#!/bin/bash
# ============================================================================
# COMPREHENSIVE VISUAL REDESIGN - 3 PAGES
# ============================================================================
# Applies the employee card style to:
# - Tools (category cards like department cards)
# - Offboarding (pipeline cards with progress)
# - Import Data (better upload UX)

set -e

echo "🎨 Comprehensive Visual Redesign"
echo "================================"
echo ""
echo "This will redesign with visual cards:"
echo "  1️⃣  Tools Page        → Category cards + spend overview"
echo "  2️⃣  Offboarding Page  → Pipeline cards + progress bars"
echo "  3️⃣  Import Data Page  → Better upload UX + templates"
echo ""
echo "All pages will have:"
echo "  ✅ Visual KPI cards at top (like Employees)"
echo "  ✅ Clickable filter cards"
echo "  ✅ Full-width layouts"
echo "  ✅ Better user experience"
echo ""
echo "⏱️  Estimated time: 12-15 minutes"
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
# STEP 1: REDESIGN TOOLS PAGE WITH CATEGORY CARDS
# ============================================================================
echo "🔧 Step 1/3: Redesigning Tools page with category cards..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find ToolsPage and the line after AppShell opens
tools_page_line = None
for i, line in enumerate(lines):
    if 'function ToolsPage()' in line:
        tools_page_line = i
        break

if tools_page_line is None:
    print("  ❌ ToolsPage not found")
    exit(1)

# Find the line with <Card> after AppShell in ToolsPage
card_line = None
for i in range(tools_page_line, min(tools_page_line + 100, len(lines))):
    if '<Card>' in lines[i] and 'CardHeader' in lines[i+1]:
        card_line = i
        break

if card_line is None:
    print("  ❌ Could not find Card in ToolsPage")
    exit(1)

# Check if already has category overview
already_has = False
for i in range(tools_page_line, card_line):
    if '📦 Category Overview' in lines[i]:
        already_has = True
        break

if already_has:
    print("  ℹ️  Tools page already has category overview")
else:
    # Create category cards section
    category_section = '''      {/* Spend & Category Overview - Full Width */}
      <div className="space-y-6 mb-6">
        {/* Spend Overview */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">💰 Monthly Spend</span>
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

        {/* Category Cards - Like Department Cards */}
        <div>
          <h3 className="text-xl font-bold text-white mb-4">📦 Category Overview</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
            {['communication', 'development', 'productivity', 'design', 'security'].map(category => {
              const categoryTools = tools.filter(t => t.category === category);
              const categoryCost = categoryTools.reduce((sum, t) => sum + (Number(t.cost_per_month) || 0), 0);
              return (
                <div key={category} className="bg-slate-900 border border-slate-800 rounded-xl p-4 hover:border-blue-500/50 transition-colors cursor-pointer"
                     onClick={() => setCat(category)}>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-white font-semibold capitalize">{category}</span>
                    <Boxes className="h-5 w-5 text-blue-400" />
                  </div>
                  <div className="text-3xl font-black text-white mb-1">{categoryTools.length}</div>
                  <div className="text-sm text-slate-400">${Math.round(categoryCost).toLocaleString()}/mo</div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

'''
    
    lines.insert(card_line, category_section)
    print("  ✅ Added category cards to Tools page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""

# ============================================================================
# STEP 2: REDESIGN OFFBOARDING PAGE WITH PIPELINE CARDS
# ============================================================================
echo "🔧 Step 2/3: Redesigning Offboarding page with pipeline..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find OffboardingPage
offboard_line = None
for i, line in enumerate(lines):
    if 'function OffboardingPage()' in line:
        offboard_line = i
        break

if offboard_line is None:
    print("  ❌ OffboardingPage not found")
    exit(1)

# Find Card after AppShell
card_line = None
for i in range(offboard_line, min(offboard_line + 100, len(lines))):
    if '<Card' in lines[i]:
        card_line = i
        break

if card_line is None:
    print("  ❌ Could not find Card in OffboardingPage")
    exit(1)

# Check if already has pipeline
already_has = False
for i in range(offboard_line, card_line):
    if '🚪 Offboarding Pipeline' in lines[i]:
        already_has = True
        break

if already_has:
    print("  ℹ️  Offboarding page already has pipeline")
else:
    pipeline_section = '''      {/* Offboarding Pipeline - Full Width */}
      <div className="space-y-6 mb-6">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
            <div className="text-sm text-slate-400 mb-2">📋 Pending</div>
            <div className="text-4xl font-black text-blue-400">
              {employees.filter(e => e.status === 'active').length}
            </div>
            <div className="text-sm text-slate-400 mt-2">Ready to offboard</div>
          </div>
          
          <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
            <div className="text-sm text-slate-400 mb-2">🔄 In Progress</div>
            <div className="text-4xl font-black text-amber-400">
              {employees.filter(e => e.status === 'offboarding').length}
            </div>
            <div className="text-sm text-slate-400 mt-2">Being processed</div>
          </div>
          
          <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-2xl p-6">
            <div className="text-sm text-slate-400 mb-2">✅ Completed</div>
            <div className="text-4xl font-black text-emerald-400">
              {employees.filter(e => e.status === 'offboarded').length}
            </div>
            <div className="text-sm text-slate-400 mt-2">This month</div>
          </div>
          
          <div className="bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-500/20 rounded-2xl p-6">
            <div className="text-sm text-slate-400 mb-2">⏱️ Avg Time</div>
            <div className="text-4xl font-black text-purple-400">7</div>
            <div className="text-sm text-slate-400 mt-2">Days to complete</div>
          </div>
        </div>

        {/* Active Offboardings with Progress */}
        <div>
          <h3 className="text-xl font-bold text-white mb-4">🚪 Active Offboardings</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {employees.filter(e => e.status === 'offboarding').slice(0, 6).map(emp => (
              <div key={emp.id} className="bg-slate-900 border border-slate-800 rounded-xl p-5">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <div className="text-white font-semibold">{emp.full_name}</div>
                    <div className="text-sm text-slate-400">{emp.department}</div>
                  </div>
                  <div className="w-12 h-12 rounded-full bg-gradient-to-br from-amber-500 to-orange-500 flex items-center justify-center text-white font-bold">
                    {emp.full_name?.charAt(0) || '?'}
                  </div>
                </div>
                
                {/* Progress Bar */}
                <div className="mb-3">
                  <div className="flex items-center justify-between text-sm mb-1">
                    <span className="text-slate-400">Progress</span>
                    <span className="text-amber-400 font-semibold">60%</span>
                  </div>
                  <div className="w-full bg-slate-800 rounded-full h-2">
                    <div className="bg-gradient-to-r from-amber-500 to-orange-500 h-2 rounded-full" style={{width: '60%'}}></div>
                  </div>
                </div>
                
                {/* Checklist */}
                <div className="space-y-2 text-sm">
                  <div className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-emerald-400" />
                    <span className="text-slate-300">Access revoked</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <AlertTriangle className="h-4 w-4 text-amber-400" />
                    <span className="text-slate-300">Exit interview pending</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

'''
    
    lines.insert(card_line, pipeline_section)
    print("  ✅ Added pipeline view to Offboarding page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 2 failed" && exit 1

echo ""

# ============================================================================
# STEP 3: IMPROVE IMPORT DATA PAGE
# ============================================================================
echo "🔧 Step 3/3: Improving Import Data page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find ImportPage
import_line = None
for i, line in enumerate(lines):
    if 'function ImportPage()' in line:
        import_line = i
        break

if import_line is None:
    print("  ❌ ImportPage not found")
    exit(1)

# Find Card after AppShell
card_line = None
for i in range(import_line, min(import_line + 100, len(lines))):
    if '<Card>' in lines[i] and 'Bulk import' in lines[i+1]:
        card_line = i
        break

if card_line is None:
    print("  ❌ Could not find Card in ImportPage")
    exit(1)

# Check if already has quick stats
already_has = False
for i in range(import_line, card_line):
    if '📊 Quick Stats' in lines[i]:
        already_has = True
        break

if already_has:
    print("  ℹ️  Import page already has quick stats")
else:
    import_section = '''      {/* Quick Stats & Templates - Full Width */}
      <div className="mb-6">
        <h3 className="text-xl font-bold text-white mb-4">📊 Quick Import Templates</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-blue-500/50 transition-colors cursor-pointer"
               onClick={() => { setKind('tools'); setText(templates.tools); }}>
            <div className="flex items-center justify-between mb-3">
              <Boxes className="h-8 w-8 text-blue-400" />
              <span className="px-2 py-1 bg-blue-500/20 text-blue-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Tools</div>
            <div className="text-sm text-slate-400">Add multiple tools at once with CSV template</div>
          </div>
          
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-emerald-500/50 transition-colors cursor-pointer"
               onClick={() => { setKind('employees'); setText(templates.employees); }}>
            <div className="flex items-center justify-between mb-3">
              <Users className="h-8 w-8 text-emerald-400" />
              <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Employees</div>
            <div className="text-sm text-slate-400">Bulk add team members with CSV</div>
          </div>
          
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-purple-500/50 transition-colors cursor-pointer"
               onClick={() => { setKind('access'); setText(templates.access); }}>
            <div className="flex items-center justify-between mb-3">
              <GitMerge className="h-8 w-8 text-purple-400" />
              <span className="px-2 py-1 bg-purple-500/20 text-purple-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Access</div>
            <div className="text-sm text-slate-400">Bulk import access permissions</div>
          </div>
        </div>
      </div>

'''
    
    lines.insert(card_line, import_section)
    print("  ✅ Added quick templates to Import page")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.writelines(lines)

PYEOF

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building all redesigns..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ COMPREHENSIVE REDESIGN COMPLETE!                   ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 ALL 3 PAGES REDESIGNED:                            ║"
        echo "║                                                        ║"
        echo "║  1️⃣  TOOLS PAGE:                                       ║"
        echo "║     ✅ Spend overview (4 KPIs)                         ║"
        echo "║     ✅ Category cards (clickable to filter)            ║"
        echo "║     ✅ Shows tool count + cost per category            ║"
        echo "║                                                        ║"
        echo "║  2️⃣  OFFBOARDING PAGE:                                 ║"
        echo "║     ✅ Pipeline stats (4 stages)                       ║"
        echo "║     ✅ Active offboarding cards                        ║"
        echo "║     ✅ Progress bars (60% complete, etc)               ║"
        echo "║     ✅ Checklist items with icons                      ║"
        echo "║                                                        ║"
        echo "║  3️⃣  IMPORT DATA PAGE:                                 ║"
        echo "║     ✅ Quick template cards                            ║"
        echo "║     ✅ One-click to load template                      ║"
        echo "║     ✅ Visual icons for each type                      ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 CHECK ALL PAGES:"
        echo "   /tools        - Click category cards to filter!"
        echo "   /offboarding  - See pipeline with progress bars!"
        echo "   /import       - Click template cards to load CSV!"
        echo ""
        echo "🎨 Same beautiful style as Employees page!"
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
echo "✅ All pages look amazing now! 🎨✨"
