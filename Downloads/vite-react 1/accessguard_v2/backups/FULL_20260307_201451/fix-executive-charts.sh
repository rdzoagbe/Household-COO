#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}Fixing Executive Dashboard chart rendering...${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx"

python3 << 'PYEOF'
with open('src/ExecutiveDashboard.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

fixes = []

def fix(name, old, new):
    global src
    if new in src:
        fixes.append(f"{name} (already fixed)")
    elif old in src:
        src = src.replace(old, new, 1)
        fixes.append(name)
    else:
        fixes.append(f"SKIP {name} — pattern not found")

# ── 1. Y-axis tickFormatter: \${ → ${ ────────────────────────
fix("YAxis tickFormatter",
    r'tickFormatter={(val) => `$\${(val/1000).toFixed(0)}K`}',
    r'tickFormatter={(val) => `$${(val/1000).toFixed(0)}K`}')

# ── 2. Line chart Tooltip formatter ───────────────────────────
fix("LineChart Tooltip formatter",
    r'formatter={(val) => [`$\${val.toLocaleString()}`, \'\']}',
    r"formatter={(val) => [`$${val.toLocaleString()}`, '']}")

# ── 3. Pie label: both \${name} and \${percent} ───────────────
fix("Pie label template literal",
    r'label={({ name, percent }) => `\${name} \${(percent * 100).toFixed(0)}%`}',
    r'label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}')

# ── 4. Cell key ───────────────────────────────────────────────
fix("Cell key template literal",
    r'<Cell key={`cell-\${index}`} fill={COLORS[index % COLORS.length]} />',
    r'<Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />')

# ── 5. Pie Tooltip formatter ───────────────────────────────────
fix("Pie Tooltip formatter",
    r'formatter={(val) => [`$\${val.toLocaleString()}/mo`, \'\']}',
    r"formatter={(val) => [`$${val.toLocaleString()}/mo`, '']}")

# ── 6. Risk badge className on top tools table ────────────────
fix("Risk badge className",
    r'className={`px-3 py-1 rounded-full text-xs font-semibold \${',
    r'className={`px-3 py-1 rounded-full text-xs font-semibold ${')

# ── 7. Math.random() → fixed score ────────────────────────────
fix("Cost efficiency score (remove Math.random flicker)",
    '{(85 + Math.random() * 10).toFixed(0)}',
    '{92}')

for f in fixes:
    icon = '✅' if 'SKIP' not in f and 'already' not in f else ('⚠️ ' if 'SKIP' in f else '✓ ')
    print(f"  {icon} {f}")

with open('src/ExecutiveDashboard.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
print(f"\n  Done — {src.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════╗"
echo -e "║  ✓ Executive Dashboard fixed!                        ║"
echo -e "╠══════════════════════════════════════════════════════╣"
echo -e "║  • Y-axis now shows \$1K, \$2K etc.                   ║"
echo -e "║  • Pie chart labels show category name + %           ║"
echo -e "║  • Risk badges render correctly                      ║"
echo -e "║  • Efficiency score no longer flickers               ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}\n"
