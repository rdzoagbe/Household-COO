#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Finance spending chart (v2 — targets live file)${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# ── Step 1: Find the broken BarChart block by regex (robust) ──
# Pattern: <BarChart ...> ... <defs> placed after </Bar>
# Replace entire ResponsiveContainer block with a clean working version

OLD_PATTERN = re.search(
    r'<ResponsiveContainer width="100%" height=\{300\}>\s*\n\s*<BarChart data=\{financialData\.monthlyTrend\}>.*?</BarChart>\s*\n\s*</ResponsiveContainer>',
    app, re.DOTALL
)

if not OLD_PATTERN:
    print("  Pattern not matched — trying broader search")
    OLD_PATTERN = re.search(
        r'<ResponsiveContainer[^>]*height=\{300\}[^>]*>.*?</ResponsiveContainer>',
        app, re.DOTALL
    )

if not OLD_PATTERN:
    print("  ERROR: Could not find ResponsiveContainer")
    sys.exit(1)

print("  Found chart block at chars " + str(OLD_PATTERN.start()) + "-" + str(OLD_PATTERN.end()))

NEW_CHART = '''<ResponsiveContainer width="100%" height={300}>
            <BarChart data={financialData.monthlyTrend} barSize={40} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="spendGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#3b82f6" stopOpacity={0.95} />
                  <stop offset="100%" stopColor="#6366f1" stopOpacity={0.75} />
                </linearGradient>
              </defs>
              <XAxis
                dataKey="month"
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                axisLine={{ stroke: '#334155' }}
                tickLine={false}
              />
              <YAxis
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                tickFormatter={(v) => `$${(v/1000).toFixed(0)}K`}
              />
              <Tooltip
                cursor={{ fill: 'rgba(255,255,255,0.04)' }}
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '12px', color: '#fff', fontSize: '13px' }}
                formatter={(v) => [`$${v.toLocaleString()}`, 'Monthly Spend']}
              />
              <Bar dataKey="spend" fill="url(#spendGrad)" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>'''

app = app[:OLD_PATTERN.start()] + NEW_CHART + app[OLD_PATTERN.end():]
print("  Chart block replaced with working version")

# ── Step 2: Remove Cell from recharts import (no longer needed) ──
app = app.replace(
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';",
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';"
)
print("  Removed unused Cell import")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved OK — lines: " + str(app.count('\n')))
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting
echo -e "\n${GREEN}Done! Finance spending chart is back.${NC}\n"
