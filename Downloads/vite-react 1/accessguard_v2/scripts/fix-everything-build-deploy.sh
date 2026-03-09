#!/usr/bin/env bash
set -euo pipefail

[[ -f package.json ]] || { echo "❌ Run from project root (package.json not found)."; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
echo "🛠️  Fixing project ($ts)..."

backup() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp "$f" "$f.bak.$ts"
}

backup "src/main.jsx"
backup "src/App.jsx"
backup "src/translations.js"
backup "src/translations.jsx"

# 1) Ensure translations.jsx exists
if [[ -f "src/translations.js" && ! -f "src/translations.jsx" ]]; then
  mv "src/translations.js" "src/translations.jsx"
  echo "✅ Renamed src/translations.js -> src/translations.jsx"
fi
[[ -f "src/translations.jsx" ]] || { echo "❌ src/translations.jsx not found"; exit 1; }

# 2) Patch translations.jsx
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

  useEffect(() => {
    localStorage.setItem("language", language);
  }, [language]);

  useEffect(() => {
    const onStorage = (e) => {
      if (e.key === "language" && e.newValue) setLanguage(e.newValue);
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

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
  return function t(key) {
    return translations[language]?.[key] || translations["en"]?.[key] || key;
  };
}
`;
}

fs.writeFileSync(TR, s, "utf8");
console.log("✅ Patched src/translations.jsx");
NODE

# 3) Write LanguageSelect component
mkdir -p src/components
cat > src/components/LanguageSelect.jsx <<'EOC'
import React from "react";
import { useLanguage } from "../translations.jsx";

export function LanguageSelect() {
  const { language, setLanguage } = useLanguage();

  return (
    <div onClick={(e) => e.stopPropagation()}>
      <label className="flex items-center gap-2 text-sm">
        <span className="text-gray-500">Language</span>
        <select
          value={language}
          onChange={(e) => setLanguage(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") e.preventDefault();
          }}
          className="border rounded-xl px-3 py-2 bg-white"
        >
          <option value="en">EN</option>
          <option value="fr">FR</option>
          <option value="es">ES</option>
        </select>
      </label>
    </div>
  );
}
EOC
echo "✅ Wrote src/components/LanguageSelect.jsx"

# 4) Patch main.jsx (normalize imports FIRST)
MAIN="src/main.jsx"
[[ -f "$MAIN" ]] || { echo "❌ src/main.jsx not found"; exit 1; }

# Normalize any broken extension variants
perl -pi -e 's/\.\/translations\.jsxx/\.\/translations\.jsx/g; s/\.\/translations\.js/\.\/translations\.jsx/g' "$MAIN"

# Ensure import exists
if ! grep -q "LanguageProvider" "$MAIN"; then
  if grep -qE "import ['\"]\.\/index\.css['\"]" "$MAIN"; then
    perl -0777 -i -pe 's/(import\s+[\"\x27]\.\/index\.css[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.jsx";\n/s' "$MAIN"
  else
    perl -0777 -i -pe 's/(import\s+App\s+from\s+[\"\x27]\.\/App\.jsx[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.jsx";\n/s' "$MAIN"
  fi
fi

# Wrap with provider if not already
if ! grep -q "<LanguageProvider>" "$MAIN"; then
  perl -0777 -i -pe 's/<React\.StrictMode>\s*(.*?)\s*<\/React\.StrictMode>/<React.StrictMode>\n    <LanguageProvider>\n      $1\n    <\/LanguageProvider>\n  <\/React.StrictMode>/s' "$MAIN"
fi
echo "✅ Patched src/main.jsx"

# 5) Patch App.jsx (syntax safety)
APP="src/App.jsx"
if [[ -f "$APP" ]]; then
  perl -pi -e 's/onClick=\{\(\)\s*=>\s*\}/onClick={() => {}}/g' "$APP"
  perl -pi -e 's/\s+key=\{language\}//g' "$APP"
  echo "✅ Patched src/App.jsx (fixed empty onClick + removed key={language})"
fi

# 6) Install, build, deploy
echo ""
echo "🔧 Installing deps..."
npm ci || npm install

echo ""
echo "🏗️  Building..."
npm run build

echo ""
echo "🚀 Deploying Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Done. Backups created with: .bak.$ts"
