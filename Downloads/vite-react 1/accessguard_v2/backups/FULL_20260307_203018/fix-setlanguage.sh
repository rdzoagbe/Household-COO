#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}Fixing setLanguage reference error...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

lines = src.split('\n')

# ── Find every place setLanguage is used ─────────────────────
print("  Lines using setLanguage:")
for i, line in enumerate(lines, 1):
    if 'setLanguage' in line:
        print(f"    L{i}: {line.strip()}")

# ── Find every function that calls setLanguage but only
#    destructures { language } from useLang() ─────────────────
print("\n  Functions with mismatched destructuring:")

page_fns = list(re.finditer(r'^function (\w+)\(', src, re.MULTILINE))
page_fns_bounds = [(m.group(1), m.start(), 
    src.find('\nfunction ', m.start()+10) if src.find('\nfunction ', m.start()+10) != -1 else len(src))
    for m in page_fns]

fixes = 0
for name, start, end in page_fns_bounds:
    body = src[start:end]
    uses_setlang  = 'setLanguage' in body
    has_setter    = '{ language, setLanguage }' in body or 'setLanguage }' in body
    has_readonly  = '{ language }' in body and 'useLang' in body

    if uses_setlang and has_readonly and not has_setter:
        print(f"    ❌ {name}: uses setLanguage but only destructures {{language}}")
        # Fix: add setLanguage to destructuring
        old = '{ language } = useLang()'
        new = '{ language, setLanguage } = useLang()'
        if old in body:
            new_body = body.replace(old, new, 1)
            src = src[:start] + new_body + src[end:]
            print(f"    ✅ {name}: fixed → {{ language, setLanguage }}")
            fixes += 1
            # Refresh bounds
            end = src.find('\nfunction ', start+10) if src.find('\nfunction ', start+10) != -1 else len(src)
    elif uses_setlang and not has_setter and not has_readonly:
        # Uses setLanguage with no useLang at all — inject full destructure
        if 'const { language } = useLang' in body:
            new_body = body.replace('const { language } = useLang', 'const { language, setLanguage } = useLang', 1)
            src = src[:start] + new_body + src[end:]
            print(f"    ✅ {name}: fixed destructuring")
            fixes += 1

if fixes == 0:
    # Brute-force: find every `{ language } = useLang()` and check if setLanguage is nearby
    for m in re.finditer(r'\{ language \} = useLang\(\)', src):
        fn_start = src.rfind('\nfunction ', 0, m.start())
        fn_end   = src.find('\nfunction ', m.start())
        fn_body  = src[fn_start:fn_end]
        if 'setLanguage' in fn_body:
            src = src[:m.start()] + '{ language, setLanguage } = useLang()' + src[m.end():]
            fn_name = re.search(r'function (\w+)', fn_body)
            print(f"    ✅ {fn_name.group(1) if fn_name else '?'}: fixed via brute-force scan")
            fixes += 1

print(f"\n  Total fixes: {fixes}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}✓ setLanguage reference error fixed!${NC}\n"
