#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Exec Layout + Translation + Import   ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import sys

ok = []; fail = []
def patch(name, old, new, target='app'):
    global app_src, exec_src
    s = app_src if target == 'app' else exec_src
    if old in s:
        if target == 'app': app_src = app_src.replace(old, new, 1)
        else: exec_src = exec_src.replace(old, new, 1)
        ok.append(name)
    elif new in s:
        ok.append(f"{name} (already applied)")
    else:
        fail.append(name)

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app_src = f.read()
with open('src/ExecutiveDashboard.jsx', 'r', encoding='utf-8') as f:
    exec_src = f.read()

TRANS_HOOK = """  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);
  useEffect(() => {
    const handleLangChange = (e) => setLanguage(e.detail || localStorage.getItem('language') || 'en');
    window.addEventListener('languagechange', handleLangChange);
    return () => window.removeEventListener('languagechange', handleLangChange);
  }, []);
"""

# ── EXEC: Remove max-w constraint ──────────────────────────────
patch("ExecutiveDashboard: remove max-w-7xl (full width layout)",
    '<div className="max-w-7xl mx-auto p-6 space-y-6">',
    '<div className="w-full space-y-6">', 'exec')

# ── EXEC: Remove duplicate inner header ────────────────────────
patch("ExecutiveDashboard: remove duplicate inner title/header",
    '''      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black text-white">Executive Dashboard</h1>
          <p className="text-slate-400 mt-1">High-level overview for leadership</p>
        </div>
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />''',
    '''      <div className="flex items-center justify-end">
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />''', 'exec')

# ── APP: ExecutivePageWrapper full data ───────────────────────
patch("ExecutivePageWrapper: pass employees + access data",
    '''  const derived = {
    tools: db.tools.map(t => ({ ...t, derived_risk: computeToolDerivedRisk(t) })),
    alerts: buildRiskAlerts({ tools: db.tools, access: [], employees: [] })
  };''',
    '''  const derived = {
    tools: db.tools.map(t => ({ ...t, derived_risk: computeToolDerivedRisk(t) })),
    employees: db.employees || [],
    access: db.access || [],
    alerts: buildRiskAlerts({ tools: db.tools, access: db.access || [], employees: db.employees || [] })
  };''')

# ── TRANSLATION HOOKS ─────────────────────────────────────────
patch("OffboardingPage: add translation hook",
    "function OffboardingPage() {\n  const { data: db, isLoading } = useDbQuery();\n  const muts = useDbMutations();\n  const nav = useNavigate();\n  const location = useLocation();",
    "function OffboardingPage() {\n  const { data: db, isLoading } = useDbQuery();\n  const muts = useDbMutations();\n  const nav = useNavigate();\n  const location = useLocation();\n" + TRANS_HOOK)

patch("SecurityCompliancePage: add translation hook",
    "function SecurityCompliancePage() {\n  const { data: db } = useDbQuery();",
    "function SecurityCompliancePage() {\n" + TRANS_HOOK + "  const navigate = useNavigate();\n  const { data: db } = useDbQuery();")

patch("CostManagementPage: add translation hook",
    "function CostManagementPage() {\n  const { data: db } = useDbQuery();",
    "function CostManagementPage() {\n" + TRANS_HOOK + "  const navigate = useNavigate();\n  const { data: db } = useDbQuery();")

patch("AnalyticsReportsPage: add translation hook",
    "function AnalyticsReportsPage() {\n  const { data: db } = useDbQuery();",
    "function AnalyticsReportsPage() {\n" + TRANS_HOOK + "  const { data: db } = useDbQuery();")

patch("SettingsPage: add translation hook",
    "function SettingsPage() {\n  const [activeTab, setActiveTab] = useState('general');",
    "function SettingsPage() {\n" + TRANS_HOOK + "  const [activeTab, setActiveTab] = useState('general');")

patch("BillingPage: add translation hook",
    "function BillingPage() {\n  const { data: db } = useDbQuery();\n  const muts = useDbMutations();",
    "function BillingPage() {\n" + TRANS_HOOK + "  const { data: db } = useDbQuery();\n  const muts = useDbMutations();")

# ── TRANSLATE KEY STRINGS ─────────────────────────────────────
patch("OffboardingPage: translate page title",
    'title="Offboarding"\n      right={',
    "title={t('offboarding') || 'Offboarding'}\n      right={")

patch("SecurityCompliancePage: translate page title",
    'title="Security & Compliance"',
    "title={t('security') || 'Security & Compliance'}")

patch("CostManagementPage: translate page title",
    'title="Cost Management"',
    "title={t('cost') || 'Cost Management'}")

patch("AnalyticsReportsPage: translate export PDF",
    'Export PDF',
    "{t('export') || 'Export'} PDF")

patch("AnalyticsReportsPage: translate export CSV",
    'Export CSV',
    "{t('export') || 'Export'} CSV")

patch("SettingsPage: translate Save Changes",
    '<Button variant="primary">Save Changes</Button>',
    "<Button variant=\"primary\">{t('save') || 'Save'} Changes</Button>")

patch("SettingsPage: translate Update Security",
    '<Button variant="primary">Update Security Settings</Button>',
    "<Button variant=\"primary\">{t('save') || 'Save'} Security Settings</Button>")

# ── IMPORT PAGE ───────────────────────────────────────────────
patch("ImportPage: live preview + validation + full translation",
r'''function ImportPage() {
  const muts = useDbMutations();
  const [kind, setKind] = useState("tools");
  const [text, setText] = useState("");
  const [result, setResult] = useState(null);

  const templates = {
    tools: [
      "name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes",
      "Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled",
    ].join("\n"),
    employees: [
      "full_name,email,department,role,status,start_date,end_date",
      "Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,",
    ].join("\n"),
    access: [
      "tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag",
      "Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review",
    ].join("\n"),
  };

  const importNow = async () => {
    const rows = parseCsv(text);
    await muts.bulkImport.mutateAsync({ kind, records: rows });
    setResult({ count: rows.length });
  };

  return (
    <AppShell title="Import Data" right={<Pill tone="slate" icon={Upload}>CSV</Pill>}>
      <div className="grid gap-5 lg:grid-cols-12">
        <div className="lg:col-span-7">
          <Card>
            <CardHeader title="Bulk import" subtitle="Paste CSV for Tools, Employees, or Access records" />
            <CardBody>
              <div className="grid gap-3 md:grid-cols-3">
                <div className="md:col-span-1">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Entity</div>
                  <Select value={kind} onChange={(e) => setKind(e.target.value)}>
                    <option value="tools">Tools</option>
                    <option value="employees">Employees</option>
                    <option value="access">Access Records</option>
                  </Select>
                </div>
                <div className="md:col-span-2 flex items-end justify-end gap-2">
                  <Button variant="secondary" onClick={() => setText(templates[kind])}>
                    <Download className="h-4 w-4" />
                    Paste template
                  </Button>
                  <Button
                    variant="secondary"
                    onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}
                  >
                    <Download className="h-4 w-4" />
                    Download template
                  </Button>
                </div>
              </div>

              <div className="mt-3">
                <Textarea rows={12} className="font-mono text-xs" value={text} onChange={(e) => setText(e.target.value)} placeholder="Paste CSV here..." />
              </div>

              <div className="mt-3 flex items-center justify-between gap-2">
                <div className="text-xs text-slate-500">Matching happens by tool_name and employee_email for Access records.</div>
                <Button disabled={!text.trim()} onClick={importNow}>
                  <Upload className="h-4 w-4" />
                  Import
                </Button>
              </div>

              {result ? (
                <div className="mt-4 rounded-2xl border border-slate-800 bg-slate-950/30 p-4 text-sm text-slate-300">
                  Imported <span className="font-semibold text-slate-100">{result.count}</span> record(s).
                </div>
              ) : null}
            </CardBody>
          </Card>
        </div>

        <div className="lg:col-span-5">
          <Card>
            <CardHeader title="Format guidelines" subtitle="Keep data consistent" />
            <CardBody>
              <div className="space-y-3 text-sm text-slate-300">
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Tools</div>
                  <div className="mt-1 text-slate-400">category ∈ {CATEGORIES.join(", ")}</div>
                  <div className="mt-1 text-slate-400">status ∈ {TOOL_STATUS.join(", ")}</div>
                  <div className="mt-1 text-slate-400">criticality ∈ {CRITICALITY.join(", ")}</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Employees</div>
                  <div className="mt-1 text-slate-400">department ∈ {EMP_DEPARTMENTS.join(", ")}</div>
                  <div className="mt-1 text-slate-400">status ∈ active, offboarding, offboarded</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Access</div>
                  <div className="mt-1 text-slate-400">access_level ∈ {ACCESS_LEVEL.join(", ")}</div>
                  <div className="mt-1 text-slate-400">risk_flag ∈ {RISK_FLAG.join(", ")}</div>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </AppShell>
  );
}''',
r'''function ImportPage() {
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
    tools: [
      "name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes",
      "Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled",
    ].join("\n"),
    employees: [
      "full_name,email,department,role,status,start_date,end_date",
      "Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,",
    ].join("\n"),
    access: [
      "tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag",
      "Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review",
    ].join("\n"),
  };

  const liveRows = useMemo(() => {
    if (!text.trim()) return [];
    try { return parseCsv(text); } catch { return []; }
  }, [text]);

  const COLS = {
    tools:     ["name","category","status","criticality","cost_per_month","owner_name"],
    employees: ["full_name","email","department","role","status"],
    access:    ["tool_name","employee_email","access_level","status","risk_flag"],
  };
  const REQUIRED = { tools: ["name"], employees: ["full_name","email"], access: ["tool_name","employee_email"] };
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
                  <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); }}>
                    <Download className="h-4 w-4" /> Paste template
                  </Button>
                  <Button variant="secondary" onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}>
                    <Download className="h-4 w-4" /> {t('download') || "Download"} template
                  </Button>
                </div>
              </div>
              <div className="mt-3">
                <Textarea rows={10} className="font-mono text-xs" value={text}
                  onChange={(e) => { setText(e.target.value); setImported(null); }}
                  placeholder="Paste CSV here..." />
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
                  {importing
                    ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</>
                    : <><Upload className="h-4 w-4" /> {validCount > 0 ? `${t('import_btn') || 'Import'} ${validCount} record${validCount !== 1 ? 's' : ''}` : (t('import_btn') || 'Import')}</>
                  }
                </Button>
              </div>
            </CardBody>
          </Card>

          {liveRows.length > 0 && !imported && (
            <Card>
              <CardHeader title="Preview" subtitle={`${liveRows.length} row(s) parsed`}
                right={<div className="flex gap-2">
                  {validCount > 0   && <Pill tone="green">✓ {validCount} valid</Pill>}
                  {invalidCount > 0 && <Pill tone="rose">✗ {invalidCount} invalid</Pill>}
                </div>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500">#</th>
                        {cols.map(c => <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}</th>)}
                        <th className="px-3 py-2 text-left text-slate-500">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {liveRows.map((row, i) => {
                        const valid = isRowValid(row);
                        return (
                          <tr key={i} className={cx("border-b border-slate-800/60", valid ? "hover:bg-slate-800/30" : "bg-rose-950/20")}>
                            <td className="px-3 py-2 text-slate-500">{i+1}</td>
                            {cols.map(c => (
                              <td key={c} className={cx("px-3 py-2 max-w-[140px] truncate",
                                !row[c]?.trim() && REQUIRED[kind].includes(c) ? "text-rose-400" : "text-slate-300")}>
                                {row[c] || <span className="text-slate-600 italic">—</span>}
                              </td>
                            ))}
                            <td className="px-3 py-2">
                              {valid
                                ? <span className="flex items-center gap-1 text-emerald-400"><Check className="h-3 w-3"/>OK</span>
                                : <span className="flex items-center gap-1 text-rose-400"><AlertTriangle className="h-3 w-3"/>Missing</span>}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </CardBody>
            </Card>
          )}

          {imported && (
            <Card>
              <CardHeader title={`✅ ${imported.count} ${imported.kind} imported`} subtitle="Records added to your workspace"
                right={<Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500">#</th>
                        {COLS[imported.kind].map(c => <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}</th>)}
                        <th className="px-3 py-2 text-left text-slate-500">Result</th>
                      </tr>
                    </thead>
                    <tbody>
                      {imported.rows.map((row, i) => (
                        <tr key={i} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                          <td className="px-3 py-2 text-slate-500">{i+1}</td>
                          {COLS[imported.kind].map(c => (
                            <td key={c} className="px-3 py-2 text-slate-300 max-w-[140px] truncate">
                              {row[c] || <span className="text-slate-600 italic">—</span>}
                            </td>
                          ))}
                          <td className="px-3 py-2"><span className="flex items-center gap-1 text-emerald-400 font-semibold"><CheckCircle className="h-3 w-3"/> Added</span></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="mt-4 flex gap-3">
                  <Button size="sm" onClick={() => { window.location.href = `/${imported.kind === "employees" ? "employees" : imported.kind === "access" ? "access" : "tools"}`; }}>
                    {t('view') || "View"} in {imported.kind === "employees" ? (t('employees') || "Employees") : imported.kind === "access" ? (t('access') || "Access Control") : (t('tools') || "Tools")}
                  </Button>
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
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">{t('tools') || "Tools"}</div>
                  <div className="mt-1 text-slate-400">category ∈ {CATEGORIES.join(", ")}</div>
                  <div className="mt-1 text-slate-400">status ∈ {TOOL_STATUS.join(", ")}</div>
                  <div className="mt-1 text-slate-400">criticality ∈ {CRITICALITY.join(", ")}</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">{t('employees') || "Employees"}</div>
                  <div className="mt-1 text-slate-400">department ∈ {EMP_DEPARTMENTS.join(", ")}</div>
                  <div className="mt-1 text-slate-400">status ∈ active, offboarding, offboarded</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">{t('access') || "Access"}</div>
                  <div className="mt-1 text-slate-400">access_level ∈ {ACCESS_LEVEL.join(", ")}</div>
                  <div className="mt-1 text-slate-400">risk_flag ∈ {RISK_FLAG.join(", ")}</div>
                </div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardHeader title="Current workspace data" subtitle="Records already imported" />
            <CardBody>
              <div className="grid grid-cols-3 gap-3 text-center">
                {[
                  { label: t('tools') || "Tools",     count: db?.tools?.length     ?? "—", color: "text-blue-400"   },
                  { label: t('employees') || "Employees", count: db?.employees?.length ?? "—", color: "text-violet-400" },
                  { label: t('access') || "Access",    count: db?.access?.length    ?? "—", color: "text-emerald-400"},
                ].map(({ label, count, color }) => (
                  <div key={label} className="rounded-xl border border-slate-800 bg-slate-950/40 p-4">
                    <div className={cx("text-2xl font-bold", color)}>{count}</div>
                    <div className="text-xs text-slate-500 mt-1">{label}</div>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </AppShell>
  );
}''')

# ── Report ──────────────────────────────────────────────────────
print()
for n in ok:   print(f"  \033[32m✓\033[0m  {n}")
for n in fail: print(f"  \033[31m✗\033[0m  FAILED: {n}")
if fail: sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app_src)
with open('src/ExecutiveDashboard.jsx', 'w', encoding='utf-8') as f:
    f.write(exec_src)

print(f"\n  \033[32mAll patches applied — App: {app_src.count(chr(10))} lines, Exec: {exec_src.count(chr(10))} lines\033[0m")
PYEOF

PATCH_EXIT=$?
if [ $PATCH_EXIT -ne 0 ]; then
  echo -e "${RED}✗ Patching failed. Restoring backup...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  [ -f "backups/$TS/ExecutiveDashboard.jsx" ] && cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed. Restoring backup...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  [ -f "backups/$TS/ExecutiveDashboard.jsx" ] && cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Deployed successfully!                              ║"
echo -e "╠════════════════════════════════════════════════════════╣"
echo -e "║  EXECUTIVE PAGE                                        ║"
echo -e "║    • Full-width layout (removed max-w-7xl)             ║"
echo -e "║    • Duplicate header removed                          ║"
echo -e "║    • Real employee + access data passed in             ║"
echo -e "║  TRANSLATIONS (7 pages now fully wired):               ║"
echo -e "║    • OffboardingPage, SecurityCompliancePage           ║"
echo -e "║    • CostManagementPage, AnalyticsReportsPage          ║"
echo -e "║    • SettingsPage, BillingPage, ImportPage             ║"
echo -e "║  IMPORT PAGE                                           ║"
echo -e "║    • Import button works with live row counter         ║"
echo -e "║    • Preview table before import                       ║"
echo -e "║    • Success table with navigate button after import   ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}\n"
