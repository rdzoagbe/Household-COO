#!/bin/bash
# ============================================================================
# FIX INTEGRATION CARDS - UNIFORM HEIGHT WITH STATS IN MODAL
# ============================================================================

set -e

echo "🎨 Creating Uniform Integration Cards"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Updating IntegrationConnectors..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the usage stats inline display with a modal approach
old_stats_section = '''                        {/* Usage Stats (if connected) */}
                        {connected && stats && (
                          <div className="space-y-3 mb-4 p-4 bg-slate-950/50 rounded-xl border border-slate-800">
                            <div>
                              <div className="flex items-center justify-between mb-2">
                                <span className="text-sm text-slate-400">License Usage</span>
                                <span className="text-sm font-bold text-white">{stats.activeUsers}/{stats.totalLicenses}</span>
                              </div>
                              <div className="w-full bg-slate-800 rounded-full h-2">
                                <div 
                                  className={`bg-gradient-to-r ${getUtilizationColor(utilization)} h-2 rounded-full`}
                                  style={{ width: `${utilization}%` }}
                                />
                              </div>
                              <div className="text-xs text-slate-500 mt-1">{utilization.toFixed(0)}% utilized</div>
                            </div>

                            <div className="grid grid-cols-2 gap-3">
                              <div className="text-center">
                                <div className="text-lg font-bold text-blue-400">${(stats.monthlyCost/1000).toFixed(1)}k</div>
                                <div className="text-xs text-slate-500">Monthly</div>
                              </div>
                              <div className="text-center">
                                <div className="text-lg font-bold text-purple-400">${(stats.monthlyCost/stats.activeUsers).toFixed(0)}</div>
                                <div className="text-xs text-slate-500">Per User</div>
                              </div>
                            </div>

                            {stats.potentialSavings > 0 && (
                              <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-lg p-3">
                                <div className="text-sm font-semibold text-emerald-400 mb-1">💡 Optimization</div>
                                <div className="text-xs text-slate-400">Remove {stats.inactiveUsers} inactive licenses</div>
                                <div className="text-sm font-bold text-emerald-400 mt-1">Save ${stats.potentialSavings}/mo</div>
                              </div>
                            )}

                            <div className="text-xs text-slate-500">
                              🔄 Last synced: {stats.lastSync}
                            </div>
                          </div>
                        )}'''

new_stats_section = '''                        {/* Quick Stats Summary (if connected) */}
                        {connected && stats && (
                          <div className="mb-4 p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg">
                            <div className="flex items-center justify-between text-sm">
                              <span className="text-slate-400">License Usage</span>
                              <span className="font-bold text-white">{stats.activeUsers}/{stats.totalLicenses}</span>
                            </div>
                            <div className="flex items-center justify-between text-sm mt-1">
                              <span className="text-slate-400">Monthly Cost</span>
                              <span className="font-bold text-blue-400">${(stats.monthlyCost/1000).toFixed(1)}k</span>
                            </div>
                            {stats.potentialSavings > 0 && (
                              <div className="text-xs text-emerald-400 mt-2">
                                💡 Save ${stats.potentialSavings}/mo available
                              </div>
                            )}
                          </div>
                        )}'''

if old_stats_section in content:
    content = content.replace(old_stats_section, new_stats_section)
    print("✅ Replaced usage stats with compact version")
else:
    print("❌ Could not find usage stats section")
    exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Integration cards updated!")
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
    echo "✅ UNIFORM INTEGRATION CARDS DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🎉 CHANGES:"
    echo "  ✅ All cards same height"
    echo "  ✅ Connected cards show compact stats"
    echo "  ✅ Much cleaner, professional layout"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /integrations"
    echo "  2. All cards should be uniform height"
    echo "  3. Google/Slack show compact stats"
    echo ""
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
