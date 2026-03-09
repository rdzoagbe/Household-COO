#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}Fixing duplicate </LanguageProvider> tag...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

python3 - << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

# The error: both replacements fired, producing two closing tags
# Fix: replace the doubled closing tag with a single one
bad  = '</BrowserRouter></LanguageProvider>\n      </LanguageProvider>'
good = '</BrowserRouter>\n      </LanguageProvider>'

if bad in src:
    src = src.replace(bad, good, 1)
    print("  ✓  Removed duplicate </LanguageProvider>")
elif src.count('</LanguageProvider>') > 1:
    # Fallback: remove the second occurrence
    idx = src.find('</LanguageProvider>')
    idx2 = src.find('</LanguageProvider>', idx + 1)
    src = src[:idx2] + src[idx2 + len('</LanguageProvider>'):]
    print("  ✓  Removed extra </LanguageProvider> (fallback)")
else:
    print("  ✓  Already clean — nothing to fix")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)

# Verify
count = src.count('<LanguageProvider>')
count_close = src.count('</LanguageProvider>')
print(f"  Opening tags: {count}, Closing tags: {count_close}")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || exit 1

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}✓ Done!${NC}\n"
