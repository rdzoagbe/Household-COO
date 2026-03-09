#!/usr/bin/env bash
set -euo pipefail

APP="src/App.jsx"
[[ -f "$APP" ]] || { echo "❌ src/App.jsx not found"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp "$APP" "$APP.bak.$ts"
echo "🧩 Fixing missing '}' in JSX props ($ts)"

# Fix the common broken pattern: className={cx(... )>  -> className={cx(... )}>
perl -0777 -i -pe 's/className=\{cx\(([^>]*)\)\s*>/className={cx($1)}>/g' "$APP"

# More general: if a prop expression ends with ) then immediately tag ends, ensure a }
# Example: foo={(...)   >  -> foo={(...)}>
perl -0777 -i -pe 's/=\{([^}>\n]*\))\s*>/={$1}>/g' "$APP"

echo "✅ Patched $APP (backup: $APP.bak.$ts)"
echo "Now run: npm run build"
