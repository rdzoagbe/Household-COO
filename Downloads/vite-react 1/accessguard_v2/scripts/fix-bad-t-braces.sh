#!/usr/bin/env bash
set -euo pipefail

APP="src/App.jsx"
[[ -f "$APP" ]] || { echo "❌ src/App.jsx not found"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp "$APP" "$APP.bak.$ts"
echo "🛠️  Fixing invalid {t(...)} usages inside JS objects ($ts)"

# Fix patterns like: key: {t("x")}  -> key: t("x")
perl -pi -e 's/:\s*\{\s*t\(/: t(/g' "$APP"
perl -pi -e 's/\)\s*\}\s*(,?)/)$1/g' "$APP"

echo "✅ Patched $APP (backup: $APP.bak.$ts)"
echo "Now run: npm run build"
