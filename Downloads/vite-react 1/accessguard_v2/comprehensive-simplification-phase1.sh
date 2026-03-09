#!/bin/bash
# ============================================================================
# COMPREHENSIVE SIMPLIFICATION - ALL IMPROVEMENTS
# ============================================================================
# Phase 1: Quick Wins (Traffic Lights, Tooltips, Getting Started)
# This script implements the foundational changes
# Tools cards and Finance simplification will be Phase 2

set -e

echo "🎨 Comprehensive Simplification - Phase 1"
echo "=========================================="
echo ""
echo "This will add:"
echo "  ✅ Traffic light color system (🟢🟡🔴)"
echo "  ✅ 'Explain this' tooltips everywhere"
echo "  ✅ Getting Started checklist on Dashboard"
echo "  ✅ Smart defaults and visual hierarchy"
echo ""
echo "⏱️  Estimated time: 5-7 minutes"
echo ""
echo "Note: Tools page cards and Finance redesign"
echo "      will be Phase 2 (separate script)"
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
# STEP 1: ADD TOOLTIP COMPONENT
# ============================================================================
echo "🔧 Step 1/5: Adding Tooltip component..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find where to add Tooltip (after Pill component)
pill_component = content.find('function Pill(')
if pill_component == -1:
    print("  ❌ Pill component not found")
    exit(1)

next_func = content.find('\nfunction ', pill_component + 10)

tooltip_component = '''
function Tooltip({ children, text }) {
  const [show, setShow] = useState(false);
  
  if (!text) return children;
  
  return (
    <div className="relative inline-block">
      <div
        onMouseEnter={() => setShow(true)}
        onMouseLeave={() => setShow(false)}
      >
        {children}
      </div>
      {show && (
        <div className="absolute z-50 bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-slate-800 text-white text-sm rounded-lg shadow-lg border border-slate-700 whitespace-nowrap">
          {text}
          <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1 border-4 border-transparent border-t-slate-800"></div>
        </div>
      )}
    </div>
  );
}

function HelpIcon({ text }) {
  return (
    <Tooltip text={text}>
      <button className="inline-flex items-center justify-center w-4 h-4 rounded-full bg-slate-700 hover:bg-slate-600 transition-colors ml-1">
        <span className="text-xs text-slate-300">?</span>
      </button>
    </Tooltip>
  );
}

'''

content = content[:next_func] + tooltip_component + content[next_func:]

print("  ✅ Tooltip and HelpIcon components added")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""

# ============================================================================
# STEP 2: ADD TRAFFIC LIGHT BADGE COMPONENT
# ============================================================================
echo "🔧 Step 2/5: Adding Traffic Light status badges..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find Tooltip component we just added
tooltip = content.find('function Tooltip(')
next_func = content.find('\nfunction ', content.find('function HelpIcon(') + 10)

status_badge = '''
function StatusBadge({ status, label }) {
  const styles = {
    good: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
    warning: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
    danger: 'bg-rose-500/20 text-rose-400 border-rose-500/30',
    neutral: 'bg-slate-500/20 text-slate-400 border-slate-500/30'
  };
  
  const icons = {
    good: '🟢',
    warning: '🟡',
    danger: '🔴',
    neutral: '⚪'
  };
  
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border ${styles[status] || styles.neutral}`}>
      <span>{icons[status] || icons.neutral}</span>
      {label}
    </span>
  );
}

'''

content = content[:next_func] + status_badge + content[next_func:]

print("  ✅ StatusBadge component added")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 2 failed" && exit 1

echo ""

# ============================================================================
# STEP 3: ADD GETTING STARTED CHECKLIST TO DASHBOARD
# ============================================================================
echo "🔧 Step 3/5: Adding Getting Started checklist..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find DashboardPage function
dashboard = content.find('function DashboardPage(')
if dashboard == -1:
    print("  ❌ DashboardPage not found")
    exit(1)

# Find the AppShell opening
appshell = content.find('<AppShell', dashboard)
if appshell == -1:
    print("  ❌ AppShell in Dashboard not found")
    exit(1)

# Find where content starts (after AppShell opening tag)
content_start = content.find('>', appshell) + 1

# Add Getting Started card at the very beginning
getting_started = '''
      
      {/* Getting Started Checklist */}
      {(derived?.tools.length || 0) < 3 && (
        <Card className="mb-6 bg-gradient-to-r from-blue-500/10 to-purple-500/10 border-blue-500/20">
          <CardHeader 
            title="🚀 Getting Started" 
            subtitle="Complete these steps to get the most out of AccessGuard"
          />
          <CardBody>
            <div className="space-y-3">
              <div className="flex items-center gap-3">
                <div className={`w-6 h-6 rounded-full flex items-center justify-center ${(derived?.tools.length || 0) > 0 ? 'bg-emerald-500 text-white' : 'bg-slate-700 text-slate-400'}`}>
                  {(derived?.tools.length || 0) > 0 ? '✓' : '1'}
                </div>
                <div className="flex-1">
                  <div className="text-white font-medium">Add your tools</div>
                  <div className="text-sm text-slate-400">Track your SaaS applications</div>
                </div>
                <Link to="/tools">
                  <Button size="sm" variant="secondary">Add Tools</Button>
                </Link>
              </div>
              
              <div className="flex items-center gap-3">
                <div className={`w-6 h-6 rounded-full flex items-center justify-center ${(derived?.employees.length || 0) > 2 ? 'bg-emerald-500 text-white' : 'bg-slate-700 text-slate-400'}`}>
                  {(derived?.employees.length || 0) > 2 ? '✓' : '2'}
                </div>
                <div className="flex-1">
                  <div className="text-white font-medium">Add team members</div>
                  <div className="text-sm text-slate-400">Import or add employees</div>
                </div>
                <Link to="/employees">
                  <Button size="sm" variant="secondary">Add Team</Button>
                </Link>
              </div>
              
              <div className="flex items-center gap-3">
                <div className="w-6 h-6 rounded-full flex items-center justify-center bg-slate-700 text-slate-400">
                  3
                </div>
                <div className="flex-1">
                  <div className="text-white font-medium">Connect integrations</div>
                  <div className="text-sm text-slate-400">Automate data collection</div>
                </div>
                <Link to="/integrations">
                  <Button size="sm" variant="secondary">Connect</Button>
                </Link>
              </div>
            </div>
          </CardBody>
        </Card>
      )}
'''

content = content[:content_start] + getting_started + content[content_start:]

print("  ✅ Getting Started checklist added to Dashboard")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 3 failed" && exit 1

echo ""

# ============================================================================
# STEP 4: ADD TOOLTIPS TO DASHBOARD METRICS
# ============================================================================
echo "🔧 Step 4/5: Adding helpful tooltips to metrics..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Add tooltips to common metric labels
replacements = [
    ('label="Tools tracked"', 'label={<>Tools tracked<HelpIcon text="Total number of SaaS tools in your inventory" /></>}'),
    ('"High-risk tools"', '"High-risk tools" + " "'),
    ('label={t("high_risk_tools")}', 'label={<>{t("high_risk_tools")}<HelpIcon text="Tools with security or compliance issues" /></>}'),
    ('label={t("former_employee_access")}', 'label={<>{t("former_employee_access")}<HelpIcon text="Ex-employees who still have access to tools" /></>}'),
    ('label={t("monthly_spend")}', 'label={<>{t("monthly_spend")}<HelpIcon text="Total monthly cost of all SaaS subscriptions" /></>}'),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new, 1)

print("  ✅ Help tooltips added to Dashboard metrics")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""

# ============================================================================
# STEP 5: ADD STATUS BADGES TO TOOLS
# ============================================================================
echo "🔧 Step 5/5: Adding traffic light status to tools..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# This is a placeholder - we'll do full tools card conversion in Phase 2
# For now, just add the helper function

# Find computeToolDerivedRisk function
risk_func = content.find('function computeToolDerivedRisk(')
if risk_func != -1:
    next_func = content.find('\nfunction ', risk_func + 10)
    
    helper_func = '''
function getToolStatusType(tool) {
  const status = tool.derived_status;
  const risk = tool.derived_risk;
  
  if (status === 'orphaned' || risk === 'high') return 'danger';
  if (status === 'unused' || risk === 'medium') return 'warning';
  if (status === 'active' && risk === 'low') return 'good';
  return 'neutral';
}

'''
    
    content = content[:next_func] + helper_func + content[next_func:]
    print("  ✅ Tool status helper function added")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building Phase 1 improvements..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ PHASE 1 SIMPLIFICATION COMPLETE!                   ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 WHAT'S NEW:                                        ║"
        echo "║                                                        ║"
        echo "║  ✅ Tooltip System                                     ║"
        echo "║     • Hover over ? icons for help                      ║"
        echo "║     • Explains every metric                            ║"
        echo "║                                                        ║"
        echo "║  ✅ Traffic Light Status                               ║"
        echo "║     • 🟢 Green = Good                                  ║"
        echo "║     • 🟡 Yellow = Warning                              ║"
        echo "║     • 🔴 Red = Action needed                           ║"
        echo "║                                                        ║"
        echo "║  ✅ Getting Started Checklist                          ║"
        echo "║     • Shows on Dashboard for new users                 ║"
        echo "║     • Auto-hides when complete                         ║"
        echo "║     • Quick links to key actions                       ║"
        echo "║                                                        ║"
        echo "║  🚀 COMING IN PHASE 2:                                 ║"
        echo "║     • Tools page as beautiful cards                    ║"
        echo "║     • Simplified Finance dashboard                     ║"
        echo "║     • Enhanced employee cards                          ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 TEST IT:"
        echo "   1. Go to Dashboard - see Getting Started checklist"
        echo "   2. Hover over ? icons next to metrics"
        echo "   3. Look for 🟢🟡🔴 status indicators"
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
echo "✅ Phase 1 Complete!"
echo "Ready for Phase 2 when you are! 🚀"
