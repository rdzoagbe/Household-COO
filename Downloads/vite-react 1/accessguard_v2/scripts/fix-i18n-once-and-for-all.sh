#!/usr/bin/env bash
set -euo pipefail
ts="$(date +%Y%m%d_%H%M%S)"
backup(){ [[ -f "$1" ]] && cp "$1" "$1.bak.$ts"; }

echo "✅ Fixing i18n/reactive language once-and-for-all ($ts)"

# -----------------------------
# 1) Ensure translations.jsx exists (rename if needed)
# -----------------------------
if [[ -f "src/translations.js" && ! -f "src/translations.jsx" ]]; then
  backup "src/translations.js"
  mv "src/translations.js" "src/translations.jsx"
  echo "✅ Renamed src/translations.js -> src/translations.jsx"
fi

# -----------------------------
# 2) Overwrite translations.jsx with a correct reactive provider/hook
#    IMPORTANT: This assumes you already have a `translations` object somewhere.
#    If you already had one, we keep it by appending our provider code after it.
# -----------------------------
if [[ ! -f "src/translations.jsx" ]]; then
  echo "❌ src/translations.jsx not found."
  exit 1
fi

backup "src/translations.jsx"

# Keep existing translations object content, then append our provider/hook.
node <<'NODE'
import fs from "node:fs";

const TR = "src/translations.jsx";
let s = fs.readFileSync(TR, "utf8");

// Ensure there is a translations object in the file
if (!s.includes("export const translations") && !s.includes("const translations")) {
  console.error("❌ translations.jsx does not contain a translations object. Add one (export const translations = {...}) then rerun.");
  process.exit(1);
}

// Ensure React import exists
if (!s.match(/import\s+React\b/)) {
  s = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n\n` + s;
}

// Remove any old LanguageContext/provider blocks to prevent duplicates
s = s.replace(/\/\*\s*={3,}[\s\S]*?GLOBAL LANGUAGE STATE[\s\S]*?\*\/[\s\S]*$/m, "");
s = s.replace(/const\s+LanguageContext\s*=\s*createContext\([\s\S]*$/m, "");

// Remove old useTranslation(language)
s = s.replace(/export\s+function\s+useTranslation\(\s*language\s*\)\s*\{[\s\S]*?\}\s*/m, "");

// Append correct provider/hook
s = s.trimEnd() + `

/* ============================================================================
   GLOBAL LANGUAGE STATE (Reactive, no page reload, no route change)
   ============================================================================ */
const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => localStorage.getItem("language") || "en");

  useEffect(() => {
    localStorage.setItem("language", language);
  }, [language]);

  const value = useMemo(() => ({ language, setLanguage }), [language]);
  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used inside <LanguageProvider>");
  return ctx;
}

// ✅ Use this in pages: const t = useTranslation();
export function useTranslation() {
  const { language } = useLanguage();
  return (key) => translations?.[language]?.[key] || translations?.en?.[key] || key;
}
`;

fs.writeFileSync(TR, s, "utf8");
console.log("✅ Patched src/translations.jsx");
NODE

# -----------------------------
# 3) Overwrite main.jsx to eliminate translations.jsxx forever
# -----------------------------
backup "src/main.jsx"

cat > src/main.jsx <<'EOC'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import "./index.css";
import { LanguageProvider } from "./translations.jsx";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <LanguageProvider>
      <App />
    </LanguageProvider>
  </React.StrictMode>
);
EOC
echo "✅ Overwrote src/main.jsx (no more translations.jsxx)"

# -----------------------------
# 4) Overwrite LanguageSelect.jsx (state change only, no reload/navigate)
# -----------------------------
backup "src/components/LanguageSelect.jsx"
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
echo "✅ Overwrote src/components/LanguageSelect.jsx"

# -----------------------------
# 5) Remove frozen per-page language patterns everywhere
# -----------------------------
# Remove: const [language] = useState(() => localStorage.getItem("language") || "en");
grep -RIl --include="*.jsx" 'localStorage.getItem("language")' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/^\s*const\s*\[\s*language\s*\]\s*=\s*useState\(\s*\(\)\s*=>\s*localStorage\.getItem\(["\x27]language["\x27]\)\s*\|\|\s*["\x27]en["\x27]\s*\)\s*;\s*\R//mg' "$f"
done

# Replace: useTranslation(language) -> useTranslation()
grep -RIl --include="*.jsx" 'useTranslation\(\s*language\s*\)' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/useTranslation\(\s*language\s*\)/useTranslation()/g' "$f"
done

# Remove key={language} to prevent remount -> route reset
grep -RIl --include="*.jsx" 'key={language}' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/\s+key=\{language\}//g' "$f"
done

echo "✅ Removed frozen language patterns"

# -----------------------------
# 6) Report hardcoded strings (these will NOT translate until changed to t("key"))
# -----------------------------
echo ""
echo "📌 Hardcoded JSX text (won't translate). First 80 hits:"
grep -RIn --include="*.jsx" ">[A-Za-z]" src | head -n 80 || true

echo ""
echo "✅ Done. Now run:"
echo "  rm -rf dist && npm run build && firebase deploy --only hosting"
echo "Backups created as *.bak.$ts"
