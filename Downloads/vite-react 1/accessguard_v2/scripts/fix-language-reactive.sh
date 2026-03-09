#!/usr/bin/env bash
set -euo pipefail
ts="$(date +%Y%m%d_%H%M%S)"
backup(){ [[ -f "$1" ]] && cp "$1" "$1.bak.$ts"; }

echo "🌐 Fixing reactive language switch (no page reset) — $ts"

# 1) Fix main.jsx import typo + ensure LanguageProvider wrap
MAIN="src/main.jsx"
[[ -f "$MAIN" ]] || { echo "❌ src/main.jsx not found"; exit 1; }
backup "$MAIN"
perl -pi -e 's/\.\/translations\.jsxx/\.\/translations\.jsx/g; s/\.\/translations\.js/\.\/translations\.jsx/g' "$MAIN"

# Ensure LanguageProvider import exists
if ! grep -q 'LanguageProvider' "$MAIN"; then
  perl -0777 -i -pe 's/(import\s+App\s+from\s+[\"\x27]\.\/App\.jsx[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.jsx";\n/s' "$MAIN"
fi

# Ensure wrapper exists
if ! grep -q '<LanguageProvider>' "$MAIN"; then
  perl -0777 -i -pe 's/<React\.StrictMode>\s*(.*?)\s*<\/React\.StrictMode>/<React.StrictMode>\n    <LanguageProvider>\n      $1\n    <\/LanguageProvider>\n  <\/React.StrictMode>/s' "$MAIN"
fi
echo "✅ Patched src/main.jsx"

# 2) Ensure translations.jsx exists
if [[ -f "src/translations.js" && ! -f "src/translations.jsx" ]]; then
  backup "src/translations.js"
  mv "src/translations.js" "src/translations.jsx"
  echo "✅ Renamed src/translations.js -> src/translations.jsx"
fi
TR="src/translations.jsx"
[[ -f "$TR" ]] || { echo "❌ src/translations.jsx not found"; exit 1; }
backup "$TR"

# 3) Patch translations.jsx to include reactive LanguageProvider + no-arg useTranslation()
node <<'NODE'
import fs from "node:fs";
const TR="src/translations.jsx";
let s = fs.readFileSync(TR, "utf8");

if (!s.match(/import\s+React\b/)) {
  s = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n\n` + s;
}

s = s.replace(/export\s+function\s+useTranslation\(\s*language\s*\)\s*\{[\s\S]*?\}\s*/m, "");

if (!s.includes("export function LanguageProvider") || !s.includes("export function useLanguage")) {
  s = s.trimEnd() + `

const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => localStorage.getItem("language") || "en");
  useEffect(() => { localStorage.setItem("language", language); }, [language]);
  const value = useMemo(() => ({ language, setLanguage }), [language]);
  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used inside <LanguageProvider>");
  return ctx;
}

export function useTranslation() {
  const { language } = useLanguage();
  return (key) => translations[language]?.[key] || translations["en"]?.[key] || key;
}
`;
}

fs.writeFileSync(TR, s, "utf8");
console.log("✅ Patched src/translations.jsx");
NODE

# 4) Write a safe LanguageSelect component
mkdir -p src/components
cat > src/components/LanguageSelect.jsx <<'EOC'
import React from "react";
import { useLanguage } from "../translations.jsx";

export function LanguageSelect() {
  const { language, setLanguage } = useLanguage();
  return (
    <label className="flex items-center gap-2 text-sm">
      <span className="text-gray-500">Language</span>
      <select
        value={language}
        onChange={(e) => setLanguage(e.target.value)}
        className="border rounded-xl px-3 py-2 bg-white"
      >
        <option value="en">EN</option>
        <option value="fr">FR</option>
        <option value="es">ES</option>
      </select>
    </label>
  );
}
EOC
echo "✅ Wrote src/components/LanguageSelect.jsx"

# 5) Remove frozen per-page language usage across src
# (this is the big reason “only sidebar changes”)
grep -RIl --include="*.jsx" 'localStorage.getItem("language")' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/^\s*const\s*\[\s*language\s*\]\s*=\s*useState\(\s*\(\)\s*=>\s*localStorage\.getItem\(["\x27]language["\x27]\)\s*\|\|\s*["\x27]en["\x27]\s*\)\s*;\s*\R//mg' "$f"
done
grep -RIl --include="*.jsx" 'useTranslation\(\s*language\s*\)' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/useTranslation\(\s*language\s*\)/useTranslation()/g' "$f"
done
echo "✅ Removed frozen per-page language usage"

echo ""
echo "✅ Done. Now run:"
echo "  npm run build && firebase deploy --only hosting"
echo "Backups: *.bak.$ts"
