#!/usr/bin/env bash
set -euo pipefail

APP="src/App.jsx"
[[ -f "$APP" ]] || { echo "❌ src/App.jsx not found"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
cp "$APP" "$APP.bak.$ts"
echo "🧩 Fixing common JSX parse errors ($ts)"

# 1) Fix: className={cx(... )>  -> className={cx(... )}>
perl -0777 -i -pe 's/className=\{cx\(([^>]*?)\)\s*>/className={cx($1)}>/g' "$APP"

# 2) Fix: prop={(... )>  -> prop={(... )}>
perl -0777 -i -pe 's/=\{([^}\n>]*\))\s*>/={$1}>/g' "$APP"

# 3) Fix empty onClick handlers introduced by patches: onClick={() => } -> onClick={() => {}}
perl -pi -e 's/onClick=\{\(\)\s*=>\s*\}/onClick={() => {}}/g' "$APP"
perl -pi -e 's/onClick=\{\(\)\s*=>\s*\}/onClick={() => {}}/g' "$APP"

# 4) Fix object-context translation mistake: label: {t("x")} -> label: t("x")
perl -pi -e 's/:\s*\{\s*t\(/: t(/g' "$APP"
perl -pi -e 's/\)\s*\}\s*(,?)/)$1/g' "$APP"

echo "✅ Patched $APP (backup: $APP.bak.$ts)"
echo "Now run: npm run build"
