#!/usr/bin/env bash
set -euo pipefail

MAIN="src/main.jsx"
TR="src/translations.js"

if [[ ! -f "$MAIN" ]]; then
  echo "❌ $MAIN not found (run from project root)."
  exit 1
fi

if [[ ! -f "$TR" ]]; then
  echo "❌ $TR not found (run from project root)."
  exit 1
fi

ts="$(date +%Y%m%d_%H%M%S)"
cp "$MAIN" "$MAIN.bak.$ts"
cp "$TR" "$TR.bak.$ts"
echo "✅ Backups created:"
echo "   - $MAIN.bak.$ts"
echo "   - $TR.bak.$ts"

node <<'NODE'
import fs from "node:fs";

const MAIN="src/main.jsx";
const TR="src/translations.js";

// ---------------------------
// Patch translations.js
// ---------------------------
let tr = fs.readFileSync(TR, "utf8");

// If already patched, skip
if (!tr.includes("export function LanguageProvider") && !tr.includes("const LanguageContext")) {
  // Ensure React import exists at top
  const reactImport = `import React, { createContext, useContext, useEffect, useMemo, useState } from "react";\n\n`;
  if (!tr.match(/^\s*import\s+React\b/m)) {
    // Insert import at very top (safe)
    tr = reactImport + tr;
  }

  // Replace old useTranslation(language) with context-based implementation
  // Remove the old helper at the end
  tr = tr.replace(
    /\/\/ Helper function to get translation[\s\S]*?export function useTranslation\([\s\S]*?\}\s*\n\s*\}\s*\n\s*\}\s*\n?/m,
    ""
  );

  // In case the file doesn't match the exact comment, remove the function block directly too:
  tr = tr.replace(
    /export function useTranslation\(\s*language\s*\)\s*\{[\s\S]*?\}\s*\n/m,
    ""
  );

  const ctxBlock = `
// ============================================================================
// GLOBAL LANGUAGE STATE (Reactive across the whole app)
// ============================================================================

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

  // Append the context block at the end of file
  tr = tr.trimEnd() + "\n\n" + ctxBlock + "\n";
  fs.writeFileSync(TR, tr, "utf8");
  console.log("✅ Patched src/translations.js (LanguageProvider + useLanguage + useTranslation())");
} else {
  console.log("ℹ️  src/translations.js already contains LanguageProvider — skipping");
}

// ---------------------------
// Patch main.jsx
// ---------------------------
let main = fs.readFileSync(MAIN, "utf8");

// Ensure import exists
if (!main.includes("LanguageProvider")) {
  // Insert import after existing imports
  // Prefer importing from ./translations (or ./translations.js). We'll use .js to be explicit with Vite ESM.
  const importLine = `import { LanguageProvider } from "./translations.js"\n`;

  // Place after index.css import if present, otherwise after App import
  if (main.includes('import "./index.css"') || main.includes("import './index.css'")) {
    main = main.replace(
      /(import\s+['"]\.\/index\.css['"][^\n]*\n)/,
      `$1${importLine}`
    );
  } else if (main.includes('import App from "./App.jsx"') || main.includes("import App from './App.jsx'")) {
    main = main.replace(
      /(import\s+App\s+from\s+['"]\.\/App\.jsx['"][^\n]*\n)/,
      `$1${importLine}`
    );
  } else {
    // fallback: prepend
    main = importLine + main;
  }
}

// Wrap <App /> with <LanguageProvider>
if (!main.includes("<LanguageProvider>")) {
  main = main.replace(
    /<React\.StrictMode>\s*([\s\S]*?)\s*<\/React\.StrictMode>/m,
    `<React.StrictMode>\n    <LanguageProvider>\n      $1\n    </LanguageProvider>\n  </React.StrictMode>`
  );
  // Also normalize if it was exactly <App /> only
  main = main.replace(
    /<LanguageProvider>\s*<App\s*\/>\s*<\/LanguageProvider>/m,
    `<LanguageProvider>\n      <App />\n    </LanguageProvider>`
  );
}

fs.writeFileSync(MAIN, main, "utf8");
console.log("✅ Patched src/main.jsx (wrap App with LanguageProvider)");
NODE

echo ""
echo "✅ Done."
echo "Next:"
echo "  1) Update your language selector to call useLanguage().setLanguage(...)"
echo "  2) Replace per-page localStorage language state with: const t = useTranslation();"