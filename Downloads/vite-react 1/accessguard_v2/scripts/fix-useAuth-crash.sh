#!/usr/bin/env bash
set -euo pipefail
ts="$(date +%Y%m%d_%H%M%S)"
backup(){ [[ -f "$1" ]] && cp "$1" "$1.bak.$ts"; }

APP="src/App.jsx"
[[ -f "$APP" ]] || { echo "❌ src/App.jsx not found"; exit 1; }
backup "$APP"

# 1) Ensure imports exist
grep -q 'onAuthStateChanged' "$APP" || perl -0777 -i -pe 's/(from\s+["\x27]react["\x27];\s*\n)/$1import { onAuthStateChanged } from "firebase\/auth";\n/s' "$APP"
grep -q 'from "\.\/firebase-config"' "$APP" || perl -0777 -i -pe 's/(import\s+.*?\n)(?!import\s+\{\s*auth\s*\}\s+from\s+["\x27]\.\/firebase-config["\x27];)/$1import { auth } from ".\/firebase-config";\n/s' "$APP"

# 2) Insert useAuth() if missing
if ! grep -qE 'function\s+useAuth\s*\(' "$APP"; then
  perl -0777 -i -pe '
    s/(function\s+\w+\s*\(|export\s+default\s+function\s+\w+\s*\()/function useAuth() {\n  const [user, setUser] = React.useState(null);\n  const [loading, setLoading] = React.useState(true);\n\n  React.useEffect(() => {\n    const unsub = onAuthStateChanged(auth, (u) => {\n      setUser(u);\n      setLoading(false);\n    });\n    return () => unsub();\n  }, []);\n\n  return { user, loading };\n}\n\n$1/s
  ' "$APP"
fi

echo "✅ Patched useAuth() into src/App.jsx (backup: $APP.bak.$ts)"
echo "Now run: npm run build && firebase deploy --only hosting"
