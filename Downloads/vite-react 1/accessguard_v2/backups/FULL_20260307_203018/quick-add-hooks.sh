#!/bin/bash
# SIMPLE TRANSLATION HOOK INSTALLER
# Adds translation hooks to all page components

echo "🚀 Adding translation hooks to App.jsx..."
echo ""

# Backup
cp src/App.jsx src/App.jsx.backup
echo "✅ Backup created: src/App.jsx.backup"

# Define the translation hook code
HOOK='  const [language] = useState(() => localStorage.getItem("language") || "en");
  const t = useTranslation(language);'

# Add hook to each page component
# We'll add it right after the function declaration and opening brace

# DashboardPage - insert after line 2766
sed -i '2767a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# ToolsPage - insert after line 3179
sed -i '3182a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# EmployeesPage - insert after line 3516
sed -i '3519a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# AccessPage - insert after line 3802
sed -i '3805a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# OffboardingPage - insert after line 3972
sed -i '3975a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# ImportPage - insert after line 4079
sed -i '4082a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# AuditExportPage - insert after line 4188
sed -i '4191a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# BillingPage - insert after line 4329
sed -i '4332a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# IntegrationsPage - insert after line 4420
sed -i '4423a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# FinanceDashboard - insert after line 5568
sed -i '5571a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# LicenseManagement - insert after line 5809
sed -i '5812a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# RenewalAlerts - insert after line 6001
sed -i '6004a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

# InvoiceManager - insert after line 6415
sed -i '6418a\
\
  // Translation hook\
  const [language] = useState(() => localStorage.getItem("language") || "en");\
  const t = useTranslation(language);' src/App.jsx

echo ""
echo "✅ Translation hooks added to 13 page components!"
echo ""
echo "📝 Modified pages:"
echo "  • DashboardPage"
echo "  • ToolsPage"
echo "  • EmployeesPage"
echo "  • AccessPage"
echo "  • OffboardingPage"
echo "  • ImportPage"
echo "  • AuditExportPage"
echo "  • BillingPage"
echo "  • IntegrationsPage"
echo "  • FinanceDashboard"
echo "  • LicenseManagement"
echo "  • RenewalAlerts"
echo "  • InvoiceManager"
echo ""
echo "🔧 NEXT STEPS:"
echo "1. Review changes: git diff src/App.jsx"
echo "2. Or compare: diff src/App.jsx.backup src/App.jsx"
echo "3. Test build: npm run build"
echo ""
echo "💡 TIP: Each page now has the translation hook."
echo "   Next, wrap UI strings with {t('key')}"
echo ""
echo "🎉 Done!"
