#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Fix Duplicate Vars     ║"
echo -e "╚══════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

fixed = []

def remove_old_lang_t(fn_name):
    """
    After inject_after ran, some pages now have BOTH:
      const [language, setLanguage] = useState(...)   <- new (from our hook)
      const [language] = useState(...)                <- old (already existed)
      const t = useTranslation(language)              <- old (already existed)
    
    Find each function body and remove the OLD-style readonly declarations
    that appear AFTER our new setLanguage one.
    """
    global src
    fn_start = src.find(f'function {fn_name}()')
    if fn_start == -1:
        return False
    fn_end = src.find('\nfunction ', fn_start + 10)
    body = src[fn_start:fn_end]

    # Check if there are duplicate language declarations
    lang_count = body.count('const [language')
    t_count    = len(re.findall(r'^\s+const t = useTranslation', body, re.MULTILINE))

    if lang_count <= 1 and t_count <= 1:
        return False  # No duplicates

    # Remove the OLD-style (no setter) duplicate:
    # `  const [language] = useState(() => localStorage...`
    old_lang_pattern = r"\n  const \[language\] = useState\(\(\) => localStorage\.getItem\(['\"]language['\"]\) \|\| ['\"]en['\"]\);"
    body_fixed = re.sub(old_lang_pattern, '', body, count=1)

    # Remove the duplicate `  const t = useTranslation(language);`
    # Only remove if there are still 2 of them after above removal
    t_pattern = r'\n  const t = useTranslation\(language\);'
    t_matches = list(re.finditer(t_pattern, body_fixed))
    if len(t_matches) > 1:
        # Remove the SECOND occurrence (the old one)
        second = t_matches[1]
        body_fixed = body_fixed[:second.start()] + body_fixed[second.end():]

    # Also remove old `  const navigate = useNavigate();` duplicate if present
    nav_count = body_fixed.count('const navigate = useNavigate()')
    if nav_count > 1:
        nav_pattern = r'\n  const navigate = useNavigate\(\);'
        nav_matches = list(re.finditer(nav_pattern, body_fixed))
        if len(nav_matches) > 1:
            second = nav_matches[1]
            body_fixed = body_fixed[:second.start()] + body_fixed[second.end():]

    src = src[:fn_start] + body_fixed + src[fn_end:]
    fixed.append(f"{fn_name}: removed duplicate language/t declarations")
    return True

pages = [
    'SecurityCompliancePage',
    'CostManagementPage',
    'OffboardingPage',
    'AnalyticsReportsPage',
    'SettingsPage',
    'BillingPage',
    'ImportPage',
    'DashboardPage',
    'ToolsPage',
    'EmployeesPage',
    'AccessPage',
    'IntegrationsPage',
    'AuditExportPage',
    'InvoiceManager',
    'LicenseManagementPage',
    'RenewalAlertsPage',
]

for page in pages:
    remove_old_lang_t(page)

if fixed:
    for f in fixed:
        print(f"  \033[32m✓\033[0m  {f}")
else:
    print("  \033[33m--\033[0m  No duplicates found (already clean)")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)

print(f"\n  \033[32mDone — {src.count(chr(10))} lines\033[0m")
PYEOF

PATCH_EXIT=$?
if [ $PATCH_EXIT -ne 0 ]; then
  echo -e "${RED}✗ Failed. Restoring...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed. Restoring...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════╗"
echo -e "║  ✓ Deployed! Duplicate vars fixed.       ║"
echo -e "╚══════════════════════════════════════════╝${NC}\n"
