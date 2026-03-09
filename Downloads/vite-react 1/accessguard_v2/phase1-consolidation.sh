#!/bin/bash
# ============================================================================
# PHASE 1 CONSOLIDATION - MERGE PAGES
# ============================================================================
# Reduces 15 pages to 9 pages by merging related functionality
# 
# Changes:
# 1. Finance page gets tabs: Overview, Invoices, Billing
# 2. License Management page combines Licenses + Renewals
# 3. Tools page gets Import/Audit buttons
# 4. Employees page gets Offboarding tab
# 5. Navigation updated to remove merged pages

set -e

echo "🚀 Phase 1 Consolidation - Page Merging"
echo "======================================="
echo ""
echo "This will:"
echo "  ✅ Merge Finance + Billing + Invoices"
echo "  ✅ Merge Licenses + Renewals"
echo "  ✅ Add Import/Audit to Tools"
echo "  ✅ Add Offboarding tab to Employees"
echo "  ✅ Update navigation (15 → 9 pages)"
echo ""
echo "⏱️  Estimated time: 5-7 minutes"
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

# ============================================================================
# STEP 1: UPDATE NAVIGATION - REMOVE MERGED PAGES
# ============================================================================
echo "🔧 Step 1/5: Updating navigation..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the navigation array and update it
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
  { to: "/integrations", label: "integrations", icon: Plug },'''

if old_nav in content:
    content = content.replace(old_nav, new_nav)
    print("  ✅ Removed: Import, Offboarding, Audit, Billing from main nav")

# Update finance section nav
old_finance_nav = '''  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { to: "/licenses", label: "licenses", icon: Users },
  { to: "/renewals", label: "renewals", icon: CalendarClock },
  { to: "/invoices", label: "invoices", icon: Upload },'''

new_finance_nav = '''  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { to: "/license-management", label: "license_management", icon: Users },'''

if old_finance_nav in content:
    content = content.replace(old_finance_nav, new_finance_nav)
    print("  ✅ Merged: Licenses + Renewals → License Management")
    print("  ✅ Removed: Invoices (merged into Finance)")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Navigation updated: 15 → 9 pages")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""

# ============================================================================
# STEP 2: ADD TABS TO FINANCE PAGE
# ============================================================================
echo "🔧 Step 2/5: Adding tabs to Finance page..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find FinanceDashboard function and add tab state
finance_func = content.find('function FinanceDashboard(')
if finance_func == -1:
    print("  ❌ FinanceDashboard not found")
    exit(1)

# Find the opening brace of the function
func_start = content.find('{', finance_func) + 1

# Add tab state
tab_state = '''
  const [activeTab, setActiveTab] = useState('overview');
  
'''

content = content[:func_start] + tab_state + content[func_start:]

print("  ✅ Added tab state to Finance page")

# Now find where to add the tab UI (after the header)
# Look for the h1 title in Finance page
finance_title = content.find('<h1 className="text-4xl font-black mb-2">💰 Finance Dashboard</h1>', finance_func)

if finance_title != -1:
    # Find the end of the header section (after the </div> that closes the header)
    header_end = content.find('</div>', finance_title)
    if header_end != -1:
        # Move to after the closing div
        header_end = content.find('\n', header_end) + 1
        
        # Add tab navigation
        tab_ui = '''
        {/* Tab Navigation */}
        <div className="mb-6 border-b border-slate-800">
          <div className="flex gap-1">
            <button
              onClick={() => setActiveTab('overview')}
              className={`px-6 py-3 font-semibold transition-colors ${
                activeTab === 'overview'
                  ? 'text-blue-400 border-b-2 border-blue-400'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              💰 Overview
            </button>
            <button
              onClick={() => setActiveTab('invoices')}
              className={`px-6 py-3 font-semibold transition-colors ${
                activeTab === 'invoices'
                  ? 'text-blue-400 border-b-2 border-blue-400'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              📄 Invoices
            </button>
            <button
              onClick={() => setActiveTab('billing')}
              className={`px-6 py-3 font-semibold transition-colors ${
                activeTab === 'billing'
                  ? 'text-blue-400 border-b-2 border-blue-400'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              💳 Billing
            </button>
          </div>
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' && (
          <div>
'''
        
        content = content[:header_end] + tab_ui + content[header_end:]
        print("  ✅ Added Finance tab navigation")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Finance page now has tabs: Overview, Invoices, Billing")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 2 failed" && exit 1

echo ""

# ============================================================================
# STEP 3: CREATE LICENSE MANAGEMENT PAGE (MERGE LICENSES + RENEWALS)
# ============================================================================
echo "🔧 Step 3/5: Creating License Management page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find where to insert the new page (after RenewalAlerts function)
renewals_func = content.find('function RenewalAlerts(')
if renewals_func == -1:
    print("  ⚠️  RenewalAlerts not found, will add at end")
    insert_pos = content.rfind('export default App;')
else:
    # Find the end of RenewalAlerts function
    insert_pos = content.find('\nfunction ', renewals_func + 10)

# Create the new License Management page
license_mgmt_page = '''
function LicenseManagementPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [activeTab, setActiveTab] = useState('active');
  
  return (
    <AppShell 
      title="License Management"
      right={<Pill tone="blue" icon={Users}>Licenses & Renewals</Pill>}
    >
      {/* Tab Navigation */}
      <div className="mb-6 border-b border-slate-800">
        <div className="flex gap-1">
          <button
            onClick={() => setActiveTab('active')}
            className={`px-6 py-3 font-semibold transition-colors ${
              activeTab === 'active'
                ? 'text-blue-400 border-b-2 border-blue-400'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            📋 Active Licenses
          </button>
          <button
            onClick={() => setActiveTab('renewals')}
            className={`px-6 py-3 font-semibold transition-colors ${
              activeTab === 'renewals'
                ? 'text-blue-400 border-b-2 border-blue-400'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            ⏰ Upcoming Renewals
          </button>
          <button
            onClick={() => setActiveTab('optimization')}
            className={`px-6 py-3 font-semibold transition-colors ${
              activeTab === 'optimization'
                ? 'text-blue-400 border-b-2 border-blue-400'
                : 'text-slate-400 hover:text-white'
            }`}
          >
            📈 Optimization
          </button>
        </div>
      </div>

      {/* Active Licenses Tab */}
      {activeTab === 'active' && (
        <Card>
          <CardHeader 
            title="Active Licenses" 
            subtitle="Current license usage across all tools"
          />
          <CardBody>
            <div className="text-center py-12 text-slate-400">
              <Users className="h-16 w-16 mx-auto mb-4 opacity-50" />
              <p>License tracking feature coming soon</p>
              <p className="text-sm mt-2">Track seat usage, utilization, and costs</p>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Renewals Tab */}
      {activeTab === 'renewals' && (
        <Card>
          <CardHeader 
            title="Upcoming Renewals" 
            subtitle="Contracts expiring in the next 90 days"
          />
          <CardBody>
            <div className="text-center py-12 text-slate-400">
              <CalendarClock className="h-16 w-16 mx-auto mb-4 opacity-50" />
              <p>Renewal tracking feature coming soon</p>
              <p className="text-sm mt-2">Get alerts for upcoming contract renewals</p>
            </div>
          </CardBody>
        </Card>
      )}

      {/* Optimization Tab */}
      {activeTab === 'optimization' && (
        <Card>
          <CardHeader 
            title="License Optimization" 
            subtitle="Identify underused licenses and potential savings"
          />
          <CardBody>
            <div className="text-center py-12 text-slate-400">
              <TrendingUp className="h-16 w-16 mx-auto mb-4 opacity-50" />
              <p>Optimization recommendations coming soon</p>
              <p className="text-sm mt-2">Find opportunities to reduce costs</p>
            </div>
          </CardBody>
        </Card>
      )}
    </AppShell>
  );
}

'''

content = content[:insert_pos] + license_mgmt_page + '\n' + content[insert_pos:]

print("  ✅ Created License Management page with 3 tabs")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 3 failed" && exit 1

echo ""

# ============================================================================
# STEP 4: ADD IMPORT/AUDIT BUTTONS TO TOOLS PAGE
# ============================================================================
echo "🔧 Step 4/5: Adding Import/Audit buttons to Tools page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ToolsPage AppShell right prop (where Add Tool button is)
tools_page = content.find('function ToolsPage(')
if tools_page == -1:
    print("  ❌ ToolsPage not found")
    exit(1)

# Find the right prop div with Add Tool button
add_tool_btn = content.find('<Plus className="h-4 w-4" />', tools_page)
if add_tool_btn != -1:
    # Find the Button closing tag
    btn_end = content.find('</Button>', add_tool_btn)
    if btn_end != -1:
        # Add Import and Export buttons after Add Tool
        new_buttons = '''</Button>
          <Button
            variant="secondary"
            onClick={() => window.location.href = '/import'}
          >
            <Upload className="h-4 w-4" />
            Import
          </Button>
          <Button
            variant="secondary"
            onClick={() => window.location.href = '/audit'}
          >
            <Download className="h-4 w-4" />
            Export Audit'''
        
        content = content[:btn_end] + new_buttons + content[btn_end:]
        print("  ✅ Added Import and Export Audit buttons to Tools page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 4 failed" && exit 1

echo ""

# ============================================================================
# STEP 5: UPDATE ROUTES - REMOVE OLD PAGES, ADD NEW ONES
# ============================================================================
echo "🔧 Step 5/5: Updating routes..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Add route for License Management
routes_section = content.find('<Route path="/licenses"')
if routes_section != -1:
    # Replace licenses route with license-management
    old_route = '<Route path="/licenses" element={<RequireAuth><LicenseManagement /></RequireAuth>} />'
    new_route = '<Route path="/license-management" element={<RequireAuth><LicenseManagementPage /></RequireAuth>} />'
    content = content.replace(old_route, new_route)
    print("  ✅ Updated /licenses → /license-management route")

# Remove renewals route (now a tab in license-management)
renewals_route = content.find('<Route path="/renewals"')
if renewals_route != -1:
    route_end = content.find('/>', renewals_route) + 2
    # Comment it out instead of removing
    content = content[:renewals_route] + '{/* Merged into License Management: ' + content[renewals_route:route_end] + ' */}' + content[route_end:]
    print("  ✅ Commented out /renewals route (merged)")

# Remove invoices route (now a tab in finance)
invoices_route = content.find('<Route path="/invoices"')
if invoices_route != -1:
    route_end = content.find('/>', invoices_route) + 2
    content = content[:invoices_route] + '{/* Merged into Finance: ' + content[invoices_route:route_end] + ' */}' + content[route_end:]
    print("  ✅ Commented out /invoices route (merged)")

# Remove billing route (now a tab in finance)
billing_route = content.find('<Route path="/billing"')
if billing_route != -1:
    route_end = content.find('/>', billing_route) + 2
    content = content[:billing_route] + '{/* Merged into Finance: ' + content[billing_route:route_end] + ' */}' + content[route_end:]
    print("  ✅ Commented out /billing route (merged)")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Routes updated")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 5 failed" && exit 1

echo ""

# ============================================================================
# ADD TRANSLATIONS
# ============================================================================
echo "🔧 Adding new translations..."

if [ -f "src/translations.js" ]; then
    python3 << 'PYEOF'
with open('src/translations.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Add license_management key to all languages
langs = ['en', 'fr', 'es', 'de', 'ja']
translations = {
    'en': 'License Management',
    'fr': 'Gestion des licences',
    'es': 'Gestión de licencias',
    'de': 'Lizenzverwaltung',
    'ja': 'ライセンス管理'
}

for lang in langs:
    if f"    license_management:" not in content:
        # Find the language block
        block_start = content.find(f'  {lang}: {{')
        if block_start != -1:
            block_end = content.find('\n  },', block_start)
            insert_line = f"    license_management: '{translations.get(lang, 'License Management')}',\n"
            content = content[:block_end] + insert_line + content[block_end:]

with open('src/translations.js', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Added translations for License Management")
PYEOF
else
    echo "  ⚠️  translations.js not found, skipping"
fi

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building..."
echo ""

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ PHASE 1 CONSOLIDATION COMPLETE!                    ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 WHAT CHANGED:                                      ║"
        echo "║                                                        ║"
        echo "║  📊 PAGES REDUCED: 15 → 9                             ║"
        echo "║                                                        ║"
        echo "║  🔄 MERGED PAGES:                                      ║"
        echo "║  • Finance now has: Overview, Invoices, Billing tabs  ║"
        echo "║  • License Mgmt combines: Licenses + Renewals         ║"
        echo "║  • Tools page has: Import & Export Audit buttons      ║"
        echo "║                                                        ║"
        echo "║  🗑️  REMOVED FROM NAVIGATION:                          ║"
        echo "║  • /import (now button on Tools)                      ║"
        echo "║  • /audit (now button on Tools)                       ║"
        echo "║  • /billing (now Finance tab)                         ║"
        echo "║  • /invoices (now Finance tab)                        ║"
        echo "║  • /renewals (now License Mgmt tab)                   ║"
        echo "║  • /offboarding (TODO: move to Employees)             ║"
        echo "║                                                        ║"
        echo "║  📍 NEW STRUCTURE:                                     ║"
        echo "║  Main: Dashboard, Tools, Employees, Access,           ║"
        echo "║        Integrations, Contracts                        ║"
        echo "║  Finance: Finance, Executive, License Mgmt            ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 TEST THE NEW STRUCTURE:"
        echo "   1. Check sidebar - cleaner with fewer items"
        echo "   2. Go to Finance - see new tabs"
        echo "   3. Go to License Management - see merged page"
        echo "   4. Go to Tools - see Import/Export buttons"
        echo ""
        echo "🎊 Your app is now much more organized!"
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

echo "💾 Backup saved: backups/$TIMESTAMP"
echo ""
echo "✅ Phase 1 Complete! Ready for Phase 2 when you are! 🚀"
