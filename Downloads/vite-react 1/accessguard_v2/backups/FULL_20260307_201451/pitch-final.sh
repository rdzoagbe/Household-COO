#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}╔══════════════════════════════════════════════════╗"
echo -e "║  NexusIQ — Full Pitch Upgrade (applies to live) ║"
echo -e "╚══════════════════════════════════════════════════╝${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []

# ══════════════════════════════════════════════════════
# 1. REBRAND: AccessGuard → NexusIQ (all occurrences)
# ══════════════════════════════════════════════════════
before = app.count('AccessGuard')
app = app.replace('AccessGuard', 'NexusIQ')
after = app.count('AccessGuard')
ok.append("Rebrand: " + str(before) + " AccessGuard → NexusIQ (" + str(after) + " remaining)")

# ══════════════════════════════════════════════════════
# 2. Remove "by Roland D." — both instances
# ══════════════════════════════════════════════════════
app = app.replace(
    '<div className="text-xs text-slate-400">by Roland D.</div>',
    '<div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
app = app.replace(
    '<div className="text-xs text-slate-500 font-medium">by Roland D.</div>',
    '<div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
ok.append("Removed 'by Roland D.' → 'SaaS Intelligence' tagline")

# ══════════════════════════════════════════════════════
# 3. NEW LOGO — Replace RDLogo with NexusIQ shield+spark
# ══════════════════════════════════════════════════════
rd_start = app.find('function RDLogo(')
rd_end   = app.find('\n\n// =====================', rd_start)
if rd_start != -1 and rd_end != -1:
    NEW_LOGO = '''function RDLogo({ size = "md", onClick }) {
  const sizes = {
    sm: { box: "h-9 w-9" },
    md: { box: "h-12 w-12" },
    lg: { box: "h-16 w-16" },
  };
  const s = sizes[size] || sizes.md;
  return (
    <button onClick={onClick} className={cx("relative group cursor-pointer transition-all duration-300 hover:scale-105 flex-shrink-0", s.box)}>
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 opacity-60 blur-md group-hover:opacity-90 transition-opacity duration-300" />
      <div className="relative flex items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 shadow-xl overflow-hidden h-full w-full border border-white/20">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/15 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        <svg viewBox="0 0 28 28" fill="none" style={{width:"60%",height:"60%"}} className="relative z-10">
          <path d="M14 2L4 6.5V13c0 5.5 4.3 10.6 10 12 5.7-1.4 10-6.5 10-12V6.5L14 2z"
            fill="white" fillOpacity="0.15" stroke="white" strokeWidth="1.4" strokeLinejoin="round"/>
          <path d="M16 8h-4.5l-2 6h3.5l-1.5 6 7-8h-4l1.5-4z" fill="white" fillOpacity="0.95"/>
        </svg>
      </div>
      <div className="absolute inset-0 rounded-xl border border-white/0 group-hover:border-white/25 transition-colors duration-300" />
    </button>
  );
}'''
    app = app[:rd_start] + NEW_LOGO + app[rd_end:]
    ok.append("Logo: NexusIQ shield + lightning bolt SVG")

# ══════════════════════════════════════════════════════
# 4. SIDEBAR wordmark: gradient + live pulse dot
# ══════════════════════════════════════════════════════
OLD_WM = (
    '              <div className="text-sm font-semibold text-white">NexusIQ</div>\n'
    '              <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
NEW_WM = (
    '              <div className="text-sm font-black tracking-tight bg-gradient-to-r from-blue-400 to-violet-400 bg-clip-text text-transparent">NexusIQ</div>\n'
    '              <div className="flex items-center gap-1.5">\n'
    '                <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>\n'
    '                <div className="flex items-center gap-1">\n'
    '                  <div className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />\n'
    '                  <span className="text-[9px] text-emerald-500 font-bold uppercase">Live</span>\n'
    '                </div>\n'
    '              </div>'
)
if OLD_WM in app:
    app = app.replace(OLD_WM, NEW_WM, 1)
    ok.append("Sidebar: gradient wordmark + live pulse dot")

# ══════════════════════════════════════════════════════
# 5. NAV: Restructure with sections + missing pages
# ══════════════════════════════════════════════════════
OLD_NAV = (
    'const NAV = [\n'
    '  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },\n'
    '  { to: "/tools", label: "tools", icon: Boxes },\n'
    '  { to: "/employees", label: "employees", icon: Users },\n'
    '  { to: "/access", label: "access", icon: GitMerge },\n'
    '  { to: "/integrations", label: "integrations", icon: Plug },\n'
    '  { to: "/import", label: "import", icon: Upload },\n'
    '  { to: "/offboarding", label: "offboarding", icon: UserMinus },\n'
    '  { to: "/audit", label: "audit", icon: Download },\n'
    '  { to: "/billing", label: "billing", icon: CreditCard },\n'
    '  { separator: true, label: "FinOps & Finance" },\n'
    '  { to: "/finance", label: "finance", icon: BarChart3 },\n'
    '  { to: "/executive", label: "executive_view", icon: TrendingUp },\n'
    '  { to: "/licenses", label: "licenses", icon: Users },\n'
    '  { to: "/renewals", label: "renewals", icon: CalendarClock },\n'
    '  { to: "/invoices", label: "invoices", icon: Upload },\n'
    '];'
)
NEW_NAV = (
    'const NAV = [\n'
    '  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },\n'
    '  { separator: true, label: "Access & Identity" },\n'
    '  { to: "/tools",       label: "tools",       icon: Boxes },\n'
    '  { to: "/employees",   label: "employees",   icon: Users },\n'
    '  { to: "/access",      label: "access",      icon: GitMerge },\n'
    '  { to: "/offboarding", label: "offboarding", icon: UserMinus },\n'
    '  { separator: true, label: "Security & Risk" },\n'
    '  { to: "/security", label: "security", icon: Shield },\n'
    '  { to: "/audit",    label: "audit",    icon: Download },\n'
    '  { separator: true, label: "FinOps & Finance" },\n'
    '  { to: "/finance",    label: "finance",         icon: BarChart3 },\n'
    '  { to: "/executive",  label: "executive_view",  icon: TrendingUp },\n'
    '  { to: "/cost",       label: "cost_management", icon: TrendingDown },\n'
    '  { to: "/licenses",   label: "licenses",        icon: Award },\n'
    '  { to: "/renewals",   label: "renewals",        icon: CalendarClock },\n'
    '  { to: "/invoices",   label: "invoices",        icon: CreditCard },\n'
    '  { separator: true, label: "Platform" },\n'
    '  { to: "/analytics",    label: "analytics",    icon: BarChart2 },\n'
    '  { to: "/integrations", label: "integrations", icon: Plug },\n'
    '  { to: "/import",       label: "import",       icon: Upload },\n'
    '  { to: "/contracts",    label: "contracts",    icon: FileText },\n'
    '  { to: "/billing",      label: "billing",      icon: CreditCard },\n'
    '  { to: "/settings",     label: "settings",     icon: Settings },\n'
    '];'
)
if OLD_NAV in app:
    app = app.replace(OLD_NAV, NEW_NAV, 1)
    ok.append("NAV: 4 sections + Security/Cost/Analytics/Contracts/Settings added")

# ══════════════════════════════════════════════════════
# 6. ICONS: Add missing ones to lucide-react import
# ══════════════════════════════════════════════════════
luc_block_end = app.find('} from "lucide-react"')
luc_block = app[:luc_block_end]
needed = ['TrendingDown', 'BarChart2', 'Award', 'FileText', 'Settings', 'Wrench']
missing = [i for i in needed if i not in luc_block]
if missing:
    app = app.replace(
        '} from "lucide-react"',
        '  ' + ',\n  '.join(missing) + ',\n} from "lucide-react"',
        1
    )
    ok.append("Icons added: " + ", ".join(missing))

# ══════════════════════════════════════════════════════
# 7. DASHBOARD: Executive KPI strip
# ══════════════════════════════════════════════════════
OLD_GWS = '      {/* Google Workspace Sync */}\n      <GoogleWorkspaceSync />\n\n      {/* AI-Powered Insights */}'
NEW_GWS = (
    '      {/* Executive KPI Strip */}\n'
    '      {derived && (\n'
    '        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-4">\n'
    '          {[\n'
    '            { label: "Monthly SaaS Spend",\n'
    '              value: "$" + derived.spend.toLocaleString(),\n'
    '              sub: derived.tools.filter(t=>t.status==="active").length + " active tools",\n'
    '              color: "text-white", Icon: BarChart3 },\n'
    '            { label: "Estimated Waste",\n'
    '              value: "$" + Math.round(derived.spend * 0.23).toLocaleString(),\n'
    '              sub: "~23% in orphaned + unused licenses",\n'
    '              color: "text-amber-400", Icon: TrendingDown },\n'
    '            { label: "Security Risk",\n'
    '              value: derived.counts.critical > 3 ? "Critical" : derived.counts.high > 5 ? "High" : derived.counts.critical > 0 ? "Medium" : "Low",\n'
    '              sub: derived.counts.critical + " critical · " + derived.counts.high + " high alerts",\n'
    '              color: derived.counts.critical > 0 ? "text-rose-400" : derived.counts.high > 0 ? "text-amber-400" : "text-emerald-400",\n'
    '              Icon: Shield },\n'
    '            { label: "Compliance Readiness",\n'
    '              value: Math.max(40, 100 - derived.counts.critical * 12 - derived.counts.high * 4 - derived.formerAccess * 6) + "%",\n'
    '              sub: derived.formerAccess + " ex-employee access risks",\n'
    '              color: "text-blue-400", Icon: BadgeCheck },\n'
    '          ].map(({ label, value, sub, color, Icon }) => (\n'
    '            <Card key={label}>\n'
    '              <CardBody>\n'
    '                <div className="flex items-start justify-between gap-2">\n'
    '                  <div className="min-w-0 flex-1">\n'
    '                    <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>\n'
    '                    <div className={"text-2xl font-black " + color}>{value}</div>\n'
    '                    <div className="text-xs text-slate-500 mt-1 truncate">{sub}</div>\n'
    '                  </div>\n'
    '                  <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">\n'
    '                    <Icon className={"h-4 w-4 " + color} />\n'
    '                  </div>\n'
    '                </div>\n'
    '              </CardBody>\n'
    '            </Card>\n'
    '          ))}\n'
    '        </div>\n'
    '      )}\n\n'
    '      {/* Google Workspace Sync */}\n'
    '      <GoogleWorkspaceSync />\n\n'
    '      {/* AI-Powered Insights */}'
)
if OLD_GWS in app:
    app = app.replace(OLD_GWS, NEW_GWS, 1)
    ok.append("Dashboard: Executive KPI strip (Spend/Waste/Risk/Compliance)")

# ══════════════════════════════════════════════════════
# 8. LANDING: Book a Demo button in nav
# ══════════════════════════════════════════════════════
OLD_CTA = (
    '                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl font-semibold transition-all duration-300 shadow-lg hover:scale-105"\n'
    '              >\n'
    '                Get Started\n'
    '              </button>'
)
NEW_CTA = (
    '                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl font-semibold transition-all duration-300 shadow-lg hover:scale-105"\n'
    '              >\n'
    '                Get Started Free\n'
    '              </button>\n'
    '              <button\n'
    '                onClick={() => window.open("mailto:sales@nexusiq.io?subject=Demo%20Request&body=Hi%2C%20I%27d%20like%20to%20book%20a%20demo%20of%20NexusIQ%20for%20our%20team.", "_blank")}\n'
    '                className="px-6 py-3 border border-slate-600 hover:border-blue-400 hover:text-white rounded-xl font-semibold transition-all duration-300 text-slate-300"\n'
    '              >\n'
    '                Book a Demo\n'
    '              </button>'
)
if OLD_CTA in app:
    app = app.replace(OLD_CTA, NEW_CTA, 1)
    ok.append("Landing: 'Book a Demo' button added")

# ══════════════════════════════════════════════════════
# 9. LANDING: Hero copy — CTO-targeted
# ══════════════════════════════════════════════════════
OLD_HERO = (
    'NexusIQ finds orphaned licenses, risky access, and compliance gaps\xe2\x80\x94automatically. '
    '<span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> '
    'One dashboard. Zero blind spots.'
)
NEW_HERO = (
    'The command centre for IT Directors, CTOs and Security teams. One platform for every SaaS tool, user, and license across your organisation. '
    '<span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> '
    'SOC 2 ready. Audit-proof. Zero blind spots.'
)
if OLD_HERO in app:
    app = app.replace(OLD_HERO, NEW_HERO, 1)
    ok.append("Landing: hero paragraph — CTO-targeted copy")
else:
    # Try ASCII dash version
    OLD_HERO2 = (
        'NexusIQ finds orphaned licenses, risky access, and compliance gaps-automatically. '
    )
    OLD_HERO3 = 'NexusIQ finds orphaned licenses, risky access, and compliance gaps'
    if OLD_HERO3 in app:
        idx = app.find(OLD_HERO3)
        end = app.find('</p>', idx)
        app = app[:idx] + 'The command centre for IT Directors, CTOs and Security teams. One platform for every SaaS tool, user, and license across your organisation. <span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> SOC 2 ready. Audit-proof. Zero blind spots.' + app[end:]
        ok.append("Landing: hero paragraph — CTO-targeted copy (alt match)")

# ══════════════════════════════════════════════════════
# 10. LANDING: Comparison table — NexusIQ + NEW badge
# ══════════════════════════════════════════════════════
OLD_TBL = '<div className="text-lg font-bold text-white mb-1">NexusIQ</div>'
NEW_TBL = (
    '<div className="flex items-center justify-center gap-2 mb-1">'
    '<span className="text-lg font-bold text-white">NexusIQ</span>'
    '<span className="text-[10px] bg-blue-500 text-white px-1.5 py-0.5 rounded font-bold uppercase tracking-wide">NEW</span>'
    '</div>'
)
if OLD_TBL in app:
    app = app.replace(OLD_TBL, NEW_TBL, 1)
    ok.append("Landing: NexusIQ comparison table — NEW badge added")

# ══════════════════════════════════════════════════════
# Report + save
# ══════════════════════════════════════════════════════
print()
for s in ok:
    print("  OK: " + s)

remaining_ag = app.count('AccessGuard')
print("\n  AccessGuard remaining: " + str(remaining_ag))
if remaining_ag > 0:
    for m in re.finditer('AccessGuard', app):
        lno = app[:m.start()].count('\n')+1
        ctx = app[m.start()-30:m.start()+50].replace('\n',' ')
        print("    L" + str(lno) + ": " + ctx[:80])

print("  Lines: " + str(app.count('\n')))

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  App.jsx saved")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# Fix translations.js — add nav label keys to EN block
python3 << 'PYEOF'
import sys, os

trans_path = 'src/translations.js'
if not os.path.exists(trans_path):
    print("  No src/translations.js — skipping")
    sys.exit(0)

with open(trans_path, 'r', encoding='utf-8') as f:
    t = f.read()

NEW_KEYS = [
    ("cost_management", "Cost Management"),
    ("analytics",       "Analytics"),
    ("settings",        "Settings"),
    ("contracts",       "Contracts"),
    ("security",        "Security"),
]

en_start = t.find('  en: {')
en_end   = t.find('\n  },', en_start)
if en_start == -1 or en_end == -1:
    print("  Could not find EN block")
    sys.exit(0)

en_block = t[en_start:en_end]
added = []
for key, val in NEW_KEYS:
    if (key + ':') not in en_block and (key + ' :') not in en_block:
        insert = "\n    " + key + ": '" + val + "',"
        t = t[:en_end] + insert + t[en_end:]
        en_end += len(insert)
        added.append(key)

with open(trans_path, 'w', encoding='utf-8') as f:
    f.write(t)

if added:
    print("  translations.js: added " + ", ".join(added))
else:
    print("  translations.js: all keys already present")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗"
echo -e "║  NexusIQ — Pitch Upgrade Complete                        ║"
echo -e "╠════════════════════════════════════════════════════════════╣"
echo -e "║  ✓ Rebranded: AccessGuard → NexusIQ everywhere           ║"
echo -e "║  ✓ Logo: shield + lightning bolt, violet/blue gradient   ║"
echo -e "║  ✓ 'by Roland D.' → 'SaaS Intelligence · Live'          ║"
echo -e "║  ✓ Sidebar: gradient wordmark + green pulse dot          ║"
echo -e "║  ✓ NAV: 4 sections with 6 previously hidden pages       ║"
echo -e "║  ✓ Dashboard: KPI strip (Spend/Waste/Risk/Compliance)    ║"
echo -e "║  ✓ Landing: 'Book a Demo' CTA + CTO-targeted hero copy  ║"
echo -e "║  ✓ Landing: NexusIQ NEW badge in comparison table       ║"
echo -e "╚════════════════════════════════════════════════════════════╝${NC}\n"
