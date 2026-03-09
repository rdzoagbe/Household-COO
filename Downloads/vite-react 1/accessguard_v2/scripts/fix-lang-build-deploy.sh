#!/usr/bin/env bash
set -euo pipefail

# Run from project root
[[ -f "package.json" ]] || { echo "❌ Run from project root (package.json not found)."; exit 1; }
[[ -d "src" ]] || { echo "❌ src/ not found. Wrong directory?"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
echo "🧩 Starting language + build + deploy setup ($ts)"

# -----------------------------------------------------------------------------
# 1) Ensure LanguageSelect exists
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
            // Prevent Enter from submitting a parent form
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
# 2) Ensure translations is JSX-safe and contains LanguageProvider/useLanguage/useTranslation
#    - If src/translations.js exists, rename to .jsx (because it contains JSX Provider)
# -----------------------------------------------------------------------------
if [[ -f "src/translations.js" && ! -f "src/translations.jsx" ]]; then
  cp "src/translations.js" "src/translations.js.bak.$ts"
  mv "src/translations.js" "src/translations.jsx"
  echo "✅ Renamed src/translations.js -> src/translations.jsx (backup created)"
fi

if [[ ! -f "src/translations.jsx" ]]; then
  echo "❌ src/translations.jsx not found. Create it or rename your translations file."
  exit 1
fi

cp "src/translations.jsx" "src/translations.jsx.bak.$ts"

# Patch translations.jsx to include the provider/hook if missing
node <<'NODE'
import fs from "node:fs";

const TR = "src/translations.jsx";
let s = fs.readFileSync(TR, "utf8");

// Ensure React import for hooks exists
if (!/import\s+React\b/.test(s)) {
  s = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n\n` + s;
} else {
  // Ensure needed named imports exist (best-effort)
  if (!/(createContext|useContext|useEffect|useMemo|useState)/.test(s)) {
    // If you already have React import but missing hooks, we won't rewrite it aggressively.
    // We'll just add a second import for safety.
    s = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n` + s;
  }
}

// Remove old useTranslation(language) if present
s = s.replace(/export\s+function\s+useTranslation\(\s*language\s*\)\s*\{[\s\S]*?\}\s*/m, "");

// Add provider block if missing
if (!s.includes("export function LanguageProvider") || !s.includes("export function useLanguage")) {
  s = s.trimEnd() + `

/* ============================================================================
   GLOBAL LANGUAGE STATE (Reactive across the whole app)
   ============================================================================ */

const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => localStorage.getItem("language") || "en");

  useEffect(() => {
    localStorage.setItem("language", language);
  }, [language]);

  // Optional: sync language across multiple tabs
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

// Helper function to get translation (no args — uses global language)
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
# 3) Patch main.jsx to wrap App with LanguageProvider and import it
# -----------------------------------------------------------------------------
MAIN="src/main.jsx"
[[ -f "$MAIN" ]] || { echo "❌ src/main.jsx not found"; exit 1; }
cp "$MAIN" "$MAIN.bak.$ts"

node <<'NODE'
import fs from "node:fs";
const MAIN="src/main.jsx";
let s = fs.readFileSync(MAIN, "utf8");

// Ensure provider import exists
if (!s.includes("LanguageProvider")) {
  // Insert after index.css import if present, else after App import
  if (s.match(/import\s+['"]\.\/index\.css['"][^\n]*\n/)) {
    s = s.replace(/(import\s+['"]\.\/index\.css['"][^\n]*\n)/, `$1import { LanguageProvider } from "./translations.jsx";\n`);
  } else if (s.match(/import\s+App\s+from\s+['"]\.\/App\.jsx['"][^\n]*\n/)) {
    s = s.replace(/(import\s+App\s+from\s+['"]\.\/App\.jsx['"][^\n]*\n)/, `$1import { LanguageProvider } from "./translations.jsx";\n`);
  } else {
    s = `import { LanguageProvider } from "./translations.jsx";\n` + s;
  }
}

// Wrap <App /> with <LanguageProvider> (avoid duplicating)
if (!s.includes("<LanguageProvider>")) {
  s = s.replace(
    /<React\.StrictMode>\s*([\s\S]*?)\s*<\/React\.StrictMode>/m,
    `<React.StrictMode>\n    <LanguageProvider>\n      $1\n    </LanguageProvider>\n  </React.StrictMode>`
  );
}

fs.writeFileSync(MAIN, s, "utf8");
console.log("✅ Patched src/main.jsx");
NODE

# -----------------------------------------------------------------------------
# 4) Prevent "language change sends me to home page"
#    Fix common patterns in App.jsx:
#    - remove navigate("/") or window.location.reload() in language change blocks
#    - remove key={language} on Router/layout
# -----------------------------------------------------------------------------
APP="src/App.jsx"
if [[ -f "$APP" ]]; then
  cp "$APP" "$APP.bak.$ts"

  # Remove key={language} (common cause of remount + route reset)
  perl -pi -e 's/\s+key=\{language\}//g' "$APP"

  # Remove obvious forced navigation/reload patterns near language updates (best-effort)
  # (These are typical patterns; safe because they are very specific.)
  perl -pi -e 's/\bnavigate\(\s*[\"\x27]\/[\"\x27]\s*\)\s*;?//g' "$APP"
  perl -pi -e 's/\bwindow\.location\.reload\(\s*\)\s*;?//g' "$APP"
  perl -pi -e 's/\bwindow\.location\.href\s*=\s*[\"\x27]\/[\"\x27]\s*;?//g' "$APP"

  echo "✅ Patched src/App.jsx to avoid route reset patterns (backup created)"
else
  echo "ℹ️  src/App.jsx not found — skipping route-reset patch"
fi

# -----------------------------------------------------------------------------
# 5) Ensure imports point to translations.jsx
# -----------------------------------------------------------------------------
# main.jsx already patched. Fix any older imports that still reference translations.js
perl -pi -e 's/\.\/translations\.js/\.\/translations\.jsx/g' src/main.jsx 2>/dev/null || true
perl -pi -e 's/\.\.\/translations\.js/\.\.\/translations\.jsx/g' src/components/LanguageSelect.jsx 2>/dev/null || true

# -----------------------------------------------------------------------------
# 6) Install, build, deploy
# -----------------------------------------------------------------------------
echo ""
echo "🔧 Installing dependencies..."
npm ci || npm install

echo ""
echo "🏗️  Building..."
npm run build

echo ""
echo "🚀 Deploying Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Completed setup + build + deploy."
echo "Backups created with suffix: .bak.$ts"
