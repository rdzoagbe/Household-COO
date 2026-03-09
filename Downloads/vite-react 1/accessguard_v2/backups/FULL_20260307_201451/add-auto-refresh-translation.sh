#!/bin/bash
# ============================================================================
# AUTO-REFRESH + DASHBOARD TRANSLATION FIX
# ============================================================================

set -e

echo "🌍 Adding Auto-Refresh + Dashboard Translation"
echo "=============================================="
echo ""

cd "$(dirname "$0")"

# ============================================================================
# STEP 1: ADD AUTO-RELOAD TO LANGUAGE CHANGE
# ============================================================================
echo "🔧 Step 1: Adding auto-reload to language selector..."

# Add window.location.reload() on line 1307
sed -i '1307 a\    window.location.reload();' src/App.jsx

echo "✅ Auto-reload added!"
echo ""

# ============================================================================
# STEP 2: TRANSLATE DASHBOARD PAGE
# ============================================================================
echo "🔧 Step 2: Translating Dashboard page..."

# Find DashboardPage and add translation hook if not present
if ! grep -A 5 "function DashboardPage" src/App.jsx | grep -q "useTranslation"; then
  # Find the line number of DashboardPage
  LINE=$(grep -n "function DashboardPage" src/App.jsx | cut -d: -f1)
  
  # Add translation hook after the function declaration
  HOOK_LINE=$((LINE + 2))
  sed -i "${HOOK_LINE}i\\
  const [language] = useState(() => localStorage.getItem('language') || 'en');\\
  const t = useTranslation(language);" src/App.jsx
  
  echo "✅ Added translation hook to DashboardPage"
else
  echo "✅ Translation hook already in DashboardPage"
fi

echo ""

# Translate key Dashboard strings
echo "🔧 Translating Dashboard UI strings..."

# Translate common Dashboard strings
sed -i 's|title="Dashboard"|title={t("dashboard")}|g' src/App.jsx
sed -i 's|>Reset Demo Data<|>{t("reset_demo_data")}<|g' src/App.jsx
sed -i 's|>Export Audit<|>{t("export_audit")}<|g' src/App.jsx
sed -i 's|title="Top alerts"|title={t("top_alerts")}|g' src/App.jsx
sed -i 's|>Live<|>{t("live")}<|g' src/App.jsx
sed -i 's|title="Quick stats"|title={t("quick_stats")}|g' src/App.jsx
sed -i 's|title="Quick Actions"|title={t("quick_actions")}|g' src/App.jsx
sed -i 's|"Tools tracked"|{t("tools_tracked")}|g' src/App.jsx
sed -i 's|"High-risk tools"|{t("high_risk_tools")}|g' src/App.jsx
sed -i 's|"Monthly spend"|{t("monthly_spend")}|g' src/App.jsx
sed -i 's|>Assign tool owners<|>{t("assign_tool_owners")}<|g' src/App.jsx
sed -i 's|>Revoke departing access<|>{t("revoke_departing_access")}<|g' src/App.jsx
sed -i 's|>Review admin access<|>{t("review_admin_access")}<|g' src/App.jsx
sed -i 's|"Overdue reviews"|{t("overdue_reviews")}|g' src/App.jsx
sed -i 's|>Mark reviewed<|>{t("mark_reviewed")}<|g' src/App.jsx
sed -i 's|>Revoke access<|>{t("revoke_access")}<|g' src/App.jsx

echo "✅ Dashboard strings translated!"
echo ""

# ============================================================================
# STEP 3: BUILD
# ============================================================================
echo "🏗️  Step 3: Building project..."

if npm run build; then
  echo "✅ Build successful!"
else
  echo "❌ Build failed!"
  exit 1
fi

echo ""

# ============================================================================
# STEP 4: DEPLOY
# ============================================================================
echo "🚀 Step 4: Deploying..."

if firebase deploy --only hosting; then
  echo ""
  echo "=============================================="
  echo "✅ DEPLOYMENT SUCCESSFUL!"
  echo "=============================================="
  echo ""
  echo "🎉 What's new:"
  echo "   ✅ Auto-refresh on language change"
  echo "   ✅ Dashboard page translates"
  echo "   ✅ Navigation menu translates"
  echo ""
  echo "🧪 Test it:"
  echo "   1. Go to https://accessguard-v2.web.app/dashboard"
  echo "   2. Change language → Page reloads automatically"
  echo "   3. Dashboard shows in selected language!"
  echo ""
else
  echo "❌ Deployment failed!"
  exit 1
fi

echo "🎊 All done!"
