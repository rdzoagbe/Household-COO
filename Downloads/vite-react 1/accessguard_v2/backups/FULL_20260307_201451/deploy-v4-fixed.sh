#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — v4 Fixed                             ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
cp src/ExecutiveDashboard.jsx "backups/$TS/ExecutiveDashboard.jsx" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 << 'PYEOF'
import sys, re

ok = []; warn = []; fail = []

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()
with open('src/ExecutiveDashboard.jsx', 'r', encoding='utf-8') as f:
    exc = f.read()

def patch_app(name, old, new):
    global app
    if new in app:        ok.append(f"{name} (already done)")
    elif old in app:      app = app.replace(old, new, 1); ok.append(name)
    else:                 fail.append(name)

def patch_exc(name, old, new):
    global exc
    if new in exc:        ok.append(f"{name} (already done)")
    elif old in exc:      exc = exc.replace(old, new, 1); ok.append(name)
    else:                 fail.append(name)

# Smart fn: inject code into a function body if a marker string isn't already there
def inject_after(name, fn_marker, inject_code, guard):
    global app
    if guard in app:
        ok.append(f"{name} (already done)")
        return
    idx = app.find(fn_marker)
    if idx == -1:
        fail.append(f"{name} — fn not found")
        return
    # find the opening brace of the function body
    brace = app.find('{', idx)
    insert_at = app.find('\n', brace) + 1
    app = app[:insert_at] + inject_code + app[insert_at:]
    ok.append(name)

HOOK = """\
  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');
  const t = useTranslation(language);
  useEffect(() => {
    const handleLangChange = (e) => setLanguage(e.detail || localStorage.getItem('language') || 'en');
    window.addEventListener('languagechange', handleLangChange);
    return () => window.removeEventListener('languagechange', handleLangChange);
  }, []);
"""

# ── EXEC: full-width layout ─────────────────────────────────
patch_exc("Exec: remove max-w-7xl",
    '<div className="max-w-7xl mx-auto p-6 space-y-6">',
    '<div className="w-full space-y-6">')

patch_exc("Exec: remove duplicate inner header",
    """      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-black text-white">Executive Dashboard</h1>
          <p className="text-slate-400 mt-1">High-level overview for leadership</p>
        </div>
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />""",
    """      <div className="flex items-center justify-end">
        <button
          onClick={() => window.print()}
          className="flex items-center gap-2 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold text-white"
        >
          <Download className="h-5 w-5" />""")

# ── ExecutivePageWrapper: full data ─────────────────────────
# Handle both old forms (with or without employees/access)
if 'employees: db.employees || []' not in app:
    app = re.sub(
        r'(const derived = \{[^}]*?tools:[^\n]+\n[^}]*?)alerts: buildRiskAlerts\(\{[^}]*?\}\)',
        r'\1employees: db.employees || [],\n    access: db.access || [],\n    alerts: buildRiskAlerts({ tools: db.tools, access: db.access || [], employees: db.employees || [] })',
        app, count=1, flags=re.DOTALL
    )
    if 'employees: db.employees || []' in app:
        ok.append("ExecutivePageWrapper: pass full data")
    else:
        fail.append("ExecutivePageWrapper: pass full data")
else:
    ok.append("ExecutivePageWrapper: pass full data (already done)")

# ── TRANSLATION HOOKS — inject smartly ─────────────────────
inject_after("OffboardingPage: translation hook",
    "function OffboardingPage()", HOOK, "OffboardingPage() {\n" + HOOK[:30])

inject_after("SecurityCompliancePage: translation hook",
    "function SecurityCompliancePage()", HOOK, "SecurityCompliancePage() {\n" + HOOK[:30])

inject_after("CostManagementPage: translation hook",
    "function CostManagementPage()", HOOK, "CostManagementPage() {\n" + HOOK[:30])

inject_after("AnalyticsReportsPage: translation hook",
    "function AnalyticsReportsPage()", HOOK, "AnalyticsReportsPage() {\n" + HOOK[:30])

inject_after("SettingsPage: translation hook",
    "function SettingsPage()", HOOK, "SettingsPage() {\n" + HOOK[:30])

inject_after("BillingPage: translation hook",
    "function BillingPage()", HOOK, "BillingPage() {\n" + HOOK[:30])

# ── TRANSLATE KEY STRINGS (idempotent — use || fallback) ────

# Offboarding title - match any variant
if "t('offboarding')" not in app:
    app = re.sub(r'title="Offboarding"(\s*\n\s*right=\{)',
                 r"title={t('offboarding') || 'Offboarding'}\1", app)
    ok.append("OffboardingPage: translate title") if "t('offboarding')" in app else fail.append("OffboardingPage: translate title")
else:
    ok.append("OffboardingPage: translate title (already done)")

# Security title
if "t('security')" not in app:
    app = app.replace('title="Security & Compliance"', "title={t('security') || 'Security & Compliance'}", 1)
    ok.append("SecurityCompliancePage: translate title") if "t('security')" in app else fail.append("SecurityCompliancePage: translate title")
else:
    ok.append("SecurityCompliancePage: translate title (already done)")

# Cost title
if "t('cost')" not in app:
    app = app.replace('title="Cost Management"', "title={t('cost') || 'Cost Management'}", 1)
    ok.append("CostManagementPage: translate title") if "t('cost')" in app else fail.append("CostManagementPage: translate title")
else:
    ok.append("CostManagementPage: translate title (already done)")

# Analytics Export PDF/CSV
if "{t('export')" not in app:
    app = app.replace('Export PDF', "{t('export') || 'Export'} PDF", 1)
    app = app.replace('Export CSV', "{t('export') || 'Export'} CSV", 1)
    ok.append("AnalyticsReportsPage: translate export buttons")
else:
    ok.append("AnalyticsReportsPage: translate export buttons (already done)")

# Settings Save button - handle both old (no onClick) and new (with onClick) variants
for old_save in [
    '<Button variant="primary">Save Changes</Button>',
    '<Button variant="primary" onClick={handleSaveGeneral}>Save Changes</Button>',
]:
    if old_save in app:
        new_save = old_save.replace('>Save Changes<', ">{t('save') || 'Save'} Changes<")
        app = app.replace(old_save, new_save, 1)
        ok.append("SettingsPage: translate Save Changes")
        break
else:
    if "t('save')" in app:
        ok.append("SettingsPage: translate Save Changes (already done)")
    else:
        fail.append("SettingsPage: translate Save Changes")

# Settings Security button
for old_sec in [
    '<Button variant="primary">Update Security Settings</Button>',
    '<Button variant="primary" onClick={handleSaveSecurity}>Update Security Settings</Button>',
]:
    if old_sec in app:
        new_sec = old_sec.replace('>Update Security Settings<', ">{t('save') || 'Save'} Security Settings<")
        app = app.replace(old_sec, new_sec, 1)
        ok.append("SettingsPage: translate Update Security")
        break
else:
    if 'Security Settings<' in app:
        ok.append("SettingsPage: translate Update Security (already done)")
    else:
        fail.append("SettingsPage: translate Update Security")

# ── ImportPage: full replacement ────────────────────────────
# Detect what version is present and replace any form of ImportPage
import_start = app.find('function ImportPage()')
import_end   = app.find('\nfunction ', import_start + 10)
current_import = app[import_start:import_end]

if 'const liveRows = useMemo' in current_import:
    ok.append("ImportPage: full preview (already done)")
else:
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
}'''
    app = app[:import_start] + NEW_IMPORT + app[import_end:]
    ok.append("ImportPage: full preview + validation + translation")

# ── Print results ────────────────────────────────────────────
print()
for n in ok:   print(f"  \033[32m✓\033[0m  {n}")
for n in fail: print(f"  \033[31m✗\033[0m  FAILED: {n}")

if fail:
    print(f"\n\033[33m⚠ {len(fail)} patch(es) failed\033[0m")
    sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
with open('src/ExecutiveDashboard.jsx', 'w', encoding='utf-8') as f:
    f.write(exc)

print(f"\n  \033[32mAll done — App: {app.count(chr(10))} lines\033[0m")
PYEOF

PATCH_EXIT=$?
if [ $PATCH_EXIT -ne 0 ]; then
  echo -e "\n${RED}✗ Patching failed. Restoring backup...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  [ -f "backups/$TS/ExecutiveDashboard.jsx" ] && cp "backups/$TS/ExecutiveDashboard.jsx" src/ExecutiveDashboard.jsx
  exit 1
fi

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

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Deployed!                                           ║"
echo -e "╠════════════════════════════════════════════════════════╣"
echo -e "║  /executive  — full width, no duplicate header         ║"
echo -e "║  Translations — 7 pages fully wired + auto-refresh     ║"
echo -e "║  Import page — live preview, validation, success table ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}\n"
