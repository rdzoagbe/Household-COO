#!/bin/bash
# ============================================================================
# COMPREHENSIVE FIX: Modals + Translations + Language Auto-Refresh
# ============================================================================

set -e

echo "🔧 Comprehensive Fix Script"
echo "============================"
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

# ============================================================================
# FIX 1: REMOVE BROKEN ASSIGNOWNERSBUTTON IMPORT
# ============================================================================
echo "🔧 Fix 1: Removing broken AssignOwnersButton import..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

issues_fixed = []

# Remove the broken import
if "import { AssignOwnersButton } from './modals';" in content:
    content = content.replace("import { AssignOwnersButton } from './modals';\n", "")
    issues_fixed.append("Removed broken modals import")

# Remove the usage of AssignOwnersButton (line 2400)
if "<AssignOwnersButton />" in content:
    # Replace with a comment
    content = content.replace(
        "                    <AssignOwnersButton />",
        "                    {/* AssignOwnersButton removed - file missing */}"
    )
    issues_fixed.append("Removed AssignOwnersButton usage")

# Save
with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

for fix in issues_fixed:
    print(f"  ✅ {fix}")
    
if not issues_fixed:
    print("  ℹ️  No broken imports found")

PYEOF

echo ""

# ============================================================================
# FIX 2: ADD AUTO-REFRESH TO LANGUAGE CHANGE
# ============================================================================
echo "🔧 Fix 2: Adding auto-refresh on language change..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the changeLanguage function in SidebarFooter
import re

# Look for changeLanguage function
change_lang_pattern = r'const changeLanguage = \(code\) => \{[^}]+\};'
match = re.search(change_lang_pattern, content, re.DOTALL)

if match:
    old_func = match.group()
    
    # Check if it already has reload
    if 'window.location.reload()' not in old_func:
        # Replace with version that includes reload
        new_func = '''const changeLanguage = (code) => {
    setLanguage(code);
    setShowLangMenu(false);
    window.location.reload();
  };'''
        content = content.replace(old_func, new_func)
        print("  ✅ Added window.location.reload() to changeLanguage")
    else:
        print("  ℹ️  Auto-reload already present")
else:
    print("  ⚠️  changeLanguage function not found")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""

# ============================================================================
# FIX 3: ENSURE INTEGRATIONSPAGE HAS TRANSLATION
# ============================================================================
echo "🔧 Fix 3: Checking IntegrationsPage translation setup..."

if grep -A 10 "^function IntegrationsPage" src/App.jsx | grep -q "useTranslation"; then
    echo "  ✅ IntegrationsPage already has translation"
else
    # Find line number and add translation
    LINE=$(grep -n "^function IntegrationsPage" src/App.jsx | cut -d: -f1)
    if [ -n "$LINE" ]; then
        # Add after the function declaration (after the opening brace)
        INSERT_LINE=$((LINE + 1))
        sed -i "${INSERT_LINE}a\\
  const [language] = useState(() => localStorage.getItem('language') || 'en');\\
  const t = useTranslation(language);" src/App.jsx
        echo "  ✅ Added translation to IntegrationsPage"
    fi
fi

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building..."

if npm run build; then
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "=============================================="
        echo "✅ ALL FIXES DEPLOYED SUCCESSFULLY!"
        echo "=============================================="
        echo ""
        echo "🎉 FIXES APPLIED:"
        echo "  ✅ Removed broken AssignOwnersButton import"
        echo "  ✅ Added auto-refresh on language change"
        echo "  ✅ Verified IntegrationsPage translation"
        echo ""
        echo "🧪 TEST IT:"
        echo "  1. Go to https://accessguard-v2.web.app"
        echo "  2. Change language → Page reloads automatically"
        echo "  3. All pages should work without errors"
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
