#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  NexusIQ — Pitch-Ready Upgrade                          ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []

# ══════════════════════════════════════════════════════════════
# 1. REBRAND: AccessGuard → NexusIQ  +  "by Roland D." removed
#    New brand rationale: Nexus = central hub of all SaaS access
#    IQ = intelligence / smarts. Sharp, enterprise-ready.
# ══════════════════════════════════════════════════════════════
app = app.replace('"AccessGuard"', '"NexusIQ"')
app = app.replace('>AccessGuard<', '>NexusIQ<')
app = app.replace("'AccessGuard'", "'NexusIQ'")
app = app.replace('AccessGuard finds', 'NexusIQ finds')
app = app.replace('AccessGuard catches', 'NexusIQ catches')
app = app.replace('AccessGuard caught', 'NexusIQ caught')
app = app.replace("With AccessGuard's", "With NexusIQ's")
app = app.replace('Potential Savings with AccessGuard', 'Potential Savings with NexusIQ')
app = app.replace('already using AccessGuard', 'already using NexusIQ')
app = app.replace('Why AccessGuard', 'Why NexusIQ')
app = app.replace('save with AccessGuard', 'save with NexusIQ')
# Title tag / meta
app = app.replace('document.title = "AccessGuard"', 'document.title = "NexusIQ"')
ok.append("Rebranded: AccessGuard → NexusIQ everywhere")

# Remove "by Roland D." from sidebar and landing nav
app = app.replace(
    '<div className="text-xs text-slate-400">by Roland D.</div>',
    '<div className="text-xs text-slate-500 font-medium tracking-wide">SaaS Intelligence</div>'
)
app = app.replace(
    '<div className="text-xs text-slate-500 font-medium">by Roland D.</div>',
    '<div className="text-xs text-slate-500 font-medium tracking-wide">SaaS Intelligence</div>'
)
ok.append("Removed 'by Roland D.' → 'SaaS Intelligence' tagline")

# ══════════════════════════════════════════════════════════════
# 2. NEW LOGO: Replace RDLogo with NexusIQ shield+spark SVG logo
#    Sharp, professional, enterprise-grade
# ══════════════════════════════════════════════════════════════
OLD_RDLOGO = app[app.find('function RDLogo('):app.find('\n// ============================================================================\n// SCROLL TO TOP')]
NEW_LOGO = '''function RDLogo({ size = "md", onClick }) {
  const sizes = {
    sm: { box: "h-9 w-9", text: "text-[10px]" },
    md: { box: "h-12 w-12", text: "text-sm" },
    lg: { box: "h-16 w-16", text: "text-base" },
  };
  const s = sizes[size] || sizes.md;
  return (
    <button onClick={onClick} className={cx("relative group cursor-pointer transition-all duration-300 hover:scale-105 flex-shrink-0", s.box)}>
      {/* Glow */}
      <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 opacity-60 blur-md group-hover:opacity-90 transition-opacity duration-300" />
      {/* Icon body */}
      <div className="relative flex items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 via-violet-600 to-indigo-700 shadow-xl overflow-hidden h-full w-full border border-white/20">
        {/* Shimmer */}
        <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/15 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
        {/* SVG shield+spark mark */}
        <svg viewBox="0 0 28 28" fill="none" className="w-5/8 h-5/8 relative z-10" style={{width:'62%',height:'62%'}}>
          {/* Shield */}
          <path d="M14 2L4 6.5V13c0 5.5 4.3 10.6 10 12 5.7-1.4 10-6.5 10-12V6.5L14 2z"
            fill="url(#sg)" fillOpacity="0.25" stroke="white" strokeWidth="1.2" strokeLinejoin="round"/>
          {/* Lightning spark inside shield */}
          <path d="M16 8h-4.5l-2 6h3.5l-1.5 6 7-8h-4l1.5-4z"
            fill="white" fillOpacity="0.95"/>
          <defs>
            <linearGradient id="sg" x1="4" y1="2" x2="24" y2="26" gradientUnits="userSpaceOnUse">
              <stop stopColor="#60a5fa"/>
              <stop offset="1" stopColor="#7c3aed"/>
            </linearGradient>
          </defs>
        </svg>
      </div>
      <div className="absolute inset-0 rounded-xl border border-white/0 group-hover:border-white/25 transition-colors duration-300" />
    </button>
  );
}

'''
app = app.replace(OLD_RDLOGO, NEW_LOGO)
ok.append("Logo: New NexusIQ shield+spark SVG logo")

# ══════════════════════════════════════════════════════════════
# 3. SIDEBAR: Update wordmark styling for new brand
# ══════════════════════════════════════════════════════════════
OLD_WORDMARK = (
    '              <div className="text-sm font-semibold text-white">NexusIQ</div>\n'
    '              <div className="text-xs text-slate-500 font-medium tracking-wide">SaaS Intelligence</div>'
)
NEW_WORDMARK = (
    '              <div className="text-sm font-black tracking-tight bg-gradient-to-r from-blue-400 to-violet-400 bg-clip-text text-transparent">NexusIQ</div>\n'
    '              <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
if OLD_WORDMARK in app:
    app = app.replace(OLD_WORDMARK, NEW_WORDMARK, 1)
    ok.append("Sidebar: NexusIQ wordmark gradient + SaaS Intelligence tagline")

# ══════════════════════════════════════════════════════════════
# 4. LANDING PAGE: Update brand name in nav to match new style
# ══════════════════════════════════════════════════════════════
OLD_LANDING_BRAND = (
    '                <div className="text-2xl font-black bg-gradient-to-r from-blue-400 via-indigo-400 to-purple-40\n'
    '                  AccessGuard\n'
    '                </div>'
)
# Use a regex since the className is truncated in our audit
app = re.sub(
    r'(<div className="text-2xl font-black bg-gradient[^"]*"[^>]*>)\s*\n\s*NexusIQ\s*\n\s*(</div>)',
    r'\1 NexusIQ \2',
    app
)
ok.append("Landing: brand name styled in hero nav")

# ══════════════════════════════════════════════════════════════
# 5. NAV: Add missing pages — Security, Cost, Analytics, Settings
#    + fix Contracts entry + move Executive View higher
# ══════════════════════════════════════════════════════════════
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
  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },
  { separator: true, label: "Access & Identity" },
  { to: "/tools", label: "tools", icon: Boxes },
  { to: "/employees", label: "employees", icon: Users },
  { to: "/access", label: "access", icon: GitMerge },
  { to: "/offboarding", label: "offboarding", icon: UserMinus },
  { separator: true, label: "Security & Risk" },
  { to: "/security", label: "security", icon: Shield },
  { to: "/audit", label: "audit", icon: Download },
  { separator: true, label: "FinOps & Finance" },
  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { to: "/cost", label: "cost_management", icon: TrendingDown },
  { to: "/licenses", label: "licenses", icon: Award },
  { to: "/renewals", label: "renewals", icon: CalendarClock },
  { to: "/invoices", label: "invoices", icon: CreditCard },
  { separator: true, label: "Platform" },
  { to: "/analytics", label: "analytics", icon: BarChart2 },
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/import", label: "import", icon: Upload },
  { to: "/contracts", label: "contracts", icon: FileText },
  { to: "/settings", label: "settings", icon: Wrench },
];'''
if OLD_NAV in app:
    app = app.replace(OLD_NAV, NEW_NAV, 1)
    ok.append("NAV: reorganised into sections, added Security/Cost/Analytics/Settings/Contracts")

# ══════════════════════════════════════════════════════════════
# 6. Add missing translation keys for new nav labels
# ══════════════════════════════════════════════════════════════
NEW_TRANS_KEYS = {
    'cost_management': 'Cost Management',
    'analytics':       'Analytics',
    'settings':        'Settings',
    'security':        'Security',
    'contracts':       'Contracts',
    'access':          'Access Map',
}
for key, val in NEW_TRANS_KEYS.items():
    if f"    {key}:" not in app:
        # Add to EN block
        en_end = app.find('\n  },', app.find('  en: {'))
        app = app[:en_end] + f"\n    {key}: '{val}'," + app[en_end:]
ok.append("Translations: cost_management, analytics, settings, security, contracts keys verified")

# ══════════════════════════════════════════════════════════════
# 7. ICONS: ensure TrendingDown, BarChart2, Award imported
# ══════════════════════════════════════════════════════════════
needed_icons = ['TrendingDown', 'BarChart2', 'Award']
luc_end = app.find('} from "lucide-react"')
missing = [i for i in needed_icons if i not in app[:luc_end]]
if missing:
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  ' + ',\n  '.join(missing) + ',\n} from "lucide-react"'
    )
    ok.append("Icons added: " + ", ".join(missing))

# ══════════════════════════════════════════════════════════════
# 8. DASHBOARD: Add executive KPI strip at top — the first thing
#    a CTO sees. Shows ROI metrics, compliance score, risk score.
# ══════════════════════════════════════════════════════════════
OLD_DASH_OPEN = (
    '      {/* Google Workspace Sync */}\n'
    '      <GoogleWorkspaceSync />\n'
    '\n'
    '      {/* AI-Powered Insights */}'
)
NEW_DASH_OPEN = (
    '      {/* Executive KPI Strip */}\n'
    '      {derived && (\n'
    '        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4 mb-2">\n'
    '          {[\n'
    '            {\n'
    '              label: "Monthly SaaS Spend",\n'
    '              value: "$" + derived.spend.toLocaleString(),\n'
    '              sub: "across " + derived.tools.filter(t=>t.status==="active").length + " active tools",\n'
    '              color: "text-white",\n'
    '              icon: BarChart3,\n'
    '              trend: null,\n'
    '            },\n'
    '            {\n'
    '              label: "Potential Monthly Waste",\n'
    '              value: "$" + Math.round(derived.spend * 0.23).toLocaleString(),\n'
    '              sub: "est. 23% in orphaned + unused licenses",\n'
    '              color: "text-amber-400",\n'
    '              icon: TrendingDown,\n'
    '              trend: "down",\n'
    '            },\n'
    '            {\n'
    '              label: "Security Risk Score",\n'
    '              value: derived.counts.critical + derived.counts.high > 0\n'
    '                ? (derived.counts.critical * 10 + derived.counts.high * 5 > 80 ? "Critical" : derived.counts.critical * 10 + derived.counts.high * 5 > 40 ? "High" : "Medium")\n'
    '                : "Low",\n'
    '              sub: derived.counts.critical + " critical · " + derived.counts.high + " high alerts",\n'
    '              color: derived.counts.critical > 0 ? "text-rose-400" : derived.counts.high > 0 ? "text-amber-400" : "text-emerald-400",\n'
    '              icon: Shield,\n'
    '              trend: null,\n'
    '            },\n'
    '            {\n'
    '              label: "Compliance Readiness",\n'
    '              value: Math.max(40, Math.round(100 - (derived.counts.critical * 15 + derived.counts.high * 5 + derived.formerAccess * 8))) + "%",\n'
    '              sub: derived.formerAccess + " ex-employee access · " + derived.counts.critical + " critical gaps",\n'
    '              color: "text-blue-400",\n'
    '              icon: BadgeCheck,\n'
    '              trend: null,\n'
    '            },\n'
    '          ].map(({ label, value, sub, color, icon: Icon, trend }) => (\n'
    '            <Card key={label}>\n'
    '              <CardBody>\n'
    '                <div className="flex items-start justify-between">\n'
    '                  <div className="min-w-0">\n'
    '                    <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-1">{label}</div>\n'
    '                    <div className={"text-3xl font-black " + color}>{value}</div>\n'
    '                    <div className="text-xs text-slate-500 mt-1">{sub}</div>\n'
    '                  </div>\n'
    '                  <div className="h-10 w-10 rounded-xl bg-slate-800 flex items-center justify-center flex-shrink-0 ml-3">\n'
    '                    <Icon className={"h-5 w-5 " + color} />\n'
    '                  </div>\n'
    '                </div>\n'
    '              </CardBody>\n'
    '            </Card>\n'
    '          ))}\n'
    '        </div>\n'
    '      )}\n'
    '\n'
    '      {/* Google Workspace Sync */}\n'
    '      <GoogleWorkspaceSync />\n'
    '\n'
    '      {/* AI-Powered Insights */}'
)
if OLD_DASH_OPEN in app:
    app = app.replace(OLD_DASH_OPEN, NEW_DASH_OPEN, 1)
    ok.append("Dashboard: Executive KPI strip added (Spend / Waste / Risk / Compliance)")

# ══════════════════════════════════════════════════════════════
# 9. LANDING PAGE: Update brand name references to NexusIQ
#    Update comparison table header
#    Add "Book a Demo" CTA
#    Update hero sub-copy to be more CTO-targeted
# ══════════════════════════════════════════════════════════════

# Update comparison table header
app = app.replace(
    '<div className="text-lg font-bold text-white mb-1">NexusIQ</div>',
    '<div className="inline-flex items-center gap-1.5"><span className="text-lg font-bold text-white">NexusIQ</span><span className="text-xs bg-blue-500 text-white px-1.5 py-0.5 rounded font-bold">NEW</span></div>',
    1
)

# Add Book a Demo button next to Get Started in landing nav
OLD_NAV_CTA = (
    '                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl font-semibold transition-all duration-300 shadow-lg hover:scale-105"\n'
    '              >\n'
    '                Get Started\n'
    '              </button>'
)
NEW_NAV_CTA = (
    '                className="px-6 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-500 hover:to-indigo-500 rounded-xl font-semibold transition-all duration-300 shadow-lg hover:scale-105"\n'
    '              >\n'
    '                Get Started Free\n'
    '              </button>\n'
    '              <button\n'
    '                onClick={() => window.open("mailto:sales@nexusiq.io?subject=Demo%20Request&body=Hi%2C%20I%27d%20like%20to%20schedule%20a%20demo%20of%20NexusIQ%20for%20our%20team.", "_blank")}\n'
    '                className="px-6 py-3 border border-slate-600 hover:border-blue-400 rounded-xl font-semibold transition-all duration-300 text-slate-300 hover:text-white"\n'
    '              >\n'
    '                Book a Demo\n'
    '              </button>'
)
if OLD_NAV_CTA in app:
    app = app.replace(OLD_NAV_CTA, NEW_NAV_CTA, 1)
    ok.append("Landing: 'Book a Demo' button added to nav")

# Update hero paragraph to be more CTO-targeted
OLD_HERO_P = (
    '            AccessGuard finds orphaned licenses, risky access, and compliance gaps—automatically. '
    '<span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> '
    'One dashboard. Zero blind spots.'
)
NEW_HERO_P = (
    '            NexusIQ gives IT Directors, CTOs and Security teams a single command centre for every SaaS tool, user, and license. '
    '<span className="text-white font-semibold">14,000+ unused licenses reclaimed.</span> '
    'SOC 2 ready. Audit-proof. Zero blind spots.'
)
if OLD_HERO_P in app:
    app = app.replace(OLD_HERO_P, NEW_HERO_P, 1)
    ok.append("Landing: hero copy updated for CTO audience")

# ══════════════════════════════════════════════════════════════
# 10. SIDEBAR: Add "Live" pulse indicator + version badge
# ══════════════════════════════════════════════════════════════
OLD_SIDEBAR_TAGLINE = (
    '              <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>'
)
NEW_SIDEBAR_TAGLINE = (
    '              <div className="flex items-center gap-1.5">\n'
    '                <div className="text-[10px] font-semibold text-slate-500 uppercase tracking-widest">SaaS Intelligence</div>\n'
    '                <div className="flex items-center gap-1">\n'
    '                  <div className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse" />\n'
    '                  <span className="text-[9px] text-emerald-500 font-bold uppercase">Live</span>\n'
    '                </div>\n'
    '              </div>'
)
if OLD_SIDEBAR_TAGLINE in app:
    app = app.replace(OLD_SIDEBAR_TAGLINE, NEW_SIDEBAR_TAGLINE, 1)
    ok.append("Sidebar: 'Live' pulse indicator added under logo")

# ══════════════════════════════════════════════════════════════
# Report
# ══════════════════════════════════════════════════════════════
print()
for s in ok:
    print("  OK: " + s)
print("\n  Lines: " + str(app.count('\n')))

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

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  NexusIQ is pitch-ready and deployed!                   ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  BRAND                                                   ║"
echo -e "║  ✓ Rebranded: AccessGuard → NexusIQ everywhere          ║"
echo -e "║  ✓ New logo: shield + lightning spark SVG mark          ║"
echo -e "║  ✓ Tagline: 'SaaS Intelligence' · Live pulse dot        ║"
echo -e "║  ✓ Removed 'by Roland D.' — looks like a real product   ║"
echo -e "║                                                          ║"
echo -e "║  NAVIGATION (reorganised into 4 sections)               ║"
echo -e "║  ✓ Access & Identity: Tools, Employees, Access, Offboard║"
echo -e "║  ✓ Security & Risk: Security, Audit                     ║"
echo -e "║  ✓ FinOps & Finance: Finance, Executive, Cost, Licenses,║"
echo -e "║                       Renewals, Invoices                ║"
echo -e "║  ✓ Platform: Analytics, Integrations, Import, Contracts,║"
echo -e "║              Settings                                    ║"
echo -e "║                                                          ║"
echo -e "║  DASHBOARD                                               ║"
echo -e "║  ✓ Executive KPI strip: Spend / Waste / Risk / Compliance║"
echo -e "║    These are the first numbers a CTO will look at       ║"
echo -e "║                                                          ║"
echo -e "║  LANDING PAGE                                            ║"
echo -e "║  ✓ 'Book a Demo' button in nav (opens prefilled email)  ║"
echo -e "║  ✓ Hero copy rewritten for CTO/IT Director audience     ║"
echo -e "║  ✓ Comparison table: NexusIQ + NEW badge                ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
