#!/bin/bash
# ============================================================================
# DAY 1: AI INSIGHTS - Smart Recommendations Dashboard
# ============================================================================
# Adds AI-powered insights to dashboard
# Impact: Makes product feel "2026" instantly
# Time: 5 minutes

set -e

echo "🤖 DAY 1: Adding AI Insights to Dashboard"
echo "========================================="
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/DashboardComponents.jsx "backups/$TIMESTAMP/DashboardComponents.jsx.backup" 2>/dev/null || true
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

# ============================================================================
# STEP 1: ADD AI INSIGHTS COMPONENT TO DASHBOARDCOMPONENTS.JSX
# ============================================================================
echo "🔧 Step 1: Adding AIInsights component..."

# Check if component already exists
if ! grep -q "export function AIInsights" src/DashboardComponents.jsx; then
  # Append the new component to the file
  cat >> src/DashboardComponents.jsx << 'COMPONENT_EOF'

// ============================================================================
// AI INSIGHTS COMPONENT - Smart Recommendations
// ============================================================================
import { Sparkles, TrendingDown, AlertTriangle, Clock, DollarSign } from 'lucide-react';

export function AIInsights({ tools, employees, spend, accessData }) {
  const insights = [];

  // Unused licenses
  const unusedTools = tools?.filter(t => {
    const lastUsed = new Date(t.last_used_date || 0);
    const daysSinceUse = Math.floor((Date.now() - lastUsed) / (1000 * 60 * 60 * 24));
    return daysSinceUse > 90;
  }) || [];
  
  if (unusedTools.length > 0) {
    const savings = unusedTools.reduce((sum, t) => sum + (t.cost_per_month || 0), 0);
    insights.push({
      icon: TrendingDown,
      title: 'Unused License Opportunity',
      description: `${unusedTools.length} tools haven't been used in 90+ days. Potential savings: $${savings.toLocaleString()}/month`,
      savings,
      priority: 'high',
      action: 'Review Tools',
      link: '/tools'
    });
  }

  // Orphaned tools
  const orphanedTools = tools?.filter(t => !t.owner_name || t.owner_name === 'Unassigned') || [];
  if (orphanedTools.length > 0) {
    insights.push({
      icon: AlertTriangle,
      title: 'Unassigned Tools Detected',
      description: `${orphanedTools.length} tools have no owner. Security risk!`,
      priority: 'medium',
      action: 'Assign Owners',
      link: '/tools'
    });
  }

  // If no insights
  if (insights.length === 0) {
    insights.push({
      icon: Sparkles,
      title: 'All Systems Optimized',
      description: 'No immediate optimization opportunities detected!',
      priority: 'low',
      action: 'View Dashboard',
      link: '/dashboard'
    });
  }

  const priorityOrder = { critical: 0, high: 1, medium: 2, low: 3 };
  insights.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

  const totalSavings = insights.filter(i => i.savings).reduce((sum, i) => sum + i.savings, 0);

  return (
    <div className="bg-gradient-to-br from-blue-500/10 via-purple-500/10 to-pink-500/10 border border-blue-500/20 rounded-2xl p-6 mb-6">
      <div className="flex items-center gap-3 mb-4">
        <div className="p-2 bg-gradient-to-br from-blue-500 to-purple-500 rounded-xl">
          <Sparkles className="h-5 w-5 text-white" />
        </div>
        <div className="flex-1">
          <h3 className="text-lg font-bold text-white">AI-Powered Insights</h3>
          <p className="text-sm text-slate-300">Smart recommendations to optimize your SaaS stack</p>
        </div>
        {totalSavings > 0 && (
          <div className="text-right">
            <div className="text-2xl font-black text-emerald-400">${totalSavings.toLocaleString()}</div>
            <div className="text-xs text-slate-400">potential monthly savings</div>
          </div>
        )}
      </div>

      <div className="space-y-3">
        {insights.slice(0, 3).map((insight, idx) => {
          const Icon = insight.icon;
          const colors = {
            critical: 'from-red-500/20 border-red-500/30',
            high: 'from-orange-500/20 border-orange-500/30',
            medium: 'from-yellow-500/20 border-yellow-500/30',
            low: 'from-emerald-500/20 border-emerald-500/30'
          };

          return (
            <div key={idx} className={`p-4 rounded-xl border bg-gradient-to-br ${colors[insight.priority]}`}>
              <div className="flex items-start gap-3">
                <Icon className="h-5 w-5 text-white mt-0.5" />
                <div className="flex-1">
                  <h4 className="font-semibold text-white mb-1">{insight.title}</h4>
                  <p className="text-sm text-slate-300 mb-3">{insight.description}</p>
                  <a href={insight.link} className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-sm font-semibold text-white">
                    {insight.action} →
                  </a>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="mt-4 pt-4 border-t border-white/10 text-xs text-slate-400 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Sparkles className="h-3 w-3" />
          <span>Powered by AccessGuard AI</span>
        </div>
        <div>Last updated: {new Date().toLocaleTimeString()}</div>
      </div>
    </div>
  );
}
COMPONENT_EOF

  echo "  ✅ AIInsights component added to DashboardComponents.jsx"
else
  echo "  ✅ AIInsights component already exists"
fi

echo ""

# ============================================================================
# STEP 2: ADD TO DASHBOARD PAGE
# ============================================================================
echo "🔧 Step 2: Adding AIInsights to Dashboard..."

# Import the component
if ! grep -q "AIInsights" src/App.jsx; then
  sed -i "s|import { DashboardCharts|import { DashboardCharts, AIInsights|g" src/App.jsx
  echo "  ✅ Added AIInsights import"
fi

# Add to Dashboard render (look for the first card and insert before it)
if ! grep -q "<AIInsights" src/App.jsx; then
  # Find Dashboard return statement and add AIInsights
  sed -i '/<PageHeader/a\
\
        <AIInsights \
          tools={derived?.tools || []} \
          employees={db?.employees || []} \
          spend={derived?.spend || 0} \
          accessData={derived?.access || []} \
        />' src/App.jsx
  echo "  ✅ Added AIInsights to Dashboard"
fi

echo ""

# ============================================================================
# STEP 3: BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  
  echo "🚀 Deploying..."
  if firebase deploy --only hosting; then
    echo ""
    echo "=============================================="
    echo "✅ DAY 1 COMPLETE - AI INSIGHTS DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🎉 WHAT'S NEW:"
    echo "  🤖 AI-Powered Insights card on dashboard"
    echo "  💰 Automatic savings calculations"
    echo "  🎯 Smart recommendations"
    echo "  ⚡ Action buttons to fix issues"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /dashboard"
    echo "  2. See the new purple/blue gradient card at top"
    echo "  3. Shows unused licenses, orphaned tools, savings"
    echo "  4. Click action buttons to navigate"
    echo ""
    echo "📊 BUSINESS IMPACT:"
    echo "  ✅ Product now has 'AI' checkbox"
    echo "  ✅ Proves value with savings calculations"
    echo "  ✅ Guides users to take action"
    echo ""
    echo "🎯 NEXT: Day 2 - Executive Dashboard"
    echo ""
  else
    echo "❌ Deploy failed"
    exit 1
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/DashboardComponents.jsx.backup" src/DashboardComponents.jsx 2>/dev/null || true
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
echo "✨ Day 1 complete! Your product just got smarter!"
