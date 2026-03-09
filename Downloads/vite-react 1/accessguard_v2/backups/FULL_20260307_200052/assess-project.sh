#!/bin/bash
# ============================================================================
# ACCESSGUARD V2 - COMPREHENSIVE ASSESSMENT SCRIPT
# ============================================================================
# Analyzes the codebase to identify what's implemented and what's missing

set -e

echo "🔍 AccessGuard V2 - Comprehensive Assessment"
echo "============================================="
echo ""

cd "$(dirname "$0")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
FEATURES_PRESENT=0
FEATURES_MISSING=0
FEATURES_PARTIAL=0

echo "📊 Analyzing codebase structure..."
echo ""

# ============================================================================
# CORE FILES CHECK
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 CORE FILES STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_file() {
  local file=$1
  local name=$2
  if [ -f "$file" ]; then
    local lines=$(wc -l < "$file")
    echo -e "${GREEN}✓${NC} $name: ${BLUE}$lines lines${NC}"
    ((FEATURES_PRESENT++))
  else
    echo -e "${RED}✗${NC} $name: MISSING"
    ((FEATURES_MISSING++))
  fi
}

check_file "src/App.jsx" "Main App Component"
check_file "src/firebase-config.js" "Firebase Configuration"
check_file "src/translations.js" "Translation System"
check_file "src/ExecutiveDashboard.jsx" "Executive Dashboard"
check_file "src/DashboardComponents.jsx" "Dashboard Components"
check_file "src/google-workspace.js" "Google Workspace Integration"
check_file "src/modals.jsx" "Modal Components"

echo ""

# ============================================================================
# FEATURE ANALYSIS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 FEATURE IMPLEMENTATION STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_feature() {
  local search=$1
  local name=$2
  local file=${3:-"src/App.jsx"}
  
  if grep -q "$search" "$file" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} $name"
    ((FEATURES_PRESENT++))
    return 0
  else
    echo -e "${RED}✗${NC} $name"
    ((FEATURES_MISSING++))
    return 1
  fi
}

check_feature_partial() {
  local search=$1
  local name=$2
  local file=${3:-"src/App.jsx"}
  
  if grep -q "$search" "$file" 2>/dev/null; then
    echo -e "${YELLOW}◐${NC} $name ${YELLOW}(Partial)${NC}"
    ((FEATURES_PARTIAL++))
    return 0
  else
    echo -e "${RED}✗${NC} $name"
    ((FEATURES_MISSING++))
    return 1
  fi
}

echo "📊 DASHBOARD FEATURES:"
echo "─────────────────────"
check_feature "function DashboardPage" "Main Dashboard Page"
check_feature "AIInsights" "AI-Powered Insights"
check_feature "TopAlerts" "Top Alerts Section"
check_feature "RiskCounters" "Risk Counters"
check_feature "QuickStats" "Quick Statistics"
echo ""

echo "👥 EMPLOYEE MANAGEMENT:"
echo "───────────────────────"
check_feature "function EmployeesPage" "Employees Page"
check_feature "addEmployee" "Add Employee"
check_feature "updateEmployee" "Update Employee"
check_feature "deleteEmployee" "Delete Employee"
check_feature "status.*offboarded" "Offboarding Status"
echo ""

echo "🔧 TOOLS MANAGEMENT:"
echo "────────────────────"
check_feature "function ToolsPage" "Tools Page"
check_feature "addTool" "Add Tool"
check_feature "updateTool" "Update Tool"
check_feature "deleteTool" "Delete Tool"
check_feature "cost_per_month" "Cost Tracking"
echo ""

echo "💰 FINANCE & BILLING:"
echo "────────────────────"
check_feature "function FinanceDashboard" "Finance Dashboard"
check_feature "function BillingPage" "Billing Page"
check_feature "PricingTiers" "Pricing Tiers"
check_feature "function InvoiceManager" "Invoice Manager"
check_feature "function RenewalAlerts" "Renewal Alerts"
echo ""

echo "📈 EXECUTIVE FEATURES:"
echo "──────────────────────"
check_feature "function ExecutivePageWrapper" "Executive Dashboard Route"
check_feature "ExecutiveDashboard" "Executive Dashboard Component" "src/ExecutiveDashboard.jsx"
check_feature "KPI" "KPI Cards" "src/ExecutiveDashboard.jsx"
check_feature "Spend Trend" "Spend Trend Chart" "src/ExecutiveDashboard.jsx"
check_feature "Category" "Category Breakdown" "src/ExecutiveDashboard.jsx"
echo ""

echo "🔌 INTEGRATIONS:"
echo "────────────────"
check_feature "function IntegrationsPage" "Integrations Page"
check_feature_partial "GoogleWorkspaceSync" "Google Workspace"
check_feature_partial "SlackIntegration" "Slack Integration"
check_feature_partial "MicrosoftIntegration" "Microsoft 365"
check_feature "function ImportData" "Data Import"
echo ""

echo "🌍 INTERNATIONALIZATION:"
echo "────────────────────────"
check_feature "useTranslation" "Translation Hook"
check_feature "languagechange" "Language Switching"
check_feature "language.*en" "English" "src/translations.js"
check_feature "language.*fr" "French" "src/translations.js"
check_feature "language.*es" "Spanish" "src/translations.js"
check_feature "language.*de" "German" "src/translations.js"
check_feature "language.*ja" "Japanese" "src/translations.js"
echo ""

echo "🔐 AUTHENTICATION & SECURITY:"
echo "──────────────────────────────"
check_feature "signInWithGoogle" "Google Sign-In"
check_feature "sendMagicLink" "Magic Link Auth"
check_feature "RequireAuth" "Protected Routes"
check_feature "useAuth" "Auth Hook"
check_feature "isDemo" "Demo Mode"
echo ""

echo "🗺️ NAVIGATION & ROUTING:"
echo "─────────────────────────"
check_feature "path=\"/dashboard\"" "Dashboard Route"
check_feature "path=\"/tools\"" "Tools Route"
check_feature "path=\"/employees\"" "Employees Route"
check_feature "path=\"/finance\"" "Finance Route"
check_feature "path=\"/executive\"" "Executive Route"
check_feature "path=\"/billing\"" "Billing Route"
check_feature "path=\"/integrations\"" "Integrations Route"
echo ""

# ============================================================================
# CODE QUALITY METRICS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📐 CODE METRICS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "src/App.jsx" ]; then
  LINES=$(wc -l < src/App.jsx)
  COMPONENTS=$(grep -c "^function.*{$" src/App.jsx || echo "0")
  HOOKS=$(grep -c "useEffect\|useState\|useMemo" src/App.jsx || echo "0")
  
  echo "📄 App.jsx Statistics:"
  echo "   • Total Lines: $LINES"
  echo "   • Components: $COMPONENTS"
  echo "   • React Hooks: $HOOKS"
  echo ""
fi

if [ -f "src/translations.js" ]; then
  TRANSLATION_KEYS=$(grep -c ":" src/translations.js || echo "0")
  echo "🌍 Translation Keys: $TRANSLATION_KEYS"
  echo ""
fi

# ============================================================================
# SUMMARY & RECOMMENDATIONS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TOTAL=$((FEATURES_PRESENT + FEATURES_MISSING + FEATURES_PARTIAL))
PERCENT_COMPLETE=$(( (FEATURES_PRESENT * 100) / TOTAL ))

echo -e "${GREEN}✓ Implemented:${NC} $FEATURES_PRESENT"
echo -e "${YELLOW}◐ Partial:${NC} $FEATURES_PARTIAL"
echo -e "${RED}✗ Missing:${NC} $FEATURES_MISSING"
echo ""
echo -e "📈 Overall Completion: ${BLUE}${PERCENT_COMPLETE}%${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 PRIORITY RECOMMENDATIONS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔥 HIGH PRIORITY (Next Steps):"
echo "   1. Complete Google Workspace Integration"
echo "   2. Add Slack Integration"
echo "   3. Add Microsoft 365 Integration"
echo "   4. Enhance Finance Dashboard"
echo "   5. Add Audit Logs System"
echo ""

echo "⚡ MEDIUM PRIORITY:"
echo "   6. Role-Based Access Control (RBAC)"
echo "   7. Advanced Analytics"
echo "   8. Automated Workflows"
echo "   9. Email Notifications"
echo "   10. API Webhooks"
echo ""

echo "💡 NICE TO HAVE:"
echo "   11. 2FA/MFA Support"
echo "   12. Mobile App"
echo "   13. Compliance Certifications Pages"
echo "   14. Advanced Reporting"
echo "   15. Custom Integrations SDK"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 DETAILED NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cat << 'NEXTEOF'
PHASE 1: COMPLETE CURRENT TASKS (Today)
========================================
✓ Restore AI Insights to Dashboard (IN PROGRESS)
□ Enhance Finance Dashboard with fancy elements
□ Add integration connectors UI

PHASE 2: INTEGRATIONS (Week 1-2)
================================
□ Google Workspace
  - OAuth setup (partially done)
  - User sync
  - License detection
  - Auto-import
  
□ Slack
  - OAuth setup
  - Channel notifications
  - Alert routing
  - Slash commands
  
□ Microsoft 365
  - OAuth setup
  - User sync
  - License tracking

PHASE 3: ENTERPRISE FEATURES (Week 3-4)
=======================================
□ Audit Logs
  - Track all changes
  - Export capabilities
  - Search & filter
  
□ RBAC
  - Admin/Manager/Viewer roles
  - Permission system
  - Access controls

□ Compliance
  - SOC 2 documentation
  - GDPR compliance tools
  - Security pages

NEXTEOF

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Assessment Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
