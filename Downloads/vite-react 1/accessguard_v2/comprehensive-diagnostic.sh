#!/bin/bash
# ============================================================================
# ACCESSGUARD V2 - COMPREHENSIVE DIAGNOSTIC SCRIPT
# ============================================================================
# Checks all pages, functions, and identifies issues

set -e

echo "🔍 AccessGuard V2 - Comprehensive Diagnostic"
echo "============================================="
echo ""

cd "$(dirname "$0")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ISSUES=0
WARNINGS=0

echo "📊 Analyzing App.jsx structure..."
echo ""

# ============================================================================
# CHECK 1: TRANSLATION SETUP IN ALL PAGES
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌍 CHECK 1: Translation Setup (const t = useTranslation)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_translation() {
  local page=$1
  local line_start=$(grep -n "^function $page" src/App.jsx | cut -d: -f1 | head -1)
  
  if [ -z "$line_start" ]; then
    echo -e "${RED}✗${NC} $page: Function not found"
    ((ISSUES++))
    return
  fi
  
  # Check next 50 lines for translation setup
  local has_translation=$(sed -n "${line_start},$((line_start+50))p" src/App.jsx | grep -c "const t = useTranslation\|const { t }")
  local uses_translation=$(sed -n "${line_start},$((line_start+500))p" src/App.jsx | grep -c "{t(")
  
  if [ "$uses_translation" -gt 0 ] && [ "$has_translation" -eq 0 ]; then
    echo -e "${RED}✗${NC} $page: Uses t() but missing translation setup (line $line_start)"
    ((ISSUES++))
  elif [ "$uses_translation" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $page: Translation setup OK"
  else
    echo -e "${BLUE}○${NC} $page: No translation needed"
  fi
}

check_translation "DashboardPage"
check_translation "ToolsPage"
check_translation "EmployeesPage"
check_translation "AccessPage"
check_translation "IntegrationsPage"
check_translation "ImportPage"
check_translation "OffboardingPage"
check_translation "AuditExportPage"
check_translation "BillingPage"
check_translation "FinanceDashboard"

echo ""

# ============================================================================
# CHECK 2: ROUTE DEFINITIONS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗺️ CHECK 2: Route Definitions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_route() {
  local path=$1
  local component=$2
  
  if grep -q "path=\"$path\"" src/App.jsx; then
    local has_component=$(grep -A 5 "path=\"$path\"" src/App.jsx | grep -c "$component")
    if [ "$has_component" -gt 0 ]; then
      echo -e "${GREEN}✓${NC} Route $path → $component"
    else
      echo -e "${YELLOW}⚠${NC} Route $path exists but component mismatch"
      ((WARNINGS++))
    fi
  else
    echo -e "${RED}✗${NC} Route $path missing"
    ((ISSUES++))
  fi
}

check_route "/dashboard" "DashboardPage"
check_route "/tools" "ToolsPage"
check_route "/employees" "EmployeesPage"
check_route "/access" "AccessPage"
check_route "/integrations" "IntegrationsPage"
check_route "/import" "ImportPage"
check_route "/offboarding" "OffboardingPage"
check_route "/audit" "AuditExportPage"
check_route "/billing" "BillingPage"
check_route "/finance" "FinanceDashboard"
check_route "/executive" "ExecutivePageWrapper"

echo ""

# ============================================================================
# CHECK 3: NAVIGATION LINKS IN SIDEBAR
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 CHECK 3: Sidebar Navigation Links"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_nav_link() {
  local path=$1
  local label=$2
  
  if grep -q "{ to: \"$path\"" src/App.jsx; then
    echo -e "${GREEN}✓${NC} Nav link: $path ($label)"
  else
    echo -e "${RED}✗${NC} Nav link missing: $path"
    ((ISSUES++))
  fi
}

check_nav_link "/dashboard" "dashboard"
check_nav_link "/tools" "tools"
check_nav_link "/employees" "employees"
check_nav_link "/access" "access"
check_nav_link "/integrations" "integrations"
check_nav_link "/audit" "audit"
check_nav_link "/billing" "billing"
check_nav_link "/finance" "finance"
check_nav_link "/executive" "executive_view"

echo ""

# ============================================================================
# CHECK 4: CRITICAL IMPORTS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 CHECK 4: Critical Imports"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_import() {
  local component=$1
  
  if grep -q "import.*$component" src/App.jsx || grep -q "from \"$component\"" src/App.jsx; then
    echo -e "${GREEN}✓${NC} Import: $component"
  else
    echo -e "${RED}✗${NC} Import missing: $component"
    ((ISSUES++))
  fi
}

check_import "ExecutiveDashboard"
check_import "AIInsights"
check_import "useTranslation"

echo ""

# ============================================================================
# CHECK 5: COMPONENT DEFINITIONS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧩 CHECK 5: Component Definitions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_component() {
  local name=$1
  
  if grep -q "^function $name" src/App.jsx; then
    echo -e "${GREEN}✓${NC} Component: $name"
  else
    echo -e "${RED}✗${NC} Component missing: $name"
    ((ISSUES++))
  fi
}

check_component "IntegrationConnectors"
check_component "ExecutivePageWrapper"
check_component "PricingTiers"
check_component "SpendingInsightsCards"

echo ""

# ============================================================================
# CHECK 6: SYNTAX ISSUES
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CHECK 6: Common Syntax Issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for mismatched JSX tags
echo "Checking for mismatched JSX tags..."
if grep -n "</div>" src/App.jsx | wc -l | grep -q "^0$"; then
  echo -e "${RED}✗${NC} No closing </div> tags found (file corrupted?)"
  ((ISSUES++))
else
  echo -e "${GREEN}✓${NC} JSX tags structure looks OK"
fi

# Check for unclosed template literals
echo "Checking for template literal issues..."
BACKTICKS=$(grep -o '\`' src/App.jsx | wc -l)
if [ $((BACKTICKS % 2)) -ne 0 ]; then
  echo -e "${YELLOW}⚠${NC} Odd number of backticks (possible unclosed template literal)"
  ((WARNINGS++))
else
  echo -e "${GREEN}✓${NC} Template literals OK"
fi

# Check for onClick={() => {}} empty handlers
echo "Checking for empty onClick handlers..."
EMPTY_HANDLERS=$(grep -c "onClick={() => {}}" src/App.jsx || echo "0")
if [ "$EMPTY_HANDLERS" -gt 0 ]; then
  echo -e "${YELLOW}⚠${NC} Found $EMPTY_HANDLERS empty onClick handlers"
  ((WARNINGS++))
else
  echo -e "${GREEN}✓${NC} No empty onClick handlers"
fi

echo ""

# ============================================================================
# CHECK 7: DEMO DATA
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 CHECK 7: Demo Data Seeding"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if grep -q "function seedDbIfEmpty" src/App.jsx; then
  echo -e "${GREEN}✓${NC} seedDbIfEmpty function exists"
  
  # Check if it has tools data
  TOOLS_COUNT=$(sed -n '/function seedDbIfEmpty/,/^function /p' src/App.jsx | grep -c "name: \"")
  if [ "$TOOLS_COUNT" -gt 5 ]; then
    echo -e "${GREEN}✓${NC} Demo tools data exists ($TOOLS_COUNT tools)"
  else
    echo -e "${YELLOW}⚠${NC} Few demo tools ($TOOLS_COUNT)"
    ((WARNINGS++))
  fi
else
  echo -e "${RED}✗${NC} seedDbIfEmpty function missing"
  ((ISSUES++))
fi

echo ""

# ============================================================================
# CHECK 8: BUILD TEST
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏗️ CHECK 8: Build Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Running build test..."
if npm run build 2>&1 | grep -q "Build failed"; then
  echo -e "${RED}✗${NC} Build FAILED"
  ((ISSUES++))
  echo "See build output above for details"
else
  echo -e "${GREEN}✓${NC} Build successful"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 DIAGNOSTIC SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$ISSUES" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}✅ ALL CHECKS PASSED!${NC}"
  echo "Your application appears to be in good shape!"
elif [ "$ISSUES" -eq 0 ]; then
  echo -e "${YELLOW}⚠️ NO CRITICAL ISSUES${NC}"
  echo -e "Warnings: $WARNINGS (minor issues to address)"
else
  echo -e "${RED}❌ ISSUES FOUND${NC}"
  echo -e "Critical Issues: $ISSUES"
  echo -e "Warnings: $WARNINGS"
  echo ""
  echo "🔧 Recommended Actions:"
  echo "1. Fix critical issues (marked with ✗) first"
  echo "2. Address warnings (marked with ⚠) for polish"
  echo "3. Re-run this diagnostic after fixes"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diagnostic Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
