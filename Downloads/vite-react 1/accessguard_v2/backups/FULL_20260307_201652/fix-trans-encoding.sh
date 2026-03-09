#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: translations.js encoding + add missing keys${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, os, sys

tp = 'src/translations.js'
if not os.path.exists(tp):
    print("  No src/translations.js found")
    sys.exit(0)

# Read with utf-8 and errors='replace' to handle any bad bytes
with open(tp, 'r', encoding='utf-8', errors='replace') as f:
    t = f.read()

en_start = t.find('  en: {')
en_end   = t.find('\n  },', en_start)
if en_start == -1 or en_end == -1:
    print("  ERROR: Could not find EN block")
    sys.exit(1)

en_block = t[en_start:en_end]

new_keys = [
    ("need_review_soon",    "Need review soon"),
    ("review_all_critical", "Review All Critical"),
    ("set_reminders",       "Set Reminders"),
    ("cost_management",     "Cost Management"),
    ("analytics",           "Analytics"),
    ("settings",            "Settings"),
    ("contracts",           "Contracts"),
    ("security",            "Security"),
    ("access",              "Access Map"),
    ("executive_view",      "Executive View"),
    ("finance",             "Finance"),
    ("licenses",            "Licenses"),
    ("renewals",            "Renewals"),
    ("invoices",            "Invoices"),
    ("billing",             "Billing"),
    ("audit",               "Audit Export"),
    ("offboarding",         "Offboarding"),
    ("import",              "Import Data"),
    ("integrations",        "Integrations"),
]

added = []
for key, val in new_keys:
    if (key + ':') not in en_block and (key + ' :') not in en_block:
        insert = "\n    " + key + ": '" + val + "',"
        t = t[:en_end] + insert + t[en_end:]
        en_end += len(insert)
        added.append(key)

# Write back as utf-8 explicitly
with open(tp, 'w', encoding='utf-8') as f:
    f.write(t)

if added:
    print("  Added keys: " + ", ".join(added))
else:
    print("  All keys already present")
print("  File saved as UTF-8")
PYEOF

[ $? -ne 0 ] && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || exit 1
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! All labels and renewals fixes are live.${NC}\n"
