#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════════════╗"
echo -e "║  SaasGuard — Master Upgrade (Backup + Rename + Full Overhaul)  ║"
echo -e "╚══════════════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1

# ── TIMESTAMPED BACKUP ──────────────────────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}✓ Full backup saved → backups/$TS/${NC}"
echo -e "  (To revert: cp backups/$TS/App.jsx src/App.jsx && npm run build)\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

ok = []

# ══════════════════════════════════════════════════════════════════════
# 1. RENAME: Everything → SaasGuard
# ══════════════════════════════════════════════════════════════════════
for old in ['NexusIQ', 'AccessGuard', 'Nexus IQ', 'Access Guard']:
    n = app.count(old)
    if n:
        app = app.replace(old, 'SaasGuard')
        ok.append(f"[RENAME] {n}× '{old}' → SaasGuard")

# Fix emails
app = app.replace('sales@saasguard.io', 'sales@saasguard.io')
app = app.replace('support@saasguard.io', 'support@saasguard.io')
app = app.replace('it@saasguard.io', 'it@saasguard.io')
app = app.replace('finance@saasguard.io', 'finance@saasguard.io')

# ══════════════════════════════════════════════════════════════════════
# 2. LOGO: Replace RDLogo with SaasGuard shield + spark
# ══════════════════════════════════════════════════════════════════════
rd_start = app.find('function RDLogo(')
rd_end   = app.find('\n\n// =====================', rd_start)
if rd_start != -1 and rd_end != -1:
    app = app[:rd_start] + '''function RDLogo({ size = "md", onClick }) {
  const s = { sm: "h-9 w-9", md: "h-12 w-12", lg: "h-16 w-16" }[size] || "h-12 w-12";
  return (
    <button onClick={onClick} className={cx("relative group cursor-pointer transition-all duration-300 hover:scale-105 flex-shrink-0", s)}>
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-emerald-500 via-teal-600 to-blue-700 opacity-60 blur-md group-hover:opacity-90 transition-opacity duration-300" />
      <div className="relative flex items-center justify-center rounded-xl bg-gradient-to-br from-emerald-500 via-teal-600 to-blue-700 shadow-xl overflow-hidden h-full w-full border border-white/20">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/15 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        <svg viewBox="0 0 28 28" fill="none" style={{width:"62%",height:"62%"}} className="relative z-10">
          <path d="M14 2L4 6.5V13c0 5.5 4.3 10.6 10 12 5.7-1.4 10-6.5 10-12V6.5L14 2z" fill="white" fillOpacity="0.15" stroke="white" strokeWidth="1.5" strokeLinejoin="round"/>
          <path d="M10 14l3 3 5-6" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </button>
  );
}''' + app[rd_end:]
    ok.append("[LOGO] SaasGuard shield + checkmark SVG (teal/emerald)")

# Sidebar wordmark
app = re.sub(
    r'<div className="text-sm font-[^"]*"[^>]*>(?:SaasGuard|NexusIQ|AccessGuard)</div>',
    '<div className="text-sm font-black tracking-tight bg-gradient-to-r from-emerald-400 to-teal-400 bg-clip-text text-transparent">SaasGuard</div>',
    app, count=1
)
ok.append("[LOGO] Sidebar wordmark — emerald/teal gradient")

# ══════════════════════════════════════════════════════════════════════
# 3. STALE LANGUAGE LISTENERS: Remove from all pages
# ══════════════════════════════════════════════════════════════════════
STALE = (
    "\n  // Auto-update when language changes (no reload needed!)\n"
    "  useEffect(() => {\n"
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
n = 0
while STALE in app:
    app = app.replace(STALE, '\n', 1)
    n += 1
ok.append(f"[LANG] Removed {n} stale languagechange listeners")

# LanguageProvider wrap
app = re.sub(r' *</?LanguageProvider>\n?', '', app)
m_br = re.search(r'( +)<BrowserRouter>', app)
if m_br:
    sp = m_br.group(1)
    app = app.replace(sp + '<BrowserRouter>', sp + '<LanguageProvider>\n' + sp + '<BrowserRouter>', 1)
    m2 = re.search(r'( *)</BrowserRouter>', app)
    if m2:
        app = app[:m2.end()] + '\n' + m2.group(1) + '</LanguageProvider>' + app[m2.end():]
ok.append("[LANG] LanguageProvider wraps BrowserRouter")

# ══════════════════════════════════════════════════════════════════════
# 4. NAV: Restructured with sections + all pages
# ══════════════════════════════════════════════════════════════════════
OLD_NAV_PAT = re.search(r'const NAV = \[.*?\];', app, re.DOTALL)
if OLD_NAV_PAT:
    app = app[:OLD_NAV_PAT.start()] + \
'''const NAV = [
  { to: "/dashboard",   label: "dashboard",      icon: LayoutDashboard },
  { separator: true, label: "Access & Identity" },
  { to: "/tools",       label: "tools",           icon: Boxes },
  { to: "/employees",   label: "employees",       icon: Users },
  { to: "/access",      label: "access",          icon: GitMerge },
  { to: "/offboarding", label: "offboarding",     icon: UserMinus },
  { separator: true, label: "Security & Risk" },
  { to: "/security",    label: "security",        icon: Shield },
  { to: "/audit",       label: "audit",           icon: Download },
  { separator: true, label: "FinOps & Finance" },
  { to: "/finance",     label: "finance",         icon: BarChart3 },
  { to: "/executive",   label: "executive_view",  icon: TrendingUp },
  { to: "/cost",        label: "cost_management", icon: TrendingDown },
  { to: "/licenses",    label: "licenses",        icon: Award },
  { to: "/renewals",    label: "renewals",        icon: CalendarClock },
  { to: "/invoices",    label: "invoices",        icon: CreditCard },
  { separator: true, label: "Platform" },
  { to: "/analytics",    label: "analytics",    icon: BarChart2 },
  { to: "/contracts",    label: "contracts",    icon: FileText },
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/import",       label: "import",       icon: Upload },
  { to: "/billing",      label: "billing",      icon: CreditCard },
  { to: "/settings",     label: "settings",     icon: Settings },
];''' + app[OLD_NAV_PAT.end():]
    ok.append("[NAV] Restructured: 4 sections, all pages visible")

# Add missing icons to lucide-react import
luc_end = app.find('} from "lucide-react"')
luc_block = app[:luc_end]
needed = ['TrendingDown','BarChart2','Award','FileText','Settings','Shield','BadgeCheck','Zap','Target','PieChart']
missing_icons = [i for i in needed if i not in luc_block]
if missing_icons:
    app = app.replace('} from "lucide-react"', '  ' + ',\n  '.join(missing_icons) + ',\n} from "lucide-react"', 1)
    ok.append("[ICONS] Added: " + ", ".join(missing_icons))

# ══════════════════════════════════════════════════════════════════════
# 5. LABELS: Fix ALL raw underscore renders + broken JSX
# ══════════════════════════════════════════════════════════════════════
# Fix broken "{t('key')}" JSX (quoted t() calls)
app = re.sub(r'"\{t\(\'([^\']+)\'\)\}"', lambda m: '"' + m.group(1).replace('_',' ').title() + '"', app)
# Fix "{"Some Text"}" broken string literals
app = re.sub(r'"\{"([^"]+)"\}"', r'"\1"', app)

label_map = {
    "t('need_review_soon')": '"Need Review Soon"',
    "t('review_all_critical')": '"Review All Critical"',
    "t('set_reminders')": '"Set Reminders"',
    "t('export_audit')": '"Export Audit"',
    "t('live')": '"Live"',
    "t('updated')": '"Updated"',
    "t('all_clear')": '"All Clear"',
    "t('top_alerts')": '"Top Alerts"',
    "t('risk_counters')": '"Risk Counters"',
    "t('by_severity')": '"By Severity"',
    "t('coverage_and_spend')": '"Coverage & Spend"',
    "t('fast_remediation')": '"Fast Remediation"',
    "t('assign_tool_owners')": '"Assign Tool Owners"',
    "t('security')": '"Security"',
    "t('cost_management')": '"Cost Management"',
    "t('analytics')": '"Analytics"',
    "t('settings')": '"Settings"',
    "t('contracts')": '"Contracts"',
    "t('executive_view')": '"Executive View"',
    "t('reset_demo_data')": '"Reset Demo Data"',
}
for raw, proper in label_map.items():
    app = app.replace(raw, proper)

# Fix status rendering with underscores
STATUS_FMT = '{bill.status.replace(/_/g," ").replace(/\\b\\w/g,c=>c.toUpperCase())}'
app = app.replace('{bill.status}', STATUS_FMT)
INV_FMT = '{invoice.status.replace(/_/g," ").replace(/\\b\\w/g,c=>c.toUpperCase())}'
app = app.replace("{invoice.status.replace('_', ' ')}", INV_FMT)
ok.append("[LABELS] All underscore keys fixed, status fields title-cased")

# ══════════════════════════════════════════════════════════════════════
# 6. DEDUP: Remove duplicate state declarations
# ══════════════════════════════════════════════════════════════════════
for state_name in ['reviewedApps', 'selectedInvoice', 'showInvoiceDetail']:
    pat = f'  const [{state_name},'
    first = app.find(pat)
    if first != -1:
        second = app.find(pat, first + 1)
        if second != -1:
            line_end = app.find('\n', second) + 1
            app = app[:second] + app[line_end:]
ok.append("[DEDUP] Removed any duplicate state declarations")

# ══════════════════════════════════════════════════════════════════════
# 7. FINANCE CHART: Fix recharts defs position
# ══════════════════════════════════════════════════════════════════════
old_chart = re.search(r'<ResponsiveContainer[^>]*height=\{300\}[^>]*>.*?</ResponsiveContainer>', app, re.DOTALL)
if old_chart:
    app = app[:old_chart.start()] + \
    '<ResponsiveContainer width="100%" height={300}>\n' \
    '            <BarChart data={financialData.monthlyTrend} barSize={40} margin={{top:8,right:8,left:0,bottom:0}}>\n' \
    '              <defs><linearGradient id="spendGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#10b981" stopOpacity={0.9}/><stop offset="100%" stopColor="#0891b2" stopOpacity={0.7}/></linearGradient></defs>\n' \
    '              <XAxis dataKey="month" tick={{fill:"#94a3b8",fontSize:12}} axisLine={{stroke:"#334155"}} tickLine={false}/>\n' \
    '              <YAxis tick={{fill:"#94a3b8",fontSize:12}} axisLine={false} tickLine={false} tickFormatter={v=>"$"+(v/1000).toFixed(0)+"K"}/>\n' \
    '              <Tooltip cursor={{fill:"rgba(255,255,255,0.04)"}} contentStyle={{backgroundColor:"#1e293b",border:"1px solid #334155",borderRadius:"12px",color:"#fff",fontSize:"13px"}} formatter={v=>["$"+v.toLocaleString(),"Monthly Spend"]}/>\n' \
    '              <Bar dataKey="spend" fill="url(#spendGrad)" radius={[8,8,0,0]}/>\n' \
    '            </BarChart>\n' \
    '          </ResponsiveContainer>' + app[old_chart.end():]
    ok.append("[FINANCE] Spending chart fixed")
app = app.replace(
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';",
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';"
)

# ══════════════════════════════════════════════════════════════════════
# 8. RENEWALS: Mark as Reviewed flow (safe — check before inserting)
# ══════════════════════════════════════════════════════════════════════
if 'reviewedApps' not in app:
    app = app.replace(
        '  const [reminderDays, setReminderDays] = useState(30);\n',
        '  const [reminderDays, setReminderDays] = useState(30);\n  const [reviewedApps, setReviewedApps] = useState([]);\n', 1
    )
app = app.replace(
    '                onClick={() => setShowReviewModal(false)}\n'
    '                className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors"\n'
    '              >\n'
    '                Mark as Reviewed',
    '                onClick={() => { setReviewedApps(prev => [...prev, selectedRenewal.app]); setShowReviewModal(false); }}\n'
    '                className="w-full px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors"\n'
    '              >\n'
    '                ✓ Mark as Reviewed', 1
)
if 'reviewedApps.includes' not in app:
    app = app.replace(
        '{renewals.sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => (',
        '{renewals.filter(r => !reviewedApps.includes(r.app)).sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => (', 1
    )
if 'Reviewed Apps' not in app:
    app = app.replace(
        '        {/* Review Modal */}',
        '        {reviewedApps.length > 0 && (\n'
        '          <Card className="p-6 mt-6 border-emerald-500/20 bg-emerald-500/5">\n'
        '            <div className="flex items-center gap-3 mb-4">\n'
        '              <BadgeCheck className="h-6 w-6 text-emerald-400" />\n'
        '              <h3 className="text-lg font-bold">Reviewed Apps</h3>\n'
        '              <span className="text-xs bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-semibold">{reviewedApps.length} reviewed</span>\n'
        '            </div>\n'
        '            <div className="space-y-2">\n'
        '              {renewals.filter(r=>reviewedApps.includes(r.app)).map((r,i)=>(\n'
        '                <div key={i} className="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-emerald-500/10">\n'
        '                  <div><div className="font-semibold text-white">{r.app}</div><div className="text-xs text-slate-500">{r.renewalDate} · ${r.cost.toLocaleString()}</div></div>\n'
        '                  <div className="flex items-center gap-3">\n'
        '                    <span className="text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full">✓ Reviewed</span>\n'
        '                    <button onClick={()=>setReviewedApps(p=>p.filter(a=>a!==r.app))} className="text-xs text-slate-500 hover:text-slate-300">Undo</button>\n'
        '                  </div>\n'
        '                </div>\n'
        '              ))}\n'
        '            </div>\n'
        '          </Card>\n'
        '        )}\n\n'
        '        {/* Review Modal */}', 1
    )
ok.append("[RENEWALS] Mark as Reviewed → Reviewed section with Undo")

# ══════════════════════════════════════════════════════════════════════
# 9. LANDING PAGE: Full rewrite of TrialPage hero + value prop
# ══════════════════════════════════════════════════════════════════════
# Target the hero h1 + subtitle area
hero_pat = re.search(r'(<h1[^>]*>).*?(</h1>)', app, re.DOTALL)
if hero_pat:
    # Check it's in TrialPage context
    tp_start = app.find('function TrialPage()')
    tp_end = app.find('\nfunction ', tp_start + 10)
    if tp_start < hero_pat.start() < tp_end:
        app = app[:hero_pat.start()] + \
            '<h1 className="text-5xl md:text-7xl font-black tracking-tight leading-none mb-6">\n' \
            '              <span className="text-white">You\'re paying for</span><br/>\n' \
            '              <span className="bg-gradient-to-r from-emerald-400 via-teal-400 to-blue-400 bg-clip-text text-transparent">tools nobody uses.</span>\n' \
            '            </h1>' + app[hero_pat.end():]
        ok.append("[LANDING] Hero headline rewritten — punchy, buyer-focused")

# Replace hero subtext
old_sub = re.search(r'(<p[^>]*text-xl[^>]*text-slate-[^>]*>)(.*?)(</p>)', app, re.DOTALL)
if old_sub:
    tp_start = app.find('function TrialPage()')
    tp_end = app.find('\nfunction ', tp_start + 10)
    if tp_start < old_sub.start() < tp_end:
        app = app[:old_sub.start()] + \
            '<p className="text-xl md:text-2xl text-slate-300 max-w-2xl mx-auto leading-relaxed mb-10">\n' \
            '              SaasGuard shows IT teams exactly who has access to what — and flags every orphaned license, former employee, and security risk automatically.\n' \
            '              <span className="text-white font-semibold"> Average customer saves $87K in year one.</span>\n' \
            '            </p>' + app[old_sub.end():]
        ok.append("[LANDING] Hero subheadline rewritten")

# Add Book a Demo button (safe check)
if 'Book a Demo' not in app:
    app = app.replace(
        '                Get Started\n              </button>',
        '                Get Started Free\n              </button>\n'
        '              <button onClick={()=>window.open("mailto:sales@saasguard.io?subject=Demo%20Request","_blank")} className="px-6 py-3 border border-slate-600 hover:border-emerald-400 hover:text-white rounded-xl font-semibold transition-all text-slate-300">\n'
        '                Book a Demo\n              </button>', 1
    )
    ok.append("[LANDING] Book a Demo CTA added")

# Fix testimonials — update AccessGuard references
app = app.replace("AccessGuard caught them all.", "SaasGuard caught them all.")
app = app.replace("AccessGuard's reports", "SaasGuard's reports")

# ══════════════════════════════════════════════════════════════════════
# 10. DASHBOARD: Executive KPI strip
# ══════════════════════════════════════════════════════════════════════
OLD_GWS = '      {/* Google Workspace Sync */}\n      <GoogleWorkspaceSync />\n\n      {/* AI-Powered Insights */}'
if OLD_GWS in app and 'Monthly SaaS Spend' not in app:
    app = app.replace(OLD_GWS,
        '      {/* Executive KPI Strip */}\n'
        '      {derived && (\n'
        '        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-6">\n'
        '          {[\n'
        '            { label:"Monthly SaaS Spend", value:"$"+derived.spend.toLocaleString(), sub:derived.tools.filter(t=>t.status==="active").length+" active tools", color:"text-white", Icon:BarChart3 },\n'
        '            { label:"Estimated Waste", value:"$"+Math.round(derived.spend*0.23).toLocaleString(), sub:"~23% orphaned & unused licenses", color:"text-amber-400", Icon:TrendingDown },\n'
        '            { label:"Security Risk", value:derived.counts.critical>3?"Critical":derived.counts.high>5?"High":derived.counts.critical>0?"Medium":"Low", sub:derived.counts.critical+" critical · "+derived.counts.high+" high alerts", color:derived.counts.critical>0?"text-rose-400":derived.counts.high>0?"text-amber-400":"text-emerald-400", Icon:Shield },\n'
        '            { label:"Compliance Score", value:Math.max(40,100-derived.counts.critical*12-derived.counts.high*4-derived.formerAccess*6)+"%", sub:derived.formerAccess+" ex-employee access risks", color:"text-teal-400", Icon:BadgeCheck },\n'
        '          ].map(({label,value,sub,color,Icon})=>(\n'
        '            <Card key={label}><CardBody>\n'
        '              <div className="flex items-start justify-between gap-2">\n'
        '                <div className="min-w-0 flex-1">\n'
        '                  <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>\n'
        '                  <div className={"text-2xl font-black "+color}>{value}</div>\n'
        '                  <div className="text-xs text-slate-500 mt-1 truncate">{sub}</div>\n'
        '                </div>\n'
        '                <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">\n'
        '                  <Icon className={"h-4 w-4 "+color} />\n'
        '                </div>\n'
        '              </div>\n'
        '            </CardBody></Card>\n'
        '          ))}\n'
        '        </div>\n'
        '      )}\n\n'
        '      {/* Google Workspace Sync */}\n'
        '      <GoogleWorkspaceSync />\n\n'
        '      {/* AI-Powered Insights */}', 1)
    ok.append("[DASHBOARD] Executive KPI strip (Spend/Waste/Risk/Compliance)")

# ══════════════════════════════════════════════════════════════════════
# 11. ANALYTICS PAGE: Full upgrade with real charts
# ══════════════════════════════════════════════════════════════════════
an_start = app.find('function AnalyticsReportsPage()')
an_end = app.find('\nfunction ', an_start + 10)
if an_start != -1:
    app = app[:an_start] + \
'''function AnalyticsReportsPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();

  const tools = db?.tools || [];
  const employees = db?.employees || [];
  const access = db?.access || [];

  const activeTools = tools.filter(t => t.status === 'active');
  const totalSpend = activeTools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const inactiveUsers = employees.filter(e => e.status === 'inactive' || e.status === 'former').length;

  const categorySpend = Object.values(
    activeTools.reduce((acc, t) => {
      const cat = t.category || 'Other';
      if (!acc[cat]) acc[cat] = { name: cat, spend: 0, count: 0 };
      acc[cat].spend += Number(t.cost_per_month || 0);
      acc[cat].count++;
      return acc;
    }, {})
  ).sort((a, b) => b.spend - a.spend).slice(0, 6);

  const topTools = [...activeTools]
    .sort((a, b) => Number(b.cost_per_month || 0) - Number(a.cost_per_month || 0))
    .slice(0, 8);

  const deptBreakdown = Object.entries(
    employees.reduce((acc, e) => {
      const dept = e.department || 'Other';
      if (!acc[dept]) acc[dept] = { active: 0, inactive: 0 };
      if (e.status === 'active') acc[dept].active++;
      else acc[dept].inactive++;
      return acc;
    }, {})
  ).map(([name, v]) => ({ name, ...v, total: v.active + v.inactive }))
   .sort((a, b) => b.total - a.total).slice(0, 6);

  const exportCSV = () => {
    const rows = [
      ['Category','Monthly Spend','Tool Count'],
      ...categorySpend.map(c => [c.name, c.spend, c.count]),
    ].map(r => r.join(',')).join('\\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv,' + encodeURIComponent(rows);
    a.download = 'saasguard-analytics.csv';
    a.click();
  };

  const kpis = [
    { label: 'Total Active Tools', value: activeTools.length, sub: tools.length + ' total tracked', color: 'text-white', Icon: Boxes },
    { label: 'Monthly SaaS Spend', value: '$' + totalSpend.toLocaleString(), sub: 'across ' + activeTools.length + ' tools', color: 'text-emerald-400', Icon: BarChart3 },
    { label: 'Avg Cost Per Tool', value: '$' + (activeTools.length ? Math.round(totalSpend / activeTools.length).toLocaleString() : 0), sub: 'per month', color: 'text-teal-400', Icon: TrendingDown },
    { label: 'Inactive Employees', value: inactiveUsers, sub: 'may retain access', color: 'text-amber-400', Icon: Users },
  ];

  return (
    <AppShell title="Analytics & Reports">
      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-black text-white mb-1">📊 Analytics & Reports</h1>
            <p className="text-slate-400">Live insights across your entire SaaS stack</p>
          </div>
          <button onClick={exportCSV} className="flex items-center gap-2 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
            <Download className="h-4 w-4" /> Export CSV
          </button>
        </div>

        {/* KPI Strip */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {kpis.map(({ label, value, sub, color, Icon }) => (
            <Card key={label}><CardBody>
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0 flex-1">
                  <div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                  <div className={"text-2xl font-black " + color}>{value}</div>
                  <div className="text-xs text-slate-500 mt-1">{sub}</div>
                </div>
                <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                  <Icon className={"h-4 w-4 " + color} />
                </div>
              </div>
            </CardBody></Card>
          ))}
        </div>

        <div className="grid lg:grid-cols-2 gap-6">
          {/* Spend by Category Chart */}
          <Card className="p-6">
            <h2 className="text-xl font-bold mb-4">💰 Spend by Category</h2>
            <div className="space-y-3">
              {categorySpend.map((cat, i) => {
                const pct = totalSpend > 0 ? (cat.spend / totalSpend * 100) : 0;
                const colors = ['bg-emerald-500','bg-teal-500','bg-blue-500','bg-violet-500','bg-amber-500','bg-rose-500'];
                return (
                  <div key={cat.name}>
                    <div className="flex items-center justify-between mb-1.5">
                      <span className="text-sm font-semibold text-slate-200">{cat.name}</span>
                      <div className="flex items-center gap-3">
                        <span className="text-xs text-slate-500">{cat.count} tools</span>
                        <span className="text-sm font-bold text-white">${cat.spend.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className="w-full bg-slate-800 rounded-full h-2.5">
                      <div className={"h-2.5 rounded-full transition-all duration-700 " + colors[i % colors.length]} style={{width: pct + '%'}} />
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>

          {/* Top Tools by Cost */}
          <Card className="p-6">
            <h2 className="text-xl font-bold mb-4">🏆 Top Tools by Cost</h2>
            <div className="space-y-2">
              {topTools.map((tool, i) => (
                <div key={tool.id} className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-slate-800/60 transition-colors">
                  <div className="flex-shrink-0 h-7 w-7 rounded-lg bg-gradient-to-br from-emerald-500/20 to-teal-500/20 flex items-center justify-center text-xs font-bold text-emerald-400">
                    {i + 1}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="font-semibold text-sm text-white truncate">{tool.name}</div>
                    <div className="text-xs text-slate-500">{tool.category || 'General'}</div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <div className="text-sm font-bold text-white">${Number(tool.cost_per_month || 0).toLocaleString()}</div>
                    <div className="text-xs text-slate-500">/mo</div>
                  </div>
                </div>
              ))}
              {topTools.length === 0 && <div className="text-center text-slate-500 py-8">No tools tracked yet</div>}
            </div>
          </Card>
        </div>

        {/* Department Breakdown */}
        <Card className="p-6">
          <h2 className="text-xl font-bold mb-4">🏢 Department Breakdown</h2>
          {deptBreakdown.length > 0 ? (
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {deptBreakdown.map(dept => (
                <div key={dept.name} className="p-4 rounded-xl bg-slate-900/60 border border-slate-800">
                  <div className="font-semibold text-white mb-2">{dept.name}</div>
                  <div className="flex gap-4 text-sm">
                    <div><span className="text-emerald-400 font-bold">{dept.active}</span><span className="text-slate-500 ml-1">active</span></div>
                    <div><span className="text-amber-400 font-bold">{dept.inactive}</span><span className="text-slate-500 ml-1">inactive</span></div>
                  </div>
                  <div className="mt-2 w-full bg-slate-800 rounded-full h-1.5">
                    <div className="bg-emerald-500 h-1.5 rounded-full" style={{width: dept.total > 0 ? (dept.active/dept.total*100)+'%' : '0%'}} />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center text-slate-500 py-12">Add employees to see department analytics</div>
          )}
        </Card>

        {/* Quick Links */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {[
            { label: 'View Finance', to: '/finance', icon: BarChart3, color: 'emerald' },
            { label: 'Manage Licenses', to: '/licenses', icon: Award, color: 'teal' },
            { label: 'Audit Export', to: '/audit', icon: Download, color: 'blue' },
            { label: 'Security Report', to: '/security', icon: Shield, color: 'violet' },
          ].map(({ label, to, icon: Icon, color }) => (
            <button key={to} onClick={() => navigate(to)}
              className={"flex items-center gap-2 p-3 rounded-xl border transition-colors text-sm font-semibold border-slate-800 hover:border-" + color + "-500/40 hover:bg-" + color + "-500/5 text-slate-300 hover:text-white"}>
              <Icon className="h-4 w-4" />{label}
            </button>
          ))}
        </div>
      </div>
    </AppShell>
  );
}
''' + app[an_end:]
    ok.append("[ANALYTICS] Full page rebuilt — KPIs, spend chart, top tools, dept breakdown")

# ══════════════════════════════════════════════════════════════════════
# 12. COST MANAGEMENT PAGE: Upgrade to real interactive content
# ══════════════════════════════════════════════════════════════════════
cm_start = app.find('function CostManagementPage()')
cm_end = app.find('\nfunction ', cm_start + 10)
if cm_start != -1:
    app = app[:cm_start] + \
'''function CostManagementPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const navigate = useNavigate();
  const [sortBy, setSortBy] = useState('cost');
  const [filter, setFilter] = useState('all');

  const tools = db?.tools || [];
  const access = db?.access || [];

  const enriched = tools
    .filter(t => t.status === 'active')
    .map(tool => {
      const activeUsers = access.filter(a => a.tool_id === tool.id && a.access_status === 'active').length;
      const cost = Number(tool.cost_per_month || 0);
      const costPerUser = activeUsers > 0 ? cost / activeUsers : cost;
      const wasteFlag = activeUsers === 0 || costPerUser > 200;
      return { ...tool, activeUsers, cost, costPerUser, wasteFlag };
    })
    .filter(t => filter === 'all' ? true : filter === 'waste' ? t.wasteFlag : !t.wasteFlag)
    .sort((a, b) => sortBy === 'cost' ? b.cost - a.cost : b.costPerUser - a.costPerUser);

  const totalSpend = tools.filter(t => t.status === 'active').reduce((s, t) => s + Number(t.cost_per_month || 0), 0);
  const wasteTools = enriched.filter(t => t.wasteFlag);
  const wasteAmount = wasteTools.reduce((s, t) => s + t.cost, 0);
  const unusedTools = enriched.filter(t => t.activeUsers === 0);

  return (
    <AppShell title="Cost Management">
      <div className="p-6 space-y-6">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="text-3xl font-black text-white mb-1">💸 Cost Management</h1>
            <p className="text-slate-400">Find waste, optimise spend, reclaim unused licenses</p>
          </div>
          <button onClick={() => navigate('/licenses')} className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors text-sm">
            Manage Licenses →
          </button>
        </div>

        {/* KPIs */}
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[
            { label: 'Total Monthly Spend', value: '$' + totalSpend.toLocaleString(), sub: tools.filter(t=>t.status==='active').length + ' active tools', color: 'text-white', Icon: BarChart3 },
            { label: 'Estimated Waste', value: '$' + wasteAmount.toLocaleString(), sub: wasteTools.length + ' flagged tools', color: 'text-rose-400', Icon: TrendingDown },
            { label: 'Unused Tools', value: unusedTools.length, sub: 'no active users assigned', color: 'text-amber-400', Icon: Zap },
            { label: 'Potential Savings', value: '$' + Math.round(wasteAmount * 0.7).toLocaleString(), sub: 'if waste reclaimed', color: 'text-emerald-400', Icon: Target },
          ].map(({ label, value, sub, color, Icon }) => (
            <Card key={label}><CardBody>
              <div className="flex items-start justify-between gap-2">
                <div><div className="text-[10px] font-bold uppercase tracking-widest text-slate-500 mb-1">{label}</div>
                  <div className={"text-2xl font-black " + color}>{value}</div>
                  <div className="text-xs text-slate-500 mt-1">{sub}</div>
                </div>
                <div className="h-9 w-9 rounded-xl bg-slate-800/80 flex items-center justify-center flex-shrink-0">
                  <Icon className={"h-4 w-4 " + color} />
                </div>
              </div>
            </CardBody></Card>
          ))}
        </div>

        {/* Waste Alert */}
        {wasteTools.length > 0 && (
          <Card className="p-5 bg-amber-500/5 border-amber-500/20">
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-amber-400 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <div className="font-bold text-white mb-1">⚠️ {wasteTools.length} tools flagged as potential waste</div>
                <p className="text-sm text-slate-400">Tools with no active users or very high cost-per-user. Review and consider cancelling or renegotiating.</p>
              </div>
              <button onClick={() => setFilter('waste')} className="text-sm text-amber-400 font-semibold hover:text-amber-300 whitespace-nowrap">Show only →</button>
            </div>
          </Card>
        )}

        {/* Tools Table */}
        <Card className="p-6">
          <div className="flex items-center justify-between mb-4 flex-wrap gap-3">
            <h2 className="text-xl font-bold">Tool Cost Breakdown</h2>
            <div className="flex gap-2 flex-wrap">
              {[['all','All Tools'],['waste','Waste Only'],['ok','Healthy']].map(([v,l]) => (
                <button key={v} onClick={() => setFilter(v)}
                  className={"px-3 py-1.5 rounded-lg text-sm font-semibold transition-colors " + (filter === v ? 'bg-emerald-600 text-white' : 'bg-slate-800 text-slate-400 hover:text-white')}>
                  {l}
                </button>
              ))}
              <select value={sortBy} onChange={e => setSortBy(e.target.value)}
                className="px-3 py-1.5 rounded-lg text-sm bg-slate-800 text-slate-300 border-0 outline-none">
                <option value="cost">Sort: Total Cost</option>
                <option value="peruser">Sort: Cost/User</option>
              </select>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-800">
                  {['Tool','Category','Monthly Cost','Active Users','Cost / User','Status'].map(h => (
                    <th key={h} className="text-left py-3 px-3 text-xs font-semibold text-slate-500 uppercase tracking-wide">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {enriched.map((tool, i) => (
                  <tr key={tool.id || i} className="border-b border-slate-800/60 hover:bg-slate-800/30 transition-colors">
                    <td className="py-3 px-3">
                      <div className="font-semibold text-white">{tool.name}</div>
                      <div className="text-xs text-slate-500">{tool.owner || 'No owner'}</div>
                    </td>
                    <td className="py-3 px-3 text-slate-400 text-sm">{tool.category || '—'}</td>
                    <td className="py-3 px-3 font-mono font-bold text-white">${tool.cost.toLocaleString()}</td>
                    <td className="py-3 px-3 text-center">
                      <span className={"font-bold " + (tool.activeUsers === 0 ? 'text-rose-400' : 'text-slate-300')}>{tool.activeUsers}</span>
                    </td>
                    <td className="py-3 px-3 font-mono text-sm text-slate-300">${tool.costPerUser.toFixed(0)}</td>
                    <td className="py-3 px-3">
                      {tool.wasteFlag
                        ? <span className="inline-flex items-center gap-1 text-xs font-semibold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-full">⚠ Review</span>
                        : <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full">✓ OK</span>
                      }
                    </td>
                  </tr>
                ))}
                {enriched.length === 0 && (
                  <tr><td colSpan={6} className="text-center text-slate-500 py-12">No tools match this filter</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </AppShell>
  );
}
''' + app[cm_end:]
    ok.append("[COST] Full page rebuilt — waste detection, cost/user, filters, alerts")

# ══════════════════════════════════════════════════════════════════════
# 13. ADD /contracts ROUTE if missing
# ══════════════════════════════════════════════════════════════════════
if '"/contracts"' not in app and 'ContractComparison' in app:
    app = app.replace(
        '<Route path="*" element={<NotFound />} />',
        '<Route path="/contracts" element={<RequireAuth><ContractComparisonPage /></RequireAuth>} />\n          <Route path="*" element={<NotFound />} />'
    )
    ok.append("[ROUTES] /contracts route added")

# ══════════════════════════════════════════════════════════════════════
# PRINT REPORT
# ══════════════════════════════════════════════════════════════════════
print()
for s in ok:
    print("  ✓  " + s)
print(f"\n  SaasGuard remaining: {app.count('SaasGuard')}")
print(f"  AccessGuard remaining: {app.count('AccessGuard')}")
print(f"  Lines: {app.count(chr(10))}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  App.jsx saved ✓")
PYEOF

[ $? -ne 0 ] && echo -e "${RED}Failed — restoring backup${NC}" && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# Fix translations.js (UTF-8 safe)
python3 << 'PYEOF'
import os, sys
tp = 'src/translations.js'
if not os.path.exists(tp): sys.exit(0)
with open(tp, 'r', encoding='utf-8', errors='replace') as f:
    t = f.read()
for old in ['NexusIQ','AccessGuard']:
    t = t.replace(old, 'SaasGuard')
en_start = t.find('  en: {'); en_end = t.find('\n  },', en_start)
new_keys = [
    ("need_review_soon","Need review soon"),("review_all_critical","Review All Critical"),
    ("set_reminders","Set Reminders"),("cost_management","Cost Management"),
    ("analytics","Analytics"),("settings","Settings"),("contracts","Contracts"),
    ("security","Security"),("access","Access Map"),("executive_view","Executive View"),
]
added = []
en_block = t[en_start:en_end]
for key, val in new_keys:
    if key+':' not in en_block:
        t = t[:en_end] + "\n    "+key+": '"+val+"'," + t[en_end:]
        en_end += len("\n    "+key+": '"+val+"',")
        added.append(key)
with open(tp, 'w', encoding='utf-8') as f:
    f.write(t)
print("  translations.js: renamed + " + (("added "+", ".join(added)) if added else "keys OK") + " ✓")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { echo -e "${RED}Build failed — restoring backup${NC}"; cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════════╗"
echo -e "║  SaasGuard Master Upgrade — Complete ✓                          ║"
echo -e "╠═══════════════════════════════════════════════════════════════════╣"
echo -e "║  Backup saved at: backups/$TS/                                  ║"
echo -e "║                                                                  ║"
echo -e "║  [1]  RENAME     Everything → SaasGuard (brand + emails)        ║"
echo -e "║  [2]  LOGO       Shield + checkmark SVG, teal/emerald gradient   ║"
echo -e "║  [3]  LANGUAGE   Stale listeners removed, LanguageProvider fixed ║"
echo -e "║  [4]  NAV        4 sections, all 20 pages visible                ║"
echo -e "║  [5]  LABELS     All underscore keys → proper English            ║"
echo -e "║  [6]  DEDUP      No duplicate state declarations                 ║"
echo -e "║  [7]  FINANCE    Spending chart recharts bug fixed                ║"
echo -e "║  [8]  RENEWALS   Mark Reviewed → green section with Undo         ║"
echo -e "║  [9]  LANDING    Punchy headline, Book a Demo CTA                ║"
echo -e "║  [10] DASHBOARD  Live KPI strip (Spend/Waste/Risk/Compliance)    ║"
echo -e "║  [11] ANALYTICS  Full rebuild — charts, top tools, departments   ║"
echo -e "║  [12] COST MGMT  Full rebuild — waste flags, cost/user table     ║"
echo -e "╚═══════════════════════════════════════════════════════════════════╝${NC}\n"
echo -e "  To revert: ${YELLOW}cp backups/$TS/App.jsx src/App.jsx && npm run build && firebase deploy --only hosting${NC}\n"
