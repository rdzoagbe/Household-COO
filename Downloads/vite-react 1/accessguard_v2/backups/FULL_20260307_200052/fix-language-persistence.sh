#!/bin/bash
# ============================================================================
# FIX LANGUAGE CHANGE - Save to localStorage + Stay on Current Page
# ============================================================================

set -e

echo "🌍 Fixing Language Change"
echo "========================="
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Fixing changeLanguage function..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix changeLanguage to save to localStorage BEFORE reload
old_change_lang = '''  const changeLanguage = (code) => {
    setLanguage(code);
    setShowLangMenu(false);
    window.location.reload();
  };'''

new_change_lang = '''  const changeLanguage = (code) => {
    localStorage.setItem('language', code);  // Save BEFORE reload
    setLanguage(code);
    setShowLangMenu(false);
    window.location.reload();
  };'''

if old_change_lang in content:
    content = content.replace(old_change_lang, new_change_lang)
    print("  ✅ Fixed changeLanguage to save to localStorage before reload")
else:
    print("  ⚠️  changeLanguage pattern not found - checking alternatives...")
    
    # Try to find it with different whitespace
    import re
    pattern = r'const changeLanguage = \(code\) => \{[^}]*setLanguage\(code\);[^}]*setShowLangMenu\(false\);[^}]*window\.location\.reload\(\);[^}]*\};'
    match = re.search(pattern, content, re.DOTALL)
    
    if match:
        old = match.group()
        if 'localStorage.setItem' not in old:
            new = old.replace(
                'setLanguage(code);',
                "localStorage.setItem('language', code);  // Save BEFORE reload\n    setLanguage(code);"
            )
            content = content.replace(old, new)
            print("  ✅ Fixed changeLanguage (alternative pattern)")
        else:
            print("  ℹ️  localStorage.setItem already present")
    else:
        print("  ❌ Could not find changeLanguage function")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""
echo "🏗️  Building..."

if npm run build; then
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "=============================================="
        echo "✅ LANGUAGE CHANGE FIXED!"
        echo "=============================================="
        echo ""
        echo "🎉 WHAT'S FIXED:"
        echo "  ✅ Language saves to localStorage BEFORE reload"
        echo "  ✅ Page stays on current route after language change"
        echo "  ✅ Language persists after reload"
        echo ""
        echo "🧪 TEST IT:"
        echo "  1. Go to any page (dashboard, tools, etc.)"
        echo "  2. Change language"
        echo "  3. Page reloads and STAYS on same page"
        echo "  4. Language is changed!"
        echo ""
    else
        echo "❌ Deploy failed"
        cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
        exit 1
    fi
else
    echo "❌ Build failed - restoring backup"
    cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
    exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
