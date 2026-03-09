#!/usr/bin/env bash
set -euo pipefail

[[ -f package.json ]] || { echo "❌ Run from project root"; exit 1; }
ts="$(date +%Y%m%d_%H%M%S)"

backup() { [[ -f "$1" ]] && cp "$1" "$1.bak.$ts"; }

echo "🌐 Fixing language switch to re-render UI in-place (no navigation) — $ts"

# -----------------------------------------------------------------------------
# 1) Ensure translations.jsx exists (rename if needed)
# -----------------------------------------------------------------------------
if [[ -f "src/translations.js" && ! -f "src/translations.jsx" ]]; then
  backup "src/translations.js"
  mv "src/translations.js" "src/translations.jsx"
  echo "✅ Renamed src/translations.js -> src/translations.jsx"
fi

[[ -f "src/translations.jsx" ]] || { echo "❌ src/translations.jsx not found"; exit 1; }
backup "src/translations.jsx"

# -----------------------------------------------------------------------------
# 2) Patch translations.jsx: add LanguageProvider/useLanguage + make useTranslation() reactive
# -----------------------------------------------------------------------------
node <<'NODE'
import fs from "node:fs";

const TR = "src/translations.jsx";
let s = fs.readFileSync(TR, "utf8");

// Ensure React hooks import exists (safe additive)
if (!s.match(/import\s+React\b/)) {
  s = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n\n` + s;
}

// Remove old useTranslation(language) if present
s = s.replace(/export\s+function\s+useTranslation\(\s*language\s*\)\s*\{[\s\S]*?\}\s*/m, "");

// Add provider/hook if missing
if (!s.includes("export function LanguageProvider") || !s.includes("export function useLanguage")) {
  s = s.trimEnd() + `

/* ============================================================================
   Global language state (reactive — re-renders UI without changing route)
   ============================================================================ */
const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => localStorage.getItem("language") || "en");

  useEffect(() => {
    localStorage.setItem("language", language);
  }, [language]);

  // Optional: sync across browser tabs
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

// Translation hook — uses global reactive language, so the page updates in-place
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

# -----------------------------------------------------------------------------
# 3) Create safe LanguageSelect component (no reload, no navigate)
# -----------------------------------------------------------------------------
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
            // prevent Enter triggering parent form submit
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

# -----------------------------------------------------------------------------
# 4) Patch main.jsx: import LanguageProvider + wrap App (and fix .jsxx typo)
# -----------------------------------------------------------------------------
MAIN="src/main.jsx"
[[ -f "$MAIN" ]] || { echo "❌ src/main.jsx not found"; exit 1; }
backup "$MAIN"

# Normalize any broken imports
perl -pi -e 's/\.\/translations\.jsxx/\.\/translations\.jsx/g; s/\.\/translations\.js/\.\/translations\.jsx/g' "$MAIN"

# Ensure import exists
if ! grep -q "LanguageProvider" "$MAIN"; then
  if grep -qE "import ['\"]\.\/index\.css['\"]" "$MAIN"; then
    perl -0777 -i -pe 's/(import\s+[\"\x27]\.\/index\.css[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.jsx";\n/s' "$MAIN"
  else
    perl -0777 -i -pe 's/(import\s+App\s+from\s+[\"\x27]\.\/App\.jsx[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.jsx";\n/s' "$MAIN"
  fi
fi

# Wrap App with provider
if ! grep -q "<LanguageProvider>" "$MAIN"; then
  perl -0777 -i -pe 's/<React\.StrictMode>\s*(.*?)\s*<\/React\.StrictMode>/<React.StrictMode>\n    <LanguageProvider>\n      $1\n    <\/LanguageProvider>\n  <\/React.StrictMode>/s' "$MAIN"
fi

echo "✅ Patched src/main.jsx"

# -----------------------------------------------------------------------------
# 5) Remove patterns that cause route reset on language change
# -----------------------------------------------------------------------------
# A) Removing key={language} avoids Router/layout remount → losing current page
grep -RIl --include="*.jsx" 'key={language}' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/\s+key=\{language\}//g' "$f"
done
echo "✅ Removed key={language} (prevents remount resets)"

# B) Remove forced reload / forced redirect patterns (best-effort)
grep -RIl --include="*.jsx" 'window.location.reload\(\)|window.location.href\s*=\s*["\x27]/["\x27]|navigate\(["\x27]/["\x27]\)' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/\bwindow\.location\.reload\(\s*\)\s*;?//g; s/\bwindow\.location\.href\s*=\s*["\x27]\/["\x27]\s*;?//g; s/\bnavigate\(\s*["\x27]\/["\x27]\s*\)\s*;?//g' "$f"
done
echo "✅ Removed obvious forced reload/redirect to / patterns"

# -----------------------------------------------------------------------------
# 6) Remove per-page frozen language pattern (causes parts not to update)
# -----------------------------------------------------------------------------
# Remove the localStorage language state line
grep -RIl --include="*.jsx" 'localStorage.getItem("language")' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/^\s*const\s*\[\s*language\s*\]\s*=\s*useState\(\s*\(\)\s*=>\s*localStorage\.getItem\(["\x27]language["\x27]\)\s*\|\|\s*["\x27]en["\x27]\s*\)\s*;\s*\R//mg' "$f"
done

# Replace useTranslation(language) with useTranslation()
grep -RIl --include="*.jsx" 'useTranslation\(\s*language\s*\)' src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -pi -e 's/useTranslation\(\s*language\s*\)/useTranslation()/g' "$f"
done
echo "✅ Removed per-page frozen language usage (reactive translation now)"

echo ""
echo "✅ DONE. Now rebuild:"
echo "   npm run build"
echo "Backups created with suffix: .bak.$ts"
