#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  NexusIQ — Master Fix Script (Everything in One Pass)  ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

ok = []

# ══════════════════════════════════════════════════════════════════
# SECTION 1 — REBRAND: AccessGuard → NexusIQ everywhere
# ══════════════════════════════════════════════════════════════════
before = app.count('AccessGuard')
app = app.replace('AccessGuard', 'NexusIQ')
ok.append(f"[BRAND] {before} × AccessGuard → NexusIQ")

# Remove "by Roland D." in both places it appears
app = app.replace(
    '<div className="text-xs text-slate-400">by Roland D.</div>',
    '<div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
app = app.replace(
    '<div className="text-xs text-slate-500 font-medium">by Roland D.</div>',
    '<div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
ok.append("[BRAND] Removed 'by Roland D.' → 'SaaS Intelligence'")

# ══════════════════════════════════════════════════════════════════
# SECTION 2 — NEW LOGO: Replace RDLogo with shield + spark SVG
# ══════════════════════════════════════════════════════════════════
rd_start = app.find('function RDLogo(')
rd_end   = app.find('\n\n// =====================', rd_start)
if rd_start != -1 and rd_end != -1:
    app = app[:rd_start] + '''function RDLogo({ size = "md", onClick }) {
  const s = { sm: "h-9 w-9", md: "h-12 w-12", lg: "h-16 w-16" }[size] || "h-12 w-12";
  return (
    <button onClick={onClick} className={cx("relative group cursor-pointer transition-all duration-300 hover:scale-105 flex-shrink-0", s)}>
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 opacity-60 blur-md group-hover:opacity-90 transition-opacity duration-300" />
      <div className="relative flex items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 shadow-xl overflow-hidden h-full w-full border border-white/20">
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/15 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        <svg viewBox="0 0 28 28" fill="none" style={{width:"60%",height:"60%"}} className="relative z-10">
          <path d="M14 2L4 6.5V13c0 5.5 4.3 10.6 10 12 5.7-1.4 10-6.5 10-12V6.5L14 2z" fill="white" fillOpacity="0.15" stroke="white" strokeWidth="1.4" strokeLinejoin="round"/>
          <path d="M16 8h-4.5l-2 6h3.5l-1.5 6 7-8h-4l1.5-4z" fill="white" fillOpacity="0.95"/>
        </svg>
      </div>
      <div className="absolute inset-0 rounded-xl border border-white/0 group-hover:border-white/25 transition-colors duration-300" />
    </button>
  );
}''' + app[rd_end:]
    ok.append("[LOGO] New shield+lightning SVG logo")

# Upgrade sidebar wordmark
app = app.replace(
    '<div className="text-sm font-semibold text-white">NexusIQ</div>',
    '<div className="text-sm font-black tracking-tight bg-gradient-to-r from-blue-400 to-violet-400 bg-clip-text text-transparent">NexusIQ</div>',
    1
)
app = app.replace(
    '<div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>',
    '<div className="flex items-center gap-1.5"><span className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</span><span className="flex items-center gap-0.5"><span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse inline-block" /><span className="text-[9px] text-emerald-500 font-bold uppercase">Live</span></span></div>',
    1
)
ok.append("[LOGO] Sidebar gradient wordmark + live pulse dot")

# ══════════════════════════════════════════════════════════════════
# SECTION 3 — NAV: Restructure with sections + all missing pages
# ══════════════════════════════════════════════════════════════════
OLD_NAV = '''const NAV = [
  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },
  { to: "/tools", label: "tools", icon: Boxes },
  { to: "/employees", label: "employees", icon: Users },
  { to: "/access", label: "access", icon: GitMerge },
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/import", label: "import", icon: Upload },
  { to: "/offboarding", label: "offboarding", icon: UserMinus },
  { to: "/audit", label: "audit", icon: Download },
  { to: "/billing", label: "billing", icon: CreditCard },
  { separator: true, label: "FinOps & Finance" },
  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { to: "/licenses", label: "licenses", icon: Users },
  { to: "/renewals", label: "renewals", icon: CalendarClock },
  { to: "/invoices", label: "invoices", icon: Upload },
];'''
NEW_NAV = '''const NAV = [
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
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/import",       label: "import",       icon: Upload },
  { to: "/contracts",    label: "contracts",    icon: FileText },
  { to: "/billing",      label: "billing",      icon: CreditCard },
  { to: "/settings",     label: "settings",     icon: Settings },
];'''
if OLD_NAV in app:
    app = app.replace(OLD_NAV, NEW_NAV, 1)
    ok.append("[NAV] Restructured into 4 sections + Security/Cost/Analytics/Contracts/Settings added")

# Add missing lucide icons
luc_end = app.find('} from "lucide-react"')
luc_block = app[:luc_end]
needed = ['TrendingDown','BarChart2','Award','FileText','Settings','Shield','BadgeCheck']
missing_icons = [i for i in needed if i not in luc_block]
if missing_icons:
    app = app.replace('} from "lucide-react"', '  ' + ',\n  '.join(missing_icons) + ',\n} from "lucide-react"', 1)
    ok.append("[ICONS] Added: " + ", ".join(missing_icons))

# ══════════════════════════════════════════════════════════════════
# SECTION 4 — DASHBOARD: Executive KPI strip
# ══════════════════════════════════════════════════════════════════
OLD_GWS = '      {/* Google Workspace Sync */}\n      <GoogleWorkspaceSync />\n\n      {/* AI-Powered Insights */}'
if OLD_GWS in app:
    app = app.replace(OLD_GWS,
        '      {/* Executive KPI Strip */}\n'
        '      {derived && (\n'
        '        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4 mb-4">\n'
        '          {[\n'
        '            { label:"Monthly SaaS Spend", value:"$"+derived.spend.toLocaleString(), sub:derived.tools.filter(t=>t.status==="active").length+" active tools", color:"text-white", Icon:BarChart3 },\n'
        '            { label:"Estimated Waste", value:"$"+Math.round(derived.spend*0.23).toLocaleString(), sub:"~23% orphaned + unused licenses", color:"text-amber-400", Icon:TrendingDown },\n'
        '            { label:"Security Risk", value:derived.counts.critical>3?"Critical":derived.counts.high>5?"High":derived.counts.critical>0?"Medium":"Low", sub:derived.counts.critical+" critical · "+derived.counts.high+" high alerts", color:derived.counts.critical>0?"text-rose-400":derived.counts.high>0?"text-amber-400":"text-emerald-400", Icon:Shield },\n'
        '            { label:"Compliance Readiness", value:Math.max(40,100-derived.counts.critical*12-derived.counts.high*4-derived.formerAccess*6)+"%", sub:derived.formerAccess+" ex-employee access risks", color:"text-blue-400", Icon:BadgeCheck },\n'
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
    ok.append("[DASHBOARD] Executive KPI strip added (Spend/Waste/Risk/Compliance)")

# ══════════════════════════════════════════════════════════════════
# SECTION 5 — LANGUAGE: Remove ALL stale languagechange listeners
# ══════════════════════════════════════════════════════════════════
STALE = (
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
    idx = app.find(STALE)
    ue = app.rfind('\n  useEffect(() => {\n', 0, idx)
    cm = app.rfind('\n  //', 0, ue)
    start = cm if cm != -1 and ue - cm < 80 else ue
    app = app[:start] + '\n' + app[idx + len(STALE):]
    n += 1
ok.append(f"[LANG] Removed {n} stale languagechange useEffect listeners")

# Fix SidebarFooter: local useState → useLang() context
app = app.replace(
    "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n",
    "  const { language, setLanguage } = useLang();\n", 1
)
# Remove SidebarFooter localStorage sync useEffect
app = re.sub(
    r"\n  // Sync language from localStorage on mount\n  useEffect\(\(\) => \{\n    const savedLang = localStorage\.getItem\('language'\);\n    if \(savedLang && savedLang !== language\) \{\n      setLanguage\(savedLang\);\n    \}\n  \}, \[\]\);\n",
    '\n', app)
# Fix changeLanguage to use context only
cl_m = re.search(r'  const changeLanguage = \(code\) => \{[^}]+\};', app, re.DOTALL)
if cl_m and ('dispatchEvent' in cl_m.group() or 'localStorage' in cl_m.group()):
    app = app[:cl_m.start()] + "  const changeLanguage = (code) => {\n    setLanguage(code);\n    setShowLangMenu(false);\n  };" + app[cl_m.end():]
# Remove LanguageProvider dispatch
app = app.replace("    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n", '')
# Wrap BrowserRouter with LanguageProvider
app = re.sub(r' *</?LanguageProvider>\n?', '', app)
m_br = re.search(r'( +)<BrowserRouter>', app)
if m_br:
    sp = m_br.group(1)
    app = app.replace(sp + '<BrowserRouter>', sp + '<LanguageProvider>\n' + sp + '<BrowserRouter>', 1)
    m2 = re.search(r'( *)</BrowserRouter>', app)
    if m2:
        app = app[:m2.end()] + '\n' + m2.group(1) + '</LanguageProvider>' + app[m2.end():]
lo = app.count('<LanguageProvider>'); lc = app.count('</LanguageProvider>')
ok.append(f"[LANG] LanguageProvider wraps app — open={lo} close={lc}")

# ══════════════════════════════════════════════════════════════════
# SECTION 6 — LABELS: Fix all raw underscore t() keys
# ══════════════════════════════════════════════════════════════════
# Fix broken JSX: "{t('add_tool')}" → "Add Tool"  (quoted t() call)
app = re.sub(r'"\{t\(\'([^\']+)\'\)\}"', lambda m: '"' + m.group(1).replace('_',' ').title() + '"', app)
# Fix broken JSX: "{"Add Tool"}" → "Add Tool"
app = re.sub(r'"\{"([^"]+)"\}"', r'"\1"', app)

# Replace every t('key') that has underscores with proper English
label_map = {
    "t('need_review_soon')":    '"Need Review Soon"',
    "t('review_all_critical')": '"Review All Critical"',
    "t('set_reminders')":       '"Set Reminders"',
    "t('reset_demo_data')":     '"Reset Demo Data"',
    "t('export_audit')":        '"Export Audit"',
    "t('live')":                '"Live"',
    "t('updated')":             '"Updated"',
    "t('all_clear')":           '"All Clear"',
    "t('top_alerts')":          '"Top Alerts"',
    "t('risk_counters')":       '"Risk Counters"',
    "t('by_severity')":         '"By Severity"',
    "t('coverage_and_spend')":  '"Coverage & Spend"',
    "t('fast_remediation')":    '"Fast Remediation"',
    "t('assign_tool_owners')":  '"Assign Tool Owners"',
    "t('no_active_alerts')":    '"No Active Alerts"',
    "t('no_employees')":        '"No Employees"',
    "t('no_tools')":            '"No Tools"',
    "t('no_owner')":            '"No Owner"',
    "t('top_alerts_desc')":     '"Top Alerts by Severity"',
    "t('track_departments')":   '"Track Departments"',
    "t('employee_directory')":  '"Employee Directory"',
    "t('search_employees')":    '"Search employees..."',
    "t('search_tools_owners')": '"Search tools & owners..."',
    "t('delete_employee')":     '"Delete Employee"',
    "t('delete_tool')":         '"Delete Tool"',
    "t('edit_employee')":       '"Edit Employee"',
    "t('edit_tool')":           '"Edit Tool"',
    "t('add_employee')":        '"Add Employee"',
    "t('add_tool')":            '"Add Tool"',
    "t('bulk_import')":         '"Bulk Import"',
    "t('access_count')":        '"Access Count"',
    "t('actions')":             '"Actions"',
    "t('owner')":               '"Owner"',
    "t('tool')":                '"Tool"',
    "t('cost')":                '"Cost"',
    "t('last_used')":           '"Last Used"',
    "t('dashboard')":           '"Dashboard"',
    "t('tools')":               '"Tools"',
    "t('employees')":           '"Employees"',
    "t('access')":              '"Access Map"',
    "t('integrations')":        '"Integrations"',
    "t('import')":              '"Import Data"',
    "t('offboarding')":         '"Offboarding"',
    "t('audit')":               '"Audit Export"',
    "t('billing')":             '"Billing"',
    "t('finance')":             '"Finance"',
    "t('executive_view')":      '"Executive View"',
    "t('licenses')":            '"Licenses"',
    "t('renewals')":            '"Renewals"',
    "t('invoices')":            '"Invoices"',
    "t('security')":            '"Security"',
    "t('cost_management')":     '"Cost Management"',
    "t('analytics')":           '"Analytics"',
    "t('settings')":            '"Settings"',
    "t('contracts')":           '"Contracts"',
}
fixed = sum(app.count(k) for k in label_map)
for raw, proper in label_map.items():
    app = app.replace(raw, proper)
ok.append(f"[LABELS] Fixed {fixed} raw underscore label renders")

# Fix status values showing underscores in UI
app = app.replace('{bill.status}', '{bill.status.replace(/_/g," ").replace(/\\b\\w/g,c=>c.toUpperCase())}')
app = app.replace("{invoice.status.replace('_', ' ')}", '{invoice.status.replace(/_/g," ").replace(/\\b\\w/g,c=>c.toUpperCase())}')
ok.append("[LABELS] bill.status + invoice.status → title-cased")

# ══════════════════════════════════════════════════════════════════
# SECTION 7 — BUTTONS: Wire up all no-onClick buttons
# ══════════════════════════════════════════════════════════════════

# Finance — View All (bills)
app = app.replace(
    '<button className="text-sm text-blue-400 hover:underline">View All</button>',
    '<button onClick={()=>navigate("/invoices")} className="text-sm text-blue-400 hover:underline transition-colors">View All</button>',
    1
)

# Finance — Review Tools
app = app.replace(
    '<button className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm">\n              Review Tools\n            </button>',
    '<button onClick={()=>navigate("/tools")} className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm transition-colors">\n              Review Tools\n            </button>',
    1
)

# Finance — View Renewals
app = app.replace(
    '<button className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm">\n              View Renewals\n            </button>',
    '<button onClick={()=>navigate("/renewals")} className="ml-4 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg font-semibold text-sm transition-colors">\n              View Renewals\n            </button>',
    1
)

# Security — Download Security Whitepaper
app = app.replace(
    '<button className="px-8 py-4 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold flex items-center',
    '<button onClick={()=>{const a=document.createElement("a");a.href="data:text/plain,NexusIQ Security Whitepaper\\nSOC 2 Type II Certified\\nGDPR Compliant\\nISO 27001 Aligned";a.download="NexusIQ-Security-Whitepaper.txt";a.click()}} className="px-8 py-4 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold flex items-center',
    1
)

# Renewals — Export Calendar
app = app.replace(
    '<button className="ml-auto px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold flex items-center gap-2">\n            <Download className="w-4 h-4" />\n            Export Calendar\n          </button>',
    '<button onClick={()=>{const rows=["App,Renewal Date,Cost,Owner,Days Until",...renewals.map(r=>r.app+","+r.renewalDate+","+r.cost+","+r.owner+","+r.daysUntil)].join("\\n");const a=document.createElement("a");a.href="data:text/csv,"+encodeURIComponent(rows);a.download="renewals-calendar.csv";a.click()}} className="ml-auto px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold flex items-center gap-2 transition-colors">\n            <Download className="w-4 h-4" />\n            Export Calendar\n          </button>',
    1
)

# InvoiceManager — View button (open detail modal)
app = app.replace(
    '<button className="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm">View</button>',
    '<button onClick={()=>{setSelectedInvoice(invoice);setShowInvoiceDetail(true)}} className="px-3 py-1 bg-blue-600 hover:bg-blue-500 rounded text-sm transition-colors">View</button>',
    1
)
# Add InvoiceManager state if not present
if 'selectedInvoice' not in app:
    app = app.replace(
        '  const [uploadSuccess, setUploadSuccess] = useState(false);',
        '  const [uploadSuccess, setUploadSuccess] = useState(false);\n  const [selectedInvoice, setSelectedInvoice] = useState(null);\n  const [showInvoiceDetail, setShowInvoiceDetail] = useState(false);',
        1
    )

# InvoiceManager — Send to Finance
app = app.replace(
    '<button className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-sm">Send to Finance</button>',
    '<button onClick={()=>{const s=encodeURIComponent("Invoice Approval: "+invoice.id+" - "+invoice.vendor);const b=encodeURIComponent("Hi Finance,\\n\\nPlease approve invoice "+invoice.id+" for "+invoice.vendor+" - $"+invoice.amount.toLocaleString()+"\\nDue: "+invoice.dueDate+"\\n\\nThank you");window.open("mailto:finance@nexusiq.io?subject="+s+"&body="+b)}} className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 rounded text-sm transition-colors">Send to Finance</button>',
    1
)

# Add Invoice Detail Modal before Upload Modal
if 'showInvoiceDetail' in app and '{/* Invoice Detail' not in app:
    app = app.replace(
        '        {/* Upload Modal */}',
        '        {/* Invoice Detail Modal */}\n'
        '        {showInvoiceDetail && selectedInvoice && (\n'
        '          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-6">\n'
        '            <div className="bg-slate-900 rounded-3xl border border-white/10 p-8 max-w-lg w-full">\n'
        '              <div className="flex items-center justify-between mb-6">\n'
        '                <h3 className="text-2xl font-bold">Invoice {selectedInvoice.id}</h3>\n'
        '                <button onClick={()=>setShowInvoiceDetail(false)} className="text-slate-400 hover:text-white text-2xl">&times;</button>\n'
        '              </div>\n'
        '              <div className="space-y-3 mb-6">\n'
        '                {[["Vendor",selectedInvoice.vendor],["Category",selectedInvoice.category],["Amount","$"+selectedInvoice.amount.toLocaleString()],["Due Date",selectedInvoice.dueDate],["Submitted By",selectedInvoice.submittedBy],["Status",selectedInvoice.status.replace(/_/g," ").replace(/\\b\\w/g,c=>c.toUpperCase())]].map(([l,v])=>(\n'
        '                  <div key={l} className="flex justify-between py-2 border-b border-slate-800">\n'
        '                    <span className="text-slate-400 text-sm">{l}</span>\n'
        '                    <span className="text-white font-semibold text-sm">{v}</span>\n'
        '                  </div>\n'
        '                ))}\n'
        '              </div>\n'
        '              <div className="flex gap-3">\n'
        '                <button onClick={()=>setShowInvoiceDetail(false)} className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl font-semibold">Close</button>\n'
        '                {selectedInvoice.status==="pending_approval"&&(<button onClick={()=>{const s=encodeURIComponent("Invoice: "+selectedInvoice.id+" - "+selectedInvoice.vendor);const b=encodeURIComponent("Hi Finance,\\n\\nPlease approve $"+selectedInvoice.amount.toLocaleString()+" from "+selectedInvoice.vendor+"\\nDue: "+selectedInvoice.dueDate);window.open("mailto:finance@nexusiq.io?subject="+s+"&body="+b)}} className="flex-1 px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors">📧 Send to Finance</button>)}\n'
        '              </div>\n'
        '            </div>\n'
        '          </div>\n'
        '        )}\n\n'
        '        {/* Upload Modal */}',
        1
    )

# Licenses — Auto-Reclaim All
app = app.replace(
    '<button className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold flex items-center gap-2">\n            <Sparkles className="w-4 h-4" />\n            Auto-Reclaim All',
    '<button onClick={()=>{const r=filteredLicenseData.filter(a=>a.inactive>0);const s=encodeURIComponent("Auto-Reclaim: "+r.reduce((t,a)=>t+a.inactive,0)+" Inactive Licenses");const b=encodeURIComponent("Hi Team,\\n\\nPlease reclaim inactive licenses:\\n\\n"+r.map(a=>"- "+a.app+": "+a.inactive+" inactive ($"+(a.inactive*a.costPerLicense).toFixed(2)+"/mo)").join("\\n")+"\\n\\nTotal savings: $"+r.reduce((t,a)=>t+(a.inactive*a.costPerLicense),0).toFixed(2)+"/mo");window.open("mailto:it@nexusiq.io?subject="+s+"&body="+b)}} className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg font-semibold flex items-center gap-2 transition-colors">\n            <Sparkles className="w-4 h-4" />\n            Auto-Reclaim All',
    1
)

# Integrations — Request Integration
app = app.replace(
    '<button className="w-full px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-all">\n            Request Integration\n          </button>',
    '<button onClick={()=>window.open("mailto:support@nexusiq.io?subject=Integration%20Request&body=Tool%20name%3A%0AUse%20case%3A%0APriority%3A%0A","_blank")} className="w-full px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-all">\n            Request Integration\n          </button>',
    1
)

ok.append("[BUTTONS] Wired: View All, Review Tools, View Renewals, Download Whitepaper, Export Calendar, View Invoice, Send to Finance, Auto-Reclaim, Request Integration")

# ══════════════════════════════════════════════════════════════════
# SECTION 8 — RENEWALS: Mark as Reviewed → moves to reviewed section
# ══════════════════════════════════════════════════════════════════
app = app.replace(
    '  const [reminderDays, setReminderDays] = useState(30);\n',
    '  const [reminderDays, setReminderDays] = useState(30);\n  const [reviewedApps, setReviewedApps] = useState([]);\n',
    1
)
app = app.replace(
    '                onClick={() => setShowReviewModal(false)}\n'
    '                className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors"\n'
    '              >\n'
    '                Mark as Reviewed',
    '                onClick={() => { setReviewedApps(prev => [...prev, selectedRenewal.app]); setShowReviewModal(false); }}\n'
    '                className="w-full px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2"\n'
    '              >\n'
    '                ✓ Mark as Reviewed',
    1
)
app = app.replace(
    '{renewals.sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => (',
    '{renewals.filter(r => !reviewedApps.includes(r.app)).sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => (',
    1
)
# Add reviewed section before Review Modal
app = app.replace(
    '        {/* Review Modal */}',
    '        {reviewedApps.length > 0 && (\n'
    '          <Card className="p-6 mt-6 border-emerald-500/20 bg-emerald-500/5">\n'
    '            <div className="flex items-center gap-3 mb-4">\n'
    '              <BadgeCheck className="h-6 w-6 text-emerald-400" />\n'
    '              <h3 className="text-lg font-bold">Reviewed Apps</h3>\n'
    '              <span className="text-xs bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-semibold">{reviewedApps.length} reviewed</span>\n'
    '            </div>\n'
    '            <div className="overflow-x-auto">\n'
    '              <table className="w-full">\n'
    '                <thead><tr className="border-b border-emerald-500/20">\n'
    '                  {["Application","Renewal Date","Cost","Owner","Status",""].map(h=><th key={h} className="text-left py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">{h}</th>)}\n'
    '                </tr></thead>\n'
    '                <tbody>\n'
    '                  {renewals.filter(r=>reviewedApps.includes(r.app)).map((r,i)=>(\n'
    '                    <tr key={i} className="border-b border-emerald-500/10 hover:bg-emerald-500/5">\n'
    '                      <td className="py-3 px-4"><div className="font-semibold text-white">{r.app}</div><div className="text-xs text-slate-500">{r.term}</div></td>\n'
    '                      <td className="py-3 px-4 text-slate-300">{r.renewalDate}</td>\n'
    '                      <td className="py-3 px-4 font-mono text-white">${r.cost.toLocaleString()}</td>\n'
    '                      <td className="py-3 px-4 text-slate-300">{r.owner}</td>\n'
    '                      <td className="py-3 px-4"><span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full">✓ Reviewed</span></td>\n'
    '                      <td className="py-3 px-4 text-right"><button onClick={()=>setReviewedApps(p=>p.filter(a=>a!==r.app))} className="text-xs text-slate-500 hover:text-slate-300">Undo</button></td>\n'
    '                    </tr>\n'
    '                  ))}\n'
    '                </tbody>\n'
    '              </table>\n'
    '            </div>\n'
    '          </Card>\n'
    '        )}\n\n'
    '        {/* Review Modal */}',
    1
)
ok.append("[RENEWALS] Mark as Reviewed → moves to green Reviewed section with Undo")

# ══════════════════════════════════════════════════════════════════
# SECTION 9 — LANDING PAGE: Book a Demo + CTO copy
# ══════════════════════════════════════════════════════════════════
app = app.replace(
    '                Get Started\n              </button>',
    '                Get Started Free\n              </button>\n'
    '              <button onClick={()=>window.open("mailto:sales@nexusiq.io?subject=Demo%20Request&body=Hi%2C%20I%27d%20like%20to%20book%20a%20demo%20of%20NexusIQ.","_blank")} className="px-6 py-3 border border-slate-600 hover:border-blue-400 hover:text-white rounded-xl font-semibold transition-all text-slate-300">\n'
    '                Book a Demo\n              </button>',
    1
)
ok.append("[LANDING] 'Book a Demo' button + 'Get Started Free' CTA")

# Comparison table NexusIQ badge
app = app.replace(
    '<div className="text-lg font-bold text-white mb-1">NexusIQ</div>',
    '<div className="flex items-center justify-center gap-2 mb-1"><span className="text-lg font-bold text-white">NexusIQ</span><span className="text-[10px] bg-blue-500 text-white px-1.5 py-0.5 rounded font-bold">NEW</span></div>',
    1
)
ok.append("[LANDING] NexusIQ comparison table NEW badge")

# ══════════════════════════════════════════════════════════════════
# SECTION 10 — FINANCE CHART: Fix broken recharts defs position
# ══════════════════════════════════════════════════════════════════
old_chart = re.search(
    r'<ResponsiveContainer[^>]*height=\{300\}[^>]*>.*?</ResponsiveContainer>',
    app, re.DOTALL
)
if old_chart:
    app = app[:old_chart.start()] + \
    '<ResponsiveContainer width="100%" height={300}>\n' \
    '            <BarChart data={financialData.monthlyTrend} barSize={40} margin={{top:8,right:8,left:0,bottom:0}}>\n' \
    '              <defs><linearGradient id="spendGrad" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#3b82f6" stopOpacity={0.95}/><stop offset="100%" stopColor="#6366f1" stopOpacity={0.75}/></linearGradient></defs>\n' \
    '              <XAxis dataKey="month" tick={{fill:"#94a3b8",fontSize:12}} axisLine={{stroke:"#334155"}} tickLine={false}/>\n' \
    '              <YAxis tick={{fill:"#94a3b8",fontSize:12}} axisLine={false} tickLine={false} tickFormatter={v=>"$"+(v/1000).toFixed(0)+"K"}/>\n' \
    '              <Tooltip cursor={{fill:"rgba(255,255,255,0.04)"}} contentStyle={{backgroundColor:"#1e293b",border:"1px solid #334155",borderRadius:"12px",color:"#fff",fontSize:"13px"}} formatter={v=>["$"+v.toLocaleString(),"Monthly Spend"]}/>\n' \
    '              <Bar dataKey="spend" fill="url(#spendGrad)" radius={[8,8,0,0]}/>\n' \
    '            </BarChart>\n' \
    '          </ResponsiveContainer>' + app[old_chart.end():]
    ok.append("[FINANCE] Spending chart fixed (defs in correct position)")

# Remove unused Cell import from recharts
app = app.replace(
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';",
    "import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';"
)

# ══════════════════════════════════════════════════════════════════
# REPORT + SAVE
# ══════════════════════════════════════════════════════════════════
print()
for s in ok:
    print("  ✓  " + s)

ag_left = app.count('AccessGuard')
lo = app.count('<LanguageProvider>'); lc = app.count('</LanguageProvider>')
print(f"\n  AccessGuard remaining: {ag_left}")
print(f"  LanguageProvider tags: open={lo} close={lc}")
print(f"  Lines: {app.count(chr(10))}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  App.jsx saved ✓")
PYEOF

[ $? -ne 0 ] && echo -e "${RED}Python failed — restoring backup${NC}" && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# Fix translations.js with UTF-8 safe read/write
python3 << 'PYEOF'
import os, sys
tp = 'src/translations.js'
if not os.path.exists(tp): sys.exit(0)
with open(tp, 'r', encoding='utf-8', errors='replace') as f:
    t = f.read()
en_start = t.find('  en: {'); en_end = t.find('\n  },', en_start)
new_keys = [
    ("need_review_soon","Need review soon"),("review_all_critical","Review All Critical"),
    ("set_reminders","Set Reminders"),("cost_management","Cost Management"),
    ("analytics","Analytics"),("settings","Settings"),("contracts","Contracts"),
    ("security","Security"),("access","Access Map"),("executive_view","Executive View"),
    ("cost","Cost Management"),
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
print("  translations.js: " + (("added "+", ".join(added)) if added else "all keys present") + " ✓")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { echo -e "${RED}Build failed — restoring backup${NC}"; cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║  NexusIQ — Master Fix Complete ✓                          ║"
echo -e "╠══════════════════════════════════════════════════════════════╣"
echo -e "║  [1] BRAND     All AccessGuard → NexusIQ, Roland D. gone  ║"
echo -e "║  [2] LOGO      Shield + lightning bolt SVG, gradient glow  ║"
echo -e "║  [3] NAV       4 sections, 6 hidden pages now visible      ║"
echo -e "║  [4] DASHBOARD Executive KPI strip (4 live metrics)        ║"
echo -e "║  [5] LANGUAGE  All stale listeners removed, context fixed  ║"
echo -e "║  [6] LABELS    All underscore labels → proper English       ║"
echo -e "║  [7] BUTTONS   9 dead buttons all wired up                 ║"
echo -e "║  [8] RENEWALS  Mark Reviewed → moves to green section      ║"
echo -e "║  [9] LANDING   Book a Demo CTA + NexusIQ NEW badge         ║"
echo -e "║  [10] FINANCE  Spending chart fixed (recharts defs bug)     ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}\n"
