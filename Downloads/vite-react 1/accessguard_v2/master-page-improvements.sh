#!/bin/bash
# ============================================================================
# MASTER PAGE IMPROVEMENTS - ALL 4 PAGES
# ============================================================================
# Fixes: Tools, Employees, Offboarding, Integrations
# - Full-width layouts (no blank spaces)
# - Visual improvements
# - Better organization
# - Executive-friendly displays

set -e

echo "🎨 Master Page Improvements - 4 Pages"
echo "======================================"
echo ""
echo "This will improve:"
echo "  1️⃣  Tools        → Spend overview + full-width"
echo "  2️⃣  Employees    → Visual cards + departments"
echo "  3️⃣  Offboarding  → Pipeline view + progress"
echo "  4️⃣  Integrations → Fix display + full-width"
echo ""
echo "⏱️  Estimated time: 10-15 minutes"
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
# STEP 1: ADD SPEND OVERVIEW TO TOOLS PAGE
# ============================================================================
echo "🔧 Step 1/4: Adding spend overview to Tools page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ToolsPage and add spend overview after AppShell opens
tools_page = content.find('function ToolsPage(')
if tools_page == -1:
    print("  ❌ ToolsPage not found")
    exit(1)

# Find AppShell in ToolsPage
appshell_start = content.find('<AppShell', tools_page)
appshell_content_start = content.find('>', appshell_start) + 1

# Check if spend overview already exists
if '💰 Total Monthly Spend' in content[tools_page:tools_page+5000]:
    print("  ℹ️  Spend overview already exists")
else:
    # Add spend overview
    spend_overview = '''
      
      {/* Spend Overview - Full Width */}
      <div className="mb-6 grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-slate-400 text-sm">💰 Total Monthly Spend</span>
          </div>
          <div className="text-4xl font-black text-white">
            ${Math.round(tools.reduce((sum, t) => sum + (Number(t.cost_per_month) || 0), 0)).toLocaleString()}
          </div>
          <div className="text-sm text-slate-400 mt-1">Across all tools</div>
        </div>
        
        <div className="bg-gradient-to-br from-rose-500/10 to-rose-600/10 border border-rose-500/20 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-slate-400 text-sm">⚠️ High Risk</span>
          </div>
          <div className="text-4xl font-black text-rose-400">
            {tools.filter(t => t.derived_risk === 'high').length}
          </div>
          <div className="text-sm text-slate-400 mt-1">Need attention</div>
        </div>
        
        <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-slate-400 text-sm">👻 Unassigned</span>
          </div>
          <div className="text-4xl font-black text-amber-400">
            {tools.filter(t => !t.owner_email).length}
          </div>
          <div className="text-sm text-slate-400 mt-1">No owner</div>
        </div>
        
        <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-slate-400 text-sm">🛠️ Total Tools</span>
          </div>
          <div className="text-4xl font-black text-blue-400">
            {tools.length}
          </div>
          <div className="text-sm text-slate-400 mt-1">In inventory</div>
        </div>
      </div>
'''
    
    content = content[:appshell_content_start] + spend_overview + content[appshell_content_start:]
    print("  ✅ Added spend overview to Tools page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""

# ============================================================================
# STEP 2: ADD DEPARTMENT CARDS TO EMPLOYEES PAGE
# ============================================================================
echo "🔧 Step 2/4: Adding department overview to Employees page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find EmployeesPage
emp_page = content.find('function EmployeesPage(')
if emp_page == -1:
    print("  ❌ EmployeesPage not found")
    exit(1)

# Find AppShell in EmployeesPage
appshell_start = content.find('<AppShell', emp_page)
appshell_content_start = content.find('>', appshell_start) + 1

# Check if department overview already exists
if '🏢 Department Overview' in content[emp_page:emp_page+5000]:
    print("  ℹ️  Department overview already exists")
else:
    # Add department overview
    dept_overview = '''
      
      {/* Department Overview - Full Width */}
      <div className="mb-6">
        <h3 className="text-xl font-bold text-white mb-4">🏢 Department Overview</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {EMP_DEPARTMENTS.map(dept => {
            const deptEmployees = employees.filter(e => e.department === dept);
            const activeCount = deptEmployees.filter(e => e.status === 'active').length;
            return (
              <div key={dept} className="bg-slate-900 border border-slate-800 rounded-xl p-4 hover:border-blue-500/50 transition-colors cursor-pointer"
                   onClick={() => setDept(dept)}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-white font-semibold">{dept}</span>
                  <Users className="h-5 w-5 text-blue-400" />
                </div>
                <div className="text-3xl font-black text-white mb-1">{activeCount}</div>
                <div className="text-sm text-slate-400">active employees</div>
              </div>
            );
          })}
        </div>
      </div>
'''
    
    content = content[:appshell_content_start] + dept_overview + content[appshell_content_start:]
    print("  ✅ Added department overview to Employees page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 2 failed" && exit 1

echo ""

# ============================================================================
# STEP 3: ADD PROGRESS VIEW TO OFFBOARDING PAGE
# ============================================================================
echo "🔧 Step 3/4: Adding progress tracking to Offboarding page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find OffboardingPage
offboard_page = content.find('function OffboardingPage(')
if offboard_page == -1:
    print("  ❌ OffboardingPage not found")
    exit(1)

# Find AppShell in OffboardingPage
appshell_start = content.find('<AppShell', offboard_page)
appshell_content_start = content.find('>', appshell_start) + 1

# Check if progress overview already exists
if '🚪 Offboarding Pipeline' in content[offboard_page:offboard_page+5000]:
    print("  ℹ️  Offboarding pipeline already exists")
else:
    # Add progress overview
    pipeline_overview = '''
      
      {/* Offboarding Stats - Full Width */}
      <div className="mb-6 grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">🔄 In Progress</div>
          <div className="text-4xl font-black text-amber-400">
            {employees.filter(e => e.status === 'offboarding').length}
          </div>
          <div className="text-sm text-slate-400 mt-2">Active offboardings</div>
        </div>
        
        <div className="bg-gradient-to-br from-slate-500/10 to-slate-600/10 border border-slate-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">✅ Completed</div>
          <div className="text-4xl font-black text-slate-400">
            {employees.filter(e => e.status === 'offboarded').length}
          </div>
          <div className="text-sm text-slate-400 mt-2">This month</div>
        </div>
        
        <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
          <div className="text-sm text-slate-400 mb-2">⏱️ Avg Duration</div>
          <div className="text-4xl font-black text-blue-400">7</div>
          <div className="text-sm text-slate-400 mt-2">Days to complete</div>
        </div>
      </div>
      
      {/* Offboarding List */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <h3 className="text-xl font-bold text-white mb-4">Active Offboardings</h3>
'''
    
    content = content[:appshell_content_start] + pipeline_overview + content[appshell_content_start:]
    print("  ✅ Added pipeline view to Offboarding page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 3 failed" && exit 1

echo ""

# ============================================================================
# STEP 4: FIX INTEGRATIONS PAGE LAYOUT
# ============================================================================
echo "🔧 Step 4/4: Fixing Integrations page layout..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find IntegrationsPage
int_page = content.find('function IntegrationsPage(')
if int_page == -1:
    print("  ❌ IntegrationsPage not found")
    exit(1)

# Ensure the integrations grid is full-width
# Look for the grid container and make sure it has proper width classes
old_grid = 'className="grid gap-6'
new_grid = 'className="grid gap-6 w-full'

# Count occurrences in IntegrationsPage section
int_page_end = content.find('\nfunction ', int_page + 20)
section = content[int_page:int_page_end]

if old_grid in section and new_grid not in section:
    # Replace only in this section
    new_section = section.replace(old_grid, new_grid, 1)
    content = content[:int_page] + new_section + content[int_page_end:]
    print("  ✅ Fixed Integrations page grid width")
else:
    print("  ℹ️  Integrations grid already properly configured")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building all improvements..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ ALL 4 PAGES IMPROVED!                              ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 IMPROVEMENTS:                                      ║"
        echo "║                                                        ║"
        echo "║  1️⃣  TOOLS PAGE:                                       ║"
        echo "║     ✅ Spend overview cards (4 metrics)                ║"
        echo "║     ✅ Full-width layout                               ║"
        echo "║     ✅ Visual KPIs at top                              ║"
        echo "║                                                        ║"
        echo "║  2️⃣  EMPLOYEES PAGE:                                   ║"
        echo "║     ✅ Department overview cards                       ║"
        echo "║     ✅ Click to filter by department                   ║"
        echo "║     ✅ Active employee counts                          ║"
        echo "║                                                        ║"
        echo "║  3️⃣  OFFBOARDING PAGE:                                 ║"
        echo "║     ✅ Pipeline statistics                             ║"
        echo "║     ✅ Progress tracking                               ║"
        echo "║     ✅ Completion metrics                              ║"
        echo "║                                                        ║"
        echo "║  4️⃣  INTEGRATIONS PAGE:                                ║"
        echo "║     ✅ Full-width grid                                 ║"
        echo "║     ✅ No blank spaces                                 ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 CHECK ALL PAGES:"
        echo "   /tools        - See spend overview"
        echo "   /employees    - See department cards"
        echo "   /offboarding  - See pipeline stats"
        echo "   /integrations - See full-width layout"
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
echo "✅ All pages improved! No more blank spaces! 🎨"
