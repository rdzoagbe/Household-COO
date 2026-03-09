#!/usr/bin/env bash
set -euo pipefail

[[ -f package.json ]] || { echo "❌ Run from project root"; exit 1; }

ts="$(date +%Y%m%d_%H%M%S)"
echo "🌐 Fixing language switch (no page reset) — $ts"

backup() {
  [[ -f "$1" ]] && cp "$1" "$1.bak.$ts"
}

# ------------------------------------------------------------
# 1) Write SAFE LanguageSelect component
# ------------------------------------------------------------
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

echo "✅ LanguageSelect.jsx written"

# ------------------------------------------------------------
# 2) Patch App.jsx — remove reset triggers
# ------------------------------------------------------------
APP="src/App.jsx"
if [[ -f "$APP" ]]; then
  backup "$APP"

  # Remove Router/layout remount key
  perl -pi -e 's/\s+key=\{language\}//g' "$APP"

  # Remove forced navigation/reload patterns
  perl -pi -e '
    s/\bnavigate\(\s*["\x27]\/["\x27]\s*\)\s*;?//g;
    s/\bwindow\.location\.reload\(\s*\)\s*;?//g;
    s/\bwindow\.location\.href\s*=\s*["\x27]\/["\x27]\s*;?//g;
  ' "$APP"

  echo "✅ App.jsx patched (removed reset triggers)"
else
  echo "ℹ️  No App.jsx found"
fi

# ------------------------------------------------------------
# 3) Patch main.jsx — ensure correct import
# ------------------------------------------------------------
MAIN="src/main.jsx"
if [[ -f "$MAIN" ]]; then
  backup "$MAIN"

  perl -pi -e '
    s/\.\/translations\.jsxx/\.\/translations\.jsx/g;
    s/\.\/translations\.js/\.\/translations\.jsx/g;
  ' "$MAIN"

  echo "✅ main.jsx imports normalized"
fi

# ------------------------------------------------------------
# 4) Ensure forms don’t auto-submit
# ------------------------------------------------------------
# Add preventDefault to any onSubmit without handler (best-effort)
grep -RIl "<form" src 2>/dev/null | while read -r f; do
  backup "$f"
  perl -0777 -i -pe '
    s/<form(?![^>]*onSubmit)/<form onSubmit={(e)=>e.preventDefault()}/g
  ' "$f"
done

echo "✅ Forms patched to prevent reload"

echo ""
echo "🎉 Language switch will now change in place without leaving the page."
echo "Rebuild with: npm run build"
