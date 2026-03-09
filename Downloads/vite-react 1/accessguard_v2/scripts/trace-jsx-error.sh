#!/usr/bin/env bash
set -euo pipefail

APP="src/App.jsx"
[[ -f "$APP" ]] || { echo "❌ src/App.jsx not found"; exit 1; }

echo "🏗️ Running build and capturing first JSX parse error..."
set +e
npm run build 2>&1 | tee /tmp/vite-build.log
status=${PIPESTATUS[0]}
set -e

if [[ $status -eq 0 ]]; then
  echo "✅ Build succeeded"
  exit 0
fi

# Extract line number like: src/App.jsx:91:11:
line=$(grep -oE 'src/App\.jsx:[0-9]+' /tmp/vite-build.log | head -n 1 | cut -d: -f2 || true)

if [[ -z "${line:-}" ]]; then
  echo "❌ Could not find App.jsx line number in build log. Showing last 30 lines:"
  tail -n 30 /tmp/vite-build.log
  exit 1
fi

start=$((line-25)); (( start < 1 )) && start=1
end=$((line+25))

echo ""
echo "🧭 Build failed at App.jsx line $line — showing context ($start..$end):"
echo "------------------------------------------------------------"
nl -ba "$APP" | sed -n "${start},${end}p"
echo "------------------------------------------------------------"
echo ""
echo "Tip: look for a JSX prop like className={...   > missing a }"
