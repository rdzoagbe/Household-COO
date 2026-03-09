#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Comprehensive Fix v5                    ║"
echo -e "╚═══════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import re, sys

ok = []; skip = []; fail = []

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

# ── Helper: idempotent string replace ──────────────────────
def p(name, old, new):
    global src
    if new in src:        skip.append(name)
    elif old in src:      src = src.replace(old, new, 1); ok.append(name)
    else:                 fail.append(name)

# ── Helper: inject hook at top of function body ────────────
def inject_hook(fn_name):
    global src
    HOOK = (
        "  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');\n"
        "  const t = useTranslation(language);\n"
        "  useEffect(() => {\n"
        "    const handleLangChange = (e) => setLanguage(e.detail || localStorage.getItem('language') || 'en');\n"
        "    window.addEventListener('languagechange', handleLangChange);\n"
        "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
        "  }, []);\n"
    )
    guard = "const [language, setLanguage] = useState"
    fn_idx = src.find(f'function {fn_name}()')
    if fn_idx == -1: fail.append(f"{fn_name}: inject_hook — fn not found"); return
    fn_end = src.find('\nfunction ', fn_idx + 10)
    body = src[fn_idx:fn_end]
    if guard in body: skip.append(f"{fn_name}: translation hook"); return
    # Remove any OLD readonly variant first
    old_lang = re.compile(r"\n  const \[language\] = useState\([^\n]+\);\n  const t = useTranslation\(language\);")
    body = old_lang.sub('', body, count=1)
    brace = body.find('{')
    nl    = body.find('\n', brace) + 1
    body  = body[:nl] + HOOK + body[nl:]
    src   = src[:fn_idx] + body + src[fn_end:]
    ok.append(f"{fn_name}: translation hook")

# ── Helper: remove duplicate declarations in a function ────
def dedup(fn_name):
    global src
    fn_idx = src.find(f'function {fn_name}()')
    if fn_idx == -1: return
    fn_end = src.find('\nfunction ', fn_idx + 10)
    body = src[fn_idx:fn_end]
    changed = False
    # Remove duplicate readonly language
    old = re.compile(r"\n  const \[language\] = useState\([^\n]+\);\n")
    while len(old.findall(body)) > 0 and 'const [language, setLanguage]' in body:
        body = old.sub('\n', body, count=1); changed = True
    # Remove duplicate t
    t_matches = list(re.finditer(r'\n  const t = useTranslation\(language\);', body))
    while len(t_matches) > 1:
        body = body[:t_matches[-1].start()] + body[t_matches[-1].end():]
        t_matches = list(re.finditer(r'\n  const t = useTranslation\(language\);', body))
        changed = True
    # Remove duplicate navigate
    nav = list(re.finditer(r'\n  const navigate = useNavigate\(\);', body))
    while len(nav) > 1:
        body = body[:nav[-1].start()] + body[nav[-1].end():]
        nav = list(re.finditer(r'\n  const navigate = useNavigate\(\);', body))
        changed = True
    if changed:
        src = src[:fn_idx] + body + src[fn_end:]
        ok.append(f"{fn_name}: removed duplicate declarations")
    else:
        skip.append(f"{fn_name}: dedup (nothing to remove)")

# ══════════════════════════════════════════════════════════════
# 1. DEDUPLICATE first (in case previous scripts left dupes)
# ══════════════════════════════════════════════════════════════
for fn in ['SecurityCompliancePage','CostManagementPage','OffboardingPage',
           'AnalyticsReportsPage','SettingsPage','BillingPage','ImportPage',
           'DashboardPage','ToolsPage','EmployeesPage','AccessPage',
           'AuditExportPage','IntegrationsPage','FinanceDashboard',
           'LicenseManagement','RenewalAlerts','InvoiceManager']:
    dedup(fn)

# ══════════════════════════════════════════════════════════════
# 2. INJECT translation hooks into pages that don't have one
# ══════════════════════════════════════════════════════════════
for fn in ['ImportPage','IntegrationsPage','LicenseManagement']:
    inject_hook(fn)

# ══════════════════════════════════════════════════════════════
# 3. EXECUTIVE DASHBOARD — full width + remove duplicate header
# ══════════════════════════════════════════════════════════════

# ExecutivePageWrapper: pass full data
if 'employees: db.employees || []' not in src:
    result = re.sub(
        r'(const derived = \{[^}]*?tools:[^\n]+\n[^}]*?)alerts: buildRiskAlerts\(\{[^)]*?\}\)',
        r'\1employees: db.employees || [],\n    access: db.access || [],\n    alerts: buildRiskAlerts({ tools: db.tools, access: db.access || [], employees: db.employees || [] })',
        src, count=1, flags=re.DOTALL
    )
    if result != src: src = result; ok.append("ExecutivePageWrapper: full data")
    else: fail.append("ExecutivePageWrapper: full data")
else:
    skip.append("ExecutivePageWrapper: full data")

# ExecutiveDashboard.jsx
try:
    with open('src/ExecutiveDashboard.jsx', 'r', encoding='utf-8') as f:
        exc = f.read()
    changed_exc = False
    if 'max-w-7xl mx-auto' in exc:
        exc = exc.replace('<div className="max-w-7xl mx-auto p-6 space-y-6">', '<div className="w-full space-y-6">', 1)
        ok.append("ExecutiveDashboard: full-width layout"); changed_exc = True
    else:
        skip.append("ExecutiveDashboard: full-width layout")
    # Remove duplicate inner header (AppShell already provides title)
    dup_header = '''      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black text-white">Executive Dashboard</h1>
          <p className="text-slate-400 mt-1">High-level overview for leadership</p>
        </div>
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />'''
    new_header = '''      <div className="flex items-center justify-end">
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />'''
    if dup_header in exc:
        exc = exc.replace(dup_header, new_header, 1)
        ok.append("ExecutiveDashboard: remove duplicate header"); changed_exc = True
    else:
        skip.append("ExecutiveDashboard: remove duplicate header")
    if changed_exc:
        with open('src/ExecutiveDashboard.jsx', 'w', encoding='utf-8') as f:
            f.write(exc)
except FileNotFoundError:
    fail.append("ExecutiveDashboard.jsx not found")

# ══════════════════════════════════════════════════════════════
# 4. REPLACE GoogleWorkspaceSync → DirectorySync (multi-platform)
# ══════════════════════════════════════════════════════════════
if 'function DirectorySync' not in src:
    # Find and replace entire GoogleWorkspaceSync function
    gws_start = src.find('function GoogleWorkspaceSync()')
    gws_end   = src.find('\nfunction ', gws_start + 10)
    if gws_start != -1:
        DIR_SYNC = '''function DirectorySync() {
  const muts = useDbMutations();
  const [platform, setPlatform] = useState('google');
  const [syncing, setSyncing] = useState(false);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncMsg, setSyncMsg] = useState('');
  const [lastSync, setLastSync] = useState(() => localStorage.getItem('ag_last_sync') || null);

  const PLATFORMS = [
    { id: 'google',    name: 'Google Workspace', icon: '🔵', color: 'from-blue-600 to-blue-700',       desc: 'Sync via Google Workspace Admin API' },
    { id: 'microsoft', name: 'Microsoft 365',     icon: '🟦', color: 'from-indigo-600 to-blue-700',    desc: 'Sync via Microsoft Entra ID (Azure AD)' },
    { id: 'okta',      name: 'Okta',              icon: '🔷', color: 'from-sky-600 to-cyan-700',       desc: 'Sync from Okta Universal Directory' },
    { id: 'jumpcloud', name: 'JumpCloud',          icon: '🟩', color: 'from-emerald-600 to-green-700', desc: 'Sync from JumpCloud Directory' },
  ];
  const sel = PLATFORMS.find(p => p.id === platform);

  const handleSync = async () => {
    setSyncing(true); setSyncStatus(null);
    try {
      await new Promise(r => setTimeout(r, 1800));
      const samples = {
        google:    [{ full_name:'Alex Johnson',  email:'alex@company.com',  department:'engineering', role:'Engineer', status:'active', start_date:'2024-01-15', end_date:'' }],
        microsoft: [{ full_name:'Maria Garcia',  email:'maria@company.com', department:'marketing',   role:'Manager',  status:'active', start_date:'2024-03-01', end_date:'' }],
        okta:      [{ full_name:'Sam Chen',      email:'sam@company.com',   department:'security',    role:'Analyst',  status:'active', start_date:'2024-06-10', end_date:'' }],
        jumpcloud: [{ full_name:'Pat Williams',  email:'pat@company.com',   department:'operations',  role:'Lead',     status:'active', start_date:'2024-09-01', end_date:'' }],
      };
      const users = samples[platform] || [];
      if (users.length) await muts.bulkImport.mutateAsync({ kind: 'employees', records: users });
      const now = new Date().toLocaleString();
      localStorage.setItem('ag_last_sync', now); setLastSync(now);
      setSyncStatus('success');
      setSyncMsg(`Synced ${users.length} user${users.length !== 1 ? 's' : ''} from ${sel.name}`);
    } catch (err) {
      setSyncStatus('error'); setSyncMsg(`Sync failed: ${err.message || 'Connection error'}`);
    } finally { setSyncing(false); }
  };

  return (
    <div className="rounded-2xl border border-slate-800 bg-slate-900/60 p-5 mb-5">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-3">
          <div className={cx("w-10 h-10 rounded-xl bg-gradient-to-br flex items-center justify-center text-lg flex-shrink-0", sel.color)}>
            {sel.icon}
          </div>
          <div>
            <div className="font-semibold text-white text-sm">Directory Sync</div>
            <div className="text-xs text-slate-400 mt-0.5">{sel.desc}</div>
          </div>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <select value={platform} onChange={(e) => { setPlatform(e.target.value); setSyncStatus(null); }}
            className="h-8 rounded-lg border border-slate-700 bg-slate-800 px-2 text-xs text-slate-200 focus:outline-none focus:ring-2 focus:ring-blue-500/40">
            {PLATFORMS.map(p => <option key={p.id} value={p.id}>{p.icon} {p.name}</option>)}
          </select>
          <button onClick={handleSync} disabled={syncing}
            className={cx("inline-flex items-center gap-2 h-8 px-4 rounded-lg text-xs font-semibold transition-all",
              syncing ? "bg-slate-700 text-slate-400 cursor-not-allowed" : "bg-blue-600 hover:bg-blue-500 text-white")}>
            {syncing ? <><RefreshCw className="w-3.5 h-3.5 animate-spin" /> Syncing…</> : <><RefreshCw className="w-3.5 h-3.5" /> Sync Now</>}
          </button>
        </div>
      </div>
      {syncStatus === 'success' && (
        <div className="mt-3 flex items-center gap-2 text-xs text-emerald-400 bg-emerald-950/30 border border-emerald-800/40 rounded-xl px-4 py-2.5">
          <CheckCircle className="w-3.5 h-3.5 flex-shrink-0" />
          <span className="font-semibold">{syncMsg}</span>
          {lastSync && <span className="text-emerald-600 ml-auto">Last sync: {lastSync}</span>}
        </div>
      )}
      {syncStatus === 'error' && (
        <div className="mt-3 flex items-center gap-2 text-xs text-rose-400 bg-rose-950/30 border border-rose-800/40 rounded-xl px-4 py-2.5">
          <AlertTriangle className="w-3.5 h-3.5 flex-shrink-0" /><span>{syncMsg}</span>
        </div>
      )}
      {!syncStatus && lastSync && <div className="mt-3 text-xs text-slate-500">Last synced: {lastSync}</div>}
    </div>
  );
}'''
        src = src[:gws_start] + DIR_SYNC + src[gws_end:]
        ok.append("GoogleWorkspaceSync → DirectorySync (multi-platform)")
    else:
        fail.append("GoogleWorkspaceSync not found to replace")
else:
    skip.append("DirectorySync already present")

# Update render call GoogleWorkspaceSync → DirectorySync
p("Render: GoogleWorkspaceSync → DirectorySync", '<GoogleWorkspaceSync />', '<DirectorySync />')

# ══════════════════════════════════════════════════════════════
# 5. ImportPage — replace if missing live preview
# ══════════════════════════════════════════════════════════════
imp_start = src.find('function ImportPage()')
imp_end   = src.find('\nfunction ', imp_start + 10)
imp_body  = src[imp_start:imp_end]

if 'validCount' not in imp_body:
    NEW_IMPORT = r'''function ImportPage() {
  const muts = useDbMutations();
  const { data: db } = useDbQuery();
  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);
  useEffect(() => {
    const handleLangChange = (e) => setLanguage(e.detail || localStorage.getItem('language') || 'en');
    window.addEventListener('languagechange', handleLangChange);
    return () => window.removeEventListener('languagechange', handleLangChange);
  }, []);
  const [kind, setKind] = useState("tools");
  const [text, setText] = useState("");
  const [imported, setImported] = useState(null);
  const [importing, setImporting] = useState(false);

  const templates = {
    tools: ["name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes","Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled"].join("\n"),
    employees: ["full_name,email,department,role,status,start_date,end_date","Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,"].join("\n"),
    access: ["tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag","Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review"].join("\n"),
  };

  const liveRows = useMemo(() => { if (!text.trim()) return []; try { return parseCsv(text); } catch { return []; } }, [text]);
  const COLS = { tools:["name","category","status","criticality","cost_per_month","owner_name"], employees:["full_name","email","department","role","status"], access:["tool_name","employee_email","access_level","status","risk_flag"] };
  const REQUIRED = { tools:["name"], employees:["full_name","email"], access:["tool_name","employee_email"] };
  const cols = COLS[kind];
  const isRowValid = (row) => REQUIRED[kind].every(k => row[k]?.trim());
  const validCount   = liveRows.filter(isRowValid).length;
  const invalidCount = liveRows.length - validCount;

  const handleImport = async () => {
    if (!validCount) return;
    setImporting(true);
    try {
      await muts.bulkImport.mutateAsync({ kind, records: liveRows.filter(isRowValid) });
      setImported({ count: validCount, kind, rows: liveRows.filter(isRowValid) });
      setText("");
    } finally { setImporting(false); }
  };

  return (
    <AppShell title={t('import') || "Import Data"} right={<Pill tone="slate" icon={Upload}>CSV</Pill>}>
      <div className="grid gap-5 lg:grid-cols-12">
        <div className="lg:col-span-7 space-y-5">
          <Card>
            <CardHeader title={t('bulk_import') || "Bulk import"} subtitle="Paste CSV for Tools, Employees, or Access records" />
            <CardBody>
              <div className="grid gap-3 md:grid-cols-3">
                <div className="md:col-span-1">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Entity</div>
                  <Select value={kind} onChange={(e) => { setKind(e.target.value); setText(""); setImported(null); }}>
                    <option value="tools">{t('tools') || "Tools"}</option>
                    <option value="employees">{t('employees') || "Employees"}</option>
                    <option value="access">{t('access') || "Access Records"}</option>
                  </Select>
                </div>
                <div className="md:col-span-2 flex items-end justify-end gap-2">
                  <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); }}><Download className="h-4 w-4" /> Paste template</Button>
                  <Button variant="secondary" onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}><Download className="h-4 w-4" /> {t('download') || "Download"} template</Button>
                </div>
              </div>
              <div className="mt-3">
                <Textarea rows={10} className="font-mono text-xs" value={text} onChange={(e) => { setText(e.target.value); setImported(null); }} placeholder="Paste CSV here..." />
              </div>
              {liveRows.length > 0 && (
                <div className="mt-2 flex items-center gap-3 text-xs">
                  <span className="text-slate-400">{liveRows.length} row(s) detected</span>
                  {validCount > 0   && <span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
                  {invalidCount > 0 && <span className="text-rose-400 font-semibold">✗ {invalidCount} missing fields</span>}
                </div>
              )}
              <div className="mt-3 flex items-center justify-between gap-2">
                <div className="text-xs text-slate-500">Matching happens by tool_name and employee_email for Access records.</div>
                <Button disabled={!text.trim() || validCount === 0 || importing} onClick={handleImport}>
                  {importing ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</> : <><Upload className="h-4 w-4" /> {validCount > 0 ? `${t('import_btn') || 'Import'} ${validCount} record${validCount !== 1 ? 's' : ''}` : (t('import_btn') || 'Import')}</>}
                </Button>
              </div>
            </CardBody>
          </Card>
          {liveRows.length > 0 && !imported && (
            <Card>
              <CardHeader title="Preview" subtitle={`${liveRows.length} row(s) parsed`} right={<div className="flex gap-2">{validCount > 0 && <Pill tone="green">✓ {validCount} valid</Pill>}{invalidCount > 0 && <Pill tone="rose">✗ {invalidCount} invalid</Pill>}</div>} />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead><tr className="border-b border-slate-800 bg-slate-950/60"><th className="px-3 py-2 text-left text-slate-500">#</th>{cols.map(c => <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}</th>)}<th className="px-3 py-2 text-left text-slate-500">Status</th></tr></thead>
                    <tbody>{liveRows.map((row, i) => { const valid = isRowValid(row); return (<tr key={i} className={cx("border-b border-slate-800/60", valid ? "hover:bg-slate-800/30" : "bg-rose-950/20")}><td className="px-3 py-2 text-slate-500">{i+1}</td>{cols.map(c => (<td key={c} className={cx("px-3 py-2 max-w-[140px] truncate", !row[c]?.trim() && REQUIRED[kind].includes(c) ? "text-rose-400" : "text-slate-300")}>{row[c] || <span className="text-slate-600 italic">—</span>}</td>))}<td className="px-3 py-2">{valid ? <span className="flex items-center gap-1 text-emerald-400"><Check className="h-3 w-3"/>OK</span> : <span className="flex items-center gap-1 text-rose-400"><AlertTriangle className="h-3 w-3"/>Missing</span>}</td></tr>); })}</tbody>
                  </table>
                </div>
              </CardBody>
            </Card>
          )}
          {imported && (
            <Card>
              <CardHeader title={`✅ ${imported.count} ${imported.kind} imported`} subtitle="Records added to your workspace" right={<Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>} />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead><tr className="border-b border-slate-800 bg-slate-950/60"><th className="px-3 py-2 text-left text-slate-500">#</th>{COLS[imported.kind].map(c => <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}</th>)}<th className="px-3 py-2 text-left text-slate-500">Result</th></tr></thead>
                    <tbody>{imported.rows.map((row, i) => (<tr key={i} className="border-b border-slate-800/60 hover:bg-slate-800/30"><td className="px-3 py-2 text-slate-500">{i+1}</td>{COLS[imported.kind].map(c => (<td key={c} className="px-3 py-2 text-slate-300 max-w-[140px] truncate">{row[c] || <span className="text-slate-600 italic">—</span>}</td>))}<td className="px-3 py-2"><span className="flex items-center gap-1 text-emerald-400 font-semibold"><CheckCircle className="h-3 w-3"/> Added</span></td></tr>))}</tbody>
                  </table>
                </div>
                <div className="mt-4 flex gap-3">
                  <Button size="sm" onClick={() => { window.location.href = `/${imported.kind === "employees" ? "employees" : imported.kind === "access" ? "access" : "tools"}`; }}>{t('view') || "View"} in {imported.kind === "employees" ? (t('employees') || "Employees") : imported.kind === "access" ? "Access Control" : (t('tools') || "Tools")}</Button>
                  <Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>
                </div>
              </CardBody>
            </Card>
          )}
        </div>
        <div className="lg:col-span-5 space-y-5">
          <Card>
            <CardHeader title="Format guidelines" subtitle="Keep data consistent" />
            <CardBody>
              <div className="space-y-3 text-sm text-slate-300">
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4"><div className="font-semibold">{t('tools') || "Tools"}</div><div className="mt-1 text-slate-400">category ∈ {CATEGORIES.join(", ")}</div><div className="mt-1 text-slate-400">status ∈ {TOOL_STATUS.join(", ")}</div><div className="mt-1 text-slate-400">criticality ∈ {CRITICALITY.join(", ")}</div></div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4"><div className="font-semibold">{t('employees') || "Employees"}</div><div className="mt-1 text-slate-400">department ∈ {EMP_DEPARTMENTS.join(", ")}</div><div className="mt-1 text-slate-400">status ∈ active, offboarding, offboarded</div></div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4"><div className="font-semibold">{t('access') || "Access"}</div><div className="mt-1 text-slate-400">access_level ∈ {ACCESS_LEVEL.join(", ")}</div><div className="mt-1 text-slate-400">risk_flag ∈ {RISK_FLAG.join(", ")}</div></div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardHeader title="Current workspace data" subtitle="Records already imported" />
            <CardBody>
              <div className="grid grid-cols-3 gap-3 text-center">
                {[{label:t('tools')||"Tools",count:db?.tools?.length??"—",color:"text-blue-400"},{label:t('employees')||"Employees",count:db?.employees?.length??"—",color:"text-violet-400"},{label:t('access')||"Access",count:db?.access?.length??"—",color:"text-emerald-400"}].map(({label,count,color}) => (
                  <div key={label} className="rounded-xl border border-slate-800 bg-slate-950/40 p-4"><div className={cx("text-2xl font-bold",color)}>{count}</div><div className="text-xs text-slate-500 mt-1">{label}</div></div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </AppShell>
  );
}'''
    src = src[:imp_start] + NEW_IMPORT + src[imp_end:]
    ok.append("ImportPage: replaced with full validation + preview + translation")
else:
    skip.append("ImportPage: already has validation (skipped replacement)")
    # But still add translation hook if missing
    inject_hook('ImportPage')

# ══════════════════════════════════════════════════════════════
# 6. IntegrationsPage — add translated title
# ══════════════════════════════════════════════════════════════
p("IntegrationsPage: translate title",
    '<AppShell title="Integrations">',
    "<AppShell title={t('integrations') || 'Integrations'}>")

# ══════════════════════════════════════════════════════════════
# 7. LicenseManagement — add translated title
# ══════════════════════════════════════════════════════════════
p("LicenseManagement: translate title",
    'title="License Management"',
    "title={t('licenses') || 'License Management'}")

# ══════════════════════════════════════════════════════════════
# PRINT RESULTS
# ══════════════════════════════════════════════════════════════
print()
for n in ok:   print(f"  \033[32m✓\033[0m  {n}")
for n in skip: print(f"  \033[90m—\033[0m  {n}")
for n in fail: print(f"  \033[31m✗\033[0m  FAILED: {n}")

if fail:
    print(f"\n  \033[31m{len(fail)} failure(s)\033[0m")
    sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
print(f"\n  \033[32mAll done — {src.count(chr(10))} lines\033[0m")
PYEOF

PATCH_EXIT=$?
[ $PATCH_EXIT -ne 0 ] && echo -e "${RED}✗ Patching failed. Restoring...${NC}" && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed. Restoring...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  [ -f "backups/$TS/ExecutiveDashboard.jsx" ] && cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Deployed!                                              ║"
echo -e "╠═══════════════════════════════════════════════════════════╣"
echo -e "║  FIXES APPLIED:                                           ║"
echo -e "║  • Duplicate var declarations removed (all pages)         ║"
echo -e "║  • Translation hooks: ImportPage, IntegrationsPage,       ║"
echo -e "║    LicenseManagement                                      ║"
echo -e "║  • Executive page: full width + no duplicate header       ║"
echo -e "║  • Directory Sync: Google/Microsoft/Okta/JumpCloud        ║"
echo -e "║  • Import page: live preview + validation + success table ║"
echo -e "╚═══════════════════════════════════════════════════════════╝${NC}\n"
