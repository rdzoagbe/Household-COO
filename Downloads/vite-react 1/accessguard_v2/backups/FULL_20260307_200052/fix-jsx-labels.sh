#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: broken JSX label expressions${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

# The original file had: title={editing ? "Edit tool" : "{t('add_tool')}"}
# After our label replacement it became: title={editing ? "Edit tool" : "{"Add Tool"}"}
# Both are broken — the t() was incorrectly wrapped in quotes in the original.
# Fix: replace the broken "{"Add Tool"}" with just "Add Tool" (proper string in ternary)

fixed = 0

# Fix pattern: "{"Some Text"}" → "Some Text"  (inside JSX attribute ternaries)
def fix_match(m):
    global fixed
    fixed += 1
    return '"' + m.group(1) + '"'

app = re.sub(r'"\{"([^"]+)"\}"', fix_match, app)
print("  Fixed " + str(fixed) + " broken {\"..\"} string literals")

# Also catch any remaining "{t('key')}" patterns (quoted t() calls — invalid JSX)
# Replace with just the proper string value
remaining = re.findall(r'"\{t\(\'([^\']+)\'\)\}"', app)
if remaining:
    label_map = {
        'add_tool': 'Add Tool', 'add_employee': 'Add Employee',
        'edit_tool': 'Edit Tool', 'edit_employee': 'Edit Employee',
        'delete_tool': 'Delete Tool', 'delete_employee': 'Delete Employee',
        'bulk_import': 'Bulk Import',
    }
    for key in remaining:
        val = label_map.get(key, key.replace('_', ' ').title())
        app = app.replace('"{t(\'' + key + '\')}"', '"' + val + '"')
        print("  Fixed quoted t('" + key + "') → \"" + val + "\"")

print("  Lines: " + str(app.count('\n')))
with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! All labels and renewals are live.${NC}\n"
