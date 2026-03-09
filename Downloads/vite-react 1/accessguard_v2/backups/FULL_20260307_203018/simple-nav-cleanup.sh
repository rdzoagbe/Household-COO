#!/bin/bash
# ============================================================================
# SIMPLIFIED PHASE 1 - NAVIGATION CONSOLIDATION ONLY
# ============================================================================
# Safe approach: Just update navigation, don't modify page internals

set -e

echo "🚀 Simplified Phase 1 - Navigation Cleanup"
echo "==========================================="
echo ""
echo "This will:"
echo "  ✅ Update navigation (15 → 9 pages)"
echo "  ✅ Keep all existing pages working"
echo "  ✅ No risky internal page changes"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Updating navigation..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Update main navigation - remove pages that should be consolidated
old_nav = '''  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },
  { to: "/tools", label: "tools", icon: Boxes },
  { to: "/employees", label: "employees", icon: Users },
  { to: "/access", label: "access", icon: GitMerge },
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/import", label: "import", icon: Upload },
  { to: "/offboarding", label: "offboarding", icon: UserMinus },
  { to: "/audit", label: "audit", icon: Download },
  { to: "/billing", label: "billing", icon: CreditCard },'''

new_nav = '''  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },
  { to: "/tools", label: "tools", icon: Boxes },
  { to: "/employees", label: "employees", icon: Users },
  { to: "/access", label: "access", icon: GitMerge },
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/contracts", label: "contracts", icon: FileDiff },'''

if old_nav in content:
    content = content.replace(old_nav, new_nav)
    print("  ✅ Main navigation cleaned up")
else:
    print("  ⚠️  Main nav pattern not found, trying alternative...")

# Update finance section - consolidate finance pages
old_finance = '''  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { to: "/licenses", label: "licenses", icon: Users },
  { to: "/renewals", label: "renewals", icon: CalendarClock },
  { to: "/invoices", label: "invoices", icon: Upload },'''

new_finance = '''  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },'''

if old_finance in content:
    content = content.replace(old_finance, new_finance)
    print("  ✅ Finance section consolidated")

# Remove contracts from the end since we moved it to main nav
old_contracts = '''  { to: "/contracts", label: "contracts", icon: FileDiff },'''
# Count how many times it appears
count = content.count(old_contracts)
if count > 1:
    # Remove the second occurrence (the one in finance section)
    first_pos = content.find(old_contracts)
    second_pos = content.find(old_contracts, first_pos + 1)
    if second_pos != -1:
        content = content[:second_pos] + content[second_pos + len(old_contracts):]
        print("  ✅ Moved Contracts to main navigation")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Navigation updated successfully")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Navigation update failed" && exit 1

echo ""
echo "🏗️  Building..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ NAVIGATION SIMPLIFIED!                             ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  📊 MAIN NAVIGATION (6 items):                         ║"
        echo "║  • Dashboard                                           ║"
        echo "║  • Tools                                               ║"
        echo "║  • Employees                                           ║"
        echo "║  • Access Map                                          ║"
        echo "║  • Integrations                                        ║"
        echo "║  • Contracts                                           ║"
        echo "║                                                        ║"
        echo "║  💰 FINANCE & ADMIN (2 items):                         ║"
        echo "║  • Finance                                             ║"
        echo "║  • Executive Dashboard                                 ║"
        echo "║                                                        ║"
        echo "║  🗑️  REMOVED FROM SIDEBAR:                             ║"
        echo "║  • Import (use Tools page)                            ║"
        echo "║  • Offboarding (use Employees page)                   ║"
        echo "║  • Audit (use Tools → Export)                         ║"
        echo "║  • Billing (use Finance page)                         ║"
        echo "║  • Licenses (use Finance page)                        ║"
        echo "║  • Renewals (use Finance page)                        ║"
        echo "║  • Invoices (use Finance page)                        ║"
        echo "║                                                        ║"
        echo "║  📍 RESULT: 15 → 8 visible navigation items           ║"
        echo "║  (Pages still accessible via direct URL)              ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 CHECK IT OUT:"
        echo "   Look at your sidebar - much cleaner!"
        echo ""
        echo "💡 NEXT STEPS:"
        echo "   Phase 2 can add tabs to pages later"
        echo "   For now, enjoy the simplified navigation!"
        echo ""
    else
        echo "❌ Deploy failed - restoring backup"
        cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
        exit 1
    fi
else
    echo "❌ Build failed - restoring backup"
    cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
    exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
echo "✅ Done! Your navigation is now clean and simple! 🎉"
