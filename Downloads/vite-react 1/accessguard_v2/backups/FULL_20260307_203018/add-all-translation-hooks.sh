#!/bin/bash
# Add translation hooks to ALL page components

set -e

cd "$(dirname "$0")"

echo "🔧 Adding translation hooks to all pages..."

# Function to add hook to a page if it doesn't have one
add_hook_to_page() {
  local page_name=$1
  
  # Check if page already has translation hook
  if grep -A 5 "function ${page_name}" src/App.jsx | grep -q "useTranslation"; then
    echo "  ✅ ${page_name} already has hook"
  else
    # Find line number of function declaration
    LINE=$(grep -n "^function ${page_name}" src/App.jsx | cut -d: -f1 | head -1)
    
    if [ -n "$LINE" ]; then
      # Add hook 2 lines after function declaration
      HOOK_LINE=$((LINE + 2))
      sed -i "${HOOK_LINE}i\\
  const [language] = useState(() => localStorage.getItem('language') || 'en');\\
  const t = useTranslation(language);" src/App.jsx
      echo "  ✅ Added hook to ${page_name}"
    else
      echo "  ⚠️  ${page_name} not found"
    fi
  fi
}

# Add hooks to all page components
add_hook_to_page "ToolsPage"
add_hook_to_page "EmployeesPage"
add_hook_to_page "AccessPage"
add_hook_to_page "IntegrationsPage"
add_hook_to_page "ImportPage"
add_hook_to_page "OffboardingPage"
add_hook_to_page "AuditExportPage"
add_hook_to_page "BillingPage"
add_hook_to_page "FinanceDashboard"
add_hook_to_page "LicenseManagement"
add_hook_to_page "RenewalAlerts"
add_hook_to_page "InvoiceManager"

echo ""
echo "✅ All hooks added!"
echo ""
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  echo "🚀 Deploying..."
  
  if firebase deploy --only hosting; then
    echo ""
    echo "✅ DEPLOYMENT SUCCESSFUL!"
    echo ""
    echo "🎉 All pages now have translation support!"
  else
    echo "❌ Deployment failed"
    exit 1
  fi
else
  echo "❌ Build failed"
  exit 1
fi
