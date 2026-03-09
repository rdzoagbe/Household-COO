#!/usr/bin/env bash
set -euo pipefail

[[ -f "package.json" ]] || { echo "❌ Run from project root (package.json not found)."; exit 1; }

mkdir -p src/components
echo "✅ Ensured src/components exists"

LANG_FILE="src/components/LanguageSelect.jsx"
if [[ -f "$LANG_FILE" ]]; then
  echo "ℹ️  $LANG_FILE already exists — skipping creation"
else
  cat > "$LANG_FILE" <<'EOC'
import { useLanguage } from "../translations.js";

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
  echo "✅ Created $LANG_FILE"
fi

MAIN="src/main.jsx"
[[ -f "$MAIN" ]] || { echo "❌ $MAIN not found"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp "$MAIN" "$MAIN.bak.$ts"
echo "✅ Backed up $MAIN -> $MAIN.bak.$ts"

if ! grep -q "LanguageProvider" "$MAIN"; then
  if grep -qE "import ['\"]\.\/index\.css['\"]" "$MAIN"; then
    perl -0777 -i -pe 's/(import\s+[\"\x27]\.\/index\.css[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.js";\n/s' "$MAIN"
  else
    perl -0777 -i -pe 's/(import\s+App\s+from\s+[\"\x27]\.\/App\.jsx[\"\x27][^\n]*\n)/$1import { LanguageProvider } from "\.\/translations\.js";\n/s' "$MAIN"
  fi
  echo "✅ Inserted LanguageProvider import into $MAIN"
else
  echo "ℹ️  LanguageProvider import already present in $MAIN"
fi

if ! grep -q "<LanguageProvider>" "$MAIN"; then
  perl -0777 -i -pe 's/<React\.StrictMode>\s*(.*?)\s*<\/React\.StrictMode>/<React.StrictMode>\n    <LanguageProvider>\n      $1\n    <\/LanguageProvider>\n  <\/React.StrictMode>/s' "$MAIN"
  echo "✅ Wrapped App with <LanguageProvider> in $MAIN"
else
  echo "ℹ️  $MAIN already wraps with <LanguageProvider>"
fi

echo ""
echo "✅ LanguageSelect created + provider wiring ensured."
echo "Next: render <LanguageSelect /> inside your header/sidebar in App.jsx."
