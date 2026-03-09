#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'; RED='\033[0;31m'
echo -e "\n${BLUE}Fix: Finance Dashboard spending chart${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

# The bug: <defs> is placed INSIDE <BarChart> but OUTSIDE <Bar>.
# Recharts doesn't render SVG <defs> at the BarChart level.
# Fix: replace per-bar Cell gradient with a single solid fill gradient
# using a Customized component or simply use a solid color fill with
# a LinearGradient defined via the recharts built-in approach.

OLD_CHART = '''          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={financialData.monthlyTrend}>
              <XAxis 
                dataKey="month" 
                stroke="#94a3b8" 
                style={{ fontSize: '12px' }}
              />
              <YAxis 
                stroke="#94a3b8" 
                style={{ fontSize: '12px' }}
                tickFormatter={(value) => `$${(value / 1000)}K`}
              />
              <Tooltip 
                contentStyle={{ 
                  backgroundColor: '#1e293b', 
                  border: '1px solid #334155',
                  borderRadius: '8px',
                  color: '#fff'
                }}
                formatter={(value) => [`$${value.toLocaleString()}`, 'Spend']}
              />
              <Bar 
                dataKey="spend" 
                radius={[8, 8, 0, 0]}
              >
                {financialData.monthlyTrend.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={`url(#colorGradient${index})`} />
                ))}
              </Bar>
              <defs>
                {financialData.monthlyTrend.map((entry, index) => (
                  <linearGradient key={`gradient-${index}`} id={`colorGradient${index}`} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#3b82f6" stopOpacity={0.8}/>
                    <stop offset="100%" stopColor="#6366f1" stopOpacity={0.6}/>
                  </linearGradient>
                ))}
              </defs>
            </BarChart>
          </ResponsiveContainer>'''

NEW_CHART = '''          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={financialData.monthlyTrend} barSize={36}>
              <defs>
                <linearGradient id="spendGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#3b82f6" stopOpacity={0.9}/>
                  <stop offset="100%" stopColor="#6366f1" stopOpacity={0.7}/>
                </linearGradient>
              </defs>
              <XAxis
                dataKey="month"
                stroke="#94a3b8"
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                axisLine={{ stroke: '#334155' }}
                tickLine={false}
              />
              <YAxis
                stroke="#94a3b8"
                tick={{ fill: '#94a3b8', fontSize: 12 }}
                axisLine={false}
                tickLine={false}
                tickFormatter={(value) => `$${(value / 1000).toFixed(0)}K`}
              />
              <Tooltip
                cursor={{ fill: 'rgba(255,255,255,0.04)' }}
                contentStyle={{
                  backgroundColor: '#1e293b',
                  border: '1px solid #334155',
                  borderRadius: '12px',
                  color: '#fff',
                  fontSize: '13px',
                }}
                formatter={(value) => [`$${value.toLocaleString()}`, 'Monthly Spend']}
              />
              <Bar
                dataKey="spend"
                fill="url(#spendGradient)"
                radius={[8, 8, 0, 0]}
              />
            </BarChart>
          </ResponsiveContainer>'''

if OLD_CHART in app:
    app = app.replace(OLD_CHART, NEW_CHART, 1)
    print("  Fixed: <defs> moved inside BarChart (correct Recharts position)")
    print("  Fixed: single shared gradient — no per-bar Cell loop needed")
    print("  Improved: better axis styling, cursor highlight, rounded formatter")
else:
    # Fallback: find and replace just the defs+Cell section
    # The defs block was placed after </Bar> which Recharts ignores
    app = re.sub(
        r'(<Bar\s[^>]*dataKey="spend"[^>]*radius=\{[^}]+\}\s*>)\s*\{financialData\.monthlyTrend\.map[^}]+\}\s*\)\}\s*</Bar>\s*<defs>[^<]*(?:<linearGradient[^>]*>[^<]*(?:<stop[^/]*/>[^<]*)*</linearGradient>[^<]*)*</defs>',
        r'<Bar dataKey="spend" fill="url(#spendGradient)" radius={[8,8,0,0]} />',
        app, flags=re.DOTALL
    )
    # Add defs before BarChart close
    app = re.sub(
        r'(<BarChart data=\{financialData\.monthlyTrend\})',
        '<><defs><linearGradient id="spendGradient" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#3b82f6" stopOpacity={0.9}/><stop offset="100%" stopColor="#6366f1" stopOpacity={0.7}/></linearGradient></defs>\\1',
        app, count=1
    )
    print("  Applied fallback fix")

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
echo -e "\n${GREEN}Done! Finance spending chart restored.${NC}\n"
