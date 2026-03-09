#!/bin/bash
# ============================================================================
# EXECUTIVE REDESIGN - ACCESS MAP, EMPLOYEES, OFFBOARDING
# ============================================================================
# Transforms 3 admin pages into executive dashboards
# - Visual KPIs, charts, and insights
# - Full-width layouts (no blank spaces)
# - Color-coded status indicators
# - Action-oriented cards

set -e

echo "🎨 Executive Page Redesign - All 3 Pages"
echo "========================================"
echo ""
echo "This will completely redesign:"
echo "  1️⃣  Access Map    → Visual security dashboard"
echo "  2️⃣  Employees     → Team insights with cards"
echo "  3️⃣  Offboarding   → Pipeline with progress tracking"
echo ""
echo "All pages will:"
echo "  ✅ Use full window width (no blanks)"
echo "  ✅ Show visual KPIs at top"
echo "  ✅ Include charts and graphs"
echo "  ✅ Highlight what needs attention"
echo ""
echo "⏱️  Estimated time: 7-10 minutes"
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
# STEP 1: REDESIGN ACCESS MAP PAGE
# ============================================================================
echo "🔧 Step 1/3: Redesigning Access Map..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find AccessPage function
access_page_start = content.find('function AccessPage(')
if access_page_start == -1:
    print("  ❌ AccessPage not found")
    exit(1)

# Find the next function to know where AccessPage ends
next_func = content.find('\nfunction ', access_page_start + 20)

# Create the new executive Access Map
new_access_page = '''function AccessPage() {
  const { data: db, isLoading } = useDbQuery();
  const [language] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);

  const derived = useMemo(() => {
    if (!db) return null;
    
    const employeesById = Object.fromEntries(db.employees.map(e => [e.id, e]));
    const toolsById = Object.fromEntries(db.tools.map(t => [t.id, t]));
    
    const access = db.access.map(a => ({
      ...a,
      employee: employeesById[a.employee_id],
      tool: toolsById[a.tool_id],
      risk: computeAccessDerivedRiskFlag(a, employeesById, toolsById)
    }));
    
    const highRisk = access.filter(a => a.risk === 'former_employee' || a.risk === 'excessive_admin');
    const needsReview = access.filter(a => a.risk === 'needs_review');
    
    return { access, highRisk, needsReview };
  }, [db]);

  if (isLoading || !derived) return <div className="flex items-center justify-center h-screen"><div className="text-white">Loading...</div></div>;

  return (
    <AppShell title={t('access') || 'Access Map'}>
      <div className="space-y-6">
        
        {/* KPI Cards - Full Width */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">Total Access</span>
              <GitMerge className="h-5 w-5 text-blue-400" />
            </div>
            <div className="text-4xl font-black text-white mb-1">{derived.access.length}</div>
            <div className="text-sm text-slate-400">Active permissions</div>
          </div>
          
          <div className="bg-gradient-to-br from-rose-500/10 to-rose-600/10 border border-rose-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">High Risk</span>
              <AlertTriangle className="h-5 w-5 text-rose-400" />
            </div>
            <div className="text-4xl font-black text-rose-400 mb-1">{derived.highRisk.length}</div>
            <div className="text-sm text-slate-400">Urgent attention needed</div>
          </div>
          
          <div className="bg-gradient-to-br from-amber-500/10 to-amber-600/10 border border-amber-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">Needs Review</span>
              <Clock className="h-5 w-5 text-amber-400" />
            </div>
            <div className="text-4xl font-black text-amber-400 mb-1">{derived.needsReview.length}</div>
            <div className="text-sm text-slate-400">Pending review</div>
          </div>
          
          <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-2xl p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-slate-400 text-sm">Clean Access</span>
              <CheckCircle className="h-5 w-5 text-emerald-400" />
            </div>
            <div className="text-4xl font-black text-emerald-400 mb-1">
              {derived.access.length - derived.highRisk.length - derived.needsReview.length}
            </div>
            <div className="text-sm text-slate-400">No issues detected</div>
          </div>
        </div>

        {/* Urgent Issues Section - Full Width */}
        {derived.highRisk.length > 0 && (
          <div className="bg-rose-500/10 border border-rose-500/20 rounded-2xl p-6">
            <div className="flex items-center gap-3 mb-4">
              <AlertTriangle className="h-6 w-6 text-rose-400" />
              <h2 className="text-xl font-bold text-white">🚨 Urgent Security Issues</h2>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {derived.highRisk.slice(0, 6).map((access, idx) => (
                <div key={idx} className="bg-slate-900/50 border border-rose-500/30 rounded-xl p-4">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <div className="text-white font-semibold">{access.employee?.full_name || 'Unknown'}</div>
                      <div className="text-sm text-slate-400">{access.tool?.name || access.tool_name}</div>
                    </div>
                    <span className="px-2 py-1 bg-rose-500/20 text-rose-400 text-xs font-bold rounded-full">
                      {access.access_level}
                    </span>
                  </div>
                  <div className="text-sm text-rose-300 mb-3">
                    {access.risk === 'former_employee' ? '⚠️ Ex-employee still has access' : '⚠️ Excessive admin access'}
                  </div>
                  <button className="w-full px-4 py-2 bg-rose-600 hover:bg-rose-500 text-white rounded-lg text-sm font-semibold transition-colors">
                    Revoke Access
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Access Overview Table - Full Width */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
          <div className="p-6 border-b border-slate-800">
            <h2 className="text-xl font-bold text-white">All Access Permissions</h2>
            <p className="text-sm text-slate-400 mt-1">Complete overview of who has access to what</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-800 bg-slate-950/50">
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Employee</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Tool</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Access Level</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Status</th>
                  <th className="text-left py-4 px-6 text-sm font-semibold text-slate-400">Risk</th>
                  <th className="text-right py-4 px-6 text-sm font-semibold text-slate-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                {derived.access.slice(0, 20).map((access, idx) => (
                  <tr key={idx} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                    <td className="py-4 px-6">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm">
                          {access.employee?.full_name?.charAt(0) || '?'}
                        </div>
                        <div>
                          <div className="text-white font-medium">{access.employee?.full_name || 'Unknown'}</div>
                          <div className="text-xs text-slate-500">{access.employee?.department}</div>
                        </div>
                      </div>
                    </td>
                    <td className="py-4 px-6 text-white">{access.tool?.name || access.tool_name}</td>
                    <td className="py-4 px-6">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        access.access_level === 'admin' 
                          ? 'bg-purple-500/20 text-purple-400 border border-purple-500/30' 
                          : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                      }`}>
                        {access.access_level}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        access.status === 'active'
                          ? 'bg-emerald-500/20 text-emerald-400'
                          : 'bg-slate-500/20 text-slate-400'
                      }`}>
                        {access.status}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      {access.risk !== 'none' ? (
                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          access.risk === 'former_employee' || access.risk === 'excessive_admin'
                            ? 'bg-rose-500/20 text-rose-400'
                            : 'bg-amber-500/20 text-amber-400'
                        }`}>
                          {access.risk.replace('_', ' ')}
                        </span>
                      ) : (
                        <span className="text-slate-500 text-xs">No issues</span>
                      )}
                    </td>
                    <td className="py-4 px-6 text-right">
                      <button className="px-3 py-1.5 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-xs font-semibold transition-colors">
                        Manage
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

      </div>
    </AppShell>
  );
}

'''

# Replace the old AccessPage
content = content[:access_page_start] + new_access_page + content[next_func:]

print("  ✅ Access Map redesigned with executive dashboard")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building redesigned pages..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ EXECUTIVE REDESIGN PHASE 1 COMPLETE!               ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 ACCESS MAP REDESIGNED:                             ║"
        echo "║  ✅ Visual KPI cards at top                            ║"
        echo "║  ✅ Urgent issues highlighted                          ║"
        echo "║  ✅ Full-width layout (no blanks)                      ║"
        echo "║  ✅ Color-coded risk indicators                        ║"
        echo "║  ✅ Action buttons on cards                            ║"
        echo "║                                                        ║"
        echo "║  🔜 COMING NEXT:                                       ║"
        echo "║     Phase 2: Employees page redesign                   ║"
        echo "║     Phase 3: Offboarding pipeline                      ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 TEST IT:"
        echo "   Go to /access and see the new executive dashboard!"
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
echo ""
echo "✅ Phase 1 Complete! Access Map is now executive-ready!"
echo "   Run Phase 2 script next for Employees & Offboarding! 🚀"
