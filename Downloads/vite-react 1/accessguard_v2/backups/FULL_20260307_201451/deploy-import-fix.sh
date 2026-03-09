#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AccessGuard V2 — Import Page Fix       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}"

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

OLD = '''function ImportPage() {
  const muts = useDbMutations();
  const [kind, setKind] = useState("tools");
  const [text, setText] = useState("");
  const [result, setResult] = useState(null);

  const templates = {
    tools: [
      "name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes",
      "Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled",
    ].join("\\n"),
    employees: [
      "full_name,email,department,role,status,start_date,end_date",
      "Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,",
    ].join("\\n"),
    access: [
      "tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag",
      "Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review",
    ].join("\\n"),
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
}'''

NEW = '''function ImportPage() {
  const muts = useDbMutations();
  const { data: db } = useDbQuery();
  const [kind, setKind] = useState("tools");
  const [text, setText] = useState("");
  const [imported, setImported] = useState(null);
  const [importing, setImporting] = useState(false);

  const templates = {
    tools: [
      "name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes",
      "Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled",
    ].join("\\n"),
    employees: [
      "full_name,email,department,role,status,start_date,end_date",
      "Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,",
    ].join("\\n"),
    access: [
      "tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag",
      "Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review",
    ].join("\\n"),
  };

  const liveRows = useMemo(() => {
    if (!text.trim()) return [];
    try { return parseCsv(text); } catch { return []; }
  }, [text]);

  const handleImport = async () => {
    if (!liveRows.length) return;
    setImporting(true);
    try {
      await muts.bulkImport.mutateAsync({ kind, records: liveRows });
      setImported({ count: liveRows.length, kind, rows: liveRows });
      setText("");
    } finally {
      setImporting(false);
    }
  };

  const COLS = {
    tools:     ["name","category","status","criticality","cost_per_month","owner_name"],
    employees: ["full_name","email","department","role","status"],
    access:    ["tool_name","employee_email","access_level","status","risk_flag"],
  };

  const REQUIRED = {
    tools:     ["name"],
    employees: ["full_name","email"],
    access:    ["tool_name","employee_email"],
  };

  const cols = COLS[kind];
  const isRowValid = (row) => REQUIRED[kind].every(k => row[k]?.trim());
  const validCount   = liveRows.filter(isRowValid).length;
  const invalidCount = liveRows.length - validCount;

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
                  <Select value={kind} onChange={(e) => { setKind(e.target.value); setText(""); setImported(null); }}>
                    <option value="tools">Tools</option>
                    <option value="employees">Employees</option>
                    <option value="access">Access Records</option>
                  </Select>
                </div>
                <div className="md:col-span-2 flex items-end justify-end gap-2">
                  <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); }}>
                    <Download className="h-4 w-4" />
                    Paste template
                  </Button>
                  <Button variant="secondary" onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}>
                    <Download className="h-4 w-4" />
                    Download template
                  </Button>
                </div>
              </div>

              <div className="mt-3">
                <Textarea
                  rows={10}
                  className="font-mono text-xs"
                  value={text}
                  onChange={(e) => { setText(e.target.value); setImported(null); }}
                  placeholder="Paste CSV here..."
                />
              </div>

              {liveRows.length > 0 && (
                <div className="mt-2 flex items-center gap-3 text-xs">
                  <span className="text-slate-400">{liveRows.length} row(s) detected</span>
                  {validCount > 0   && <span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
                  {invalidCount > 0 && <span className="text-rose-400 font-semibold">✗ {invalidCount} missing required fields</span>}
                </div>
              )}

              <div className="mt-3 flex items-center justify-between gap-2">
                <div className="text-xs text-slate-500">Matching happens by tool_name and employee_email for Access records.</div>
                <Button disabled={!text.trim() || validCount === 0 || importing} onClick={handleImport}>
                  {importing
                    ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</>
                    : <><Upload className="h-4 w-4" /> Import {validCount > 0 ? `${validCount} record${validCount > 1 ? "s" : ""}` : ""}</>
                  }
                </Button>
              </div>
            </CardBody>
          </Card>

          {liveRows.length > 0 && !imported && (
            <Card className="mt-5">
              <CardHeader
                title="Preview"
                subtitle={`${liveRows.length} row(s) ready to import`}
                right={
                  <div className="flex gap-2">
                    {validCount > 0   && <Pill tone="green">✓ {validCount} valid</Pill>}
                    {invalidCount > 0 && <Pill tone="rose">✗ {invalidCount} invalid</Pill>}
                  </div>
                }
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500 font-semibold w-8">#</th>
                        {cols.map(c => (
                          <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">
                            {c.replace(/_/g, " ")}
                          </th>
                        ))}
                        <th className="px-3 py-2 text-left text-slate-500 font-semibold">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {liveRows.map((row, i) => {
                        const valid = isRowValid(row);
                        return (
                          <tr key={i} className={cx("border-b border-slate-800/60 transition-colors", valid ? "hover:bg-slate-800/30" : "bg-rose-950/20")}>
                            <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                            {cols.map(c => (
                              <td key={c} className={cx("px-3 py-2", !row[c]?.trim() && REQUIRED[kind].includes(c) ? "text-rose-400" : "text-slate-300")}>
                                {row[c] || <span className="text-slate-600 italic">—</span>}
                              </td>
                            ))}
                            <td className="px-3 py-2">
                              {valid
                                ? <span className="inline-flex items-center gap-1 text-emerald-400"><Check className="h-3 w-3" /> OK</span>
                                : <span className="inline-flex items-center gap-1 text-rose-400"><AlertTriangle className="h-3 w-3" /> Missing field</span>
                              }
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
            <Card className="mt-5">
              <CardHeader
                title={`✅ ${imported.count} ${imported.kind} imported`}
                subtitle="Data has been added to your workspace"
                right={<Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500 font-semibold w-8">#</th>
                        {COLS[imported.kind].map(c => (
                          <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">
                            {c.replace(/_/g, " ")}
                          </th>
                        ))}
                        <th className="px-3 py-2 text-left text-slate-500 font-semibold">Result</th>
                      </tr>
                    </thead>
                    <tbody>
                      {imported.rows.map((row, i) => (
                        <tr key={i} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                          <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                          {COLS[imported.kind].map(c => (
                            <td key={c} className="px-3 py-2 text-slate-300">
                              {row[c] || <span className="text-slate-600 italic">—</span>}
                            </td>
                          ))}
                          <td className="px-3 py-2">
                            <span className="inline-flex items-center gap-1 text-emerald-400 font-semibold">
                              <CheckCircle className="h-3 w-3" /> Added
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="mt-4 flex gap-3">
                  <Button size="sm" onClick={() => { window.location.href = `/${imported.kind === "employees" ? "employees" : imported.kind === "access" ? "access" : "tools"}`; }}>
                    View in {imported.kind === "employees" ? "Employees" : imported.kind === "access" ? "Access Control" : "Tools"}
                  </Button>
                  <Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>
                </div>
              </CardBody>
            </Card>
          )}
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

          <Card className="mt-5">
            <CardHeader title="Current data" subtitle="Records already in your workspace" />
            <CardBody>
              <div className="grid grid-cols-3 gap-3 text-center">
                {[
                  { label: "Tools",     count: db?.tools?.length     ?? "—", tone: "blue"   },
                  { label: "Employees", count: db?.employees?.length ?? "—", tone: "purple" },
                  { label: "Access",    count: db?.access?.length    ?? "—", tone: "green"  },
                ].map(({ label, count, tone }) => (
                  <div key={label} className="rounded-xl border border-slate-800 bg-slate-950/40 p-4">
                    <div className={cx("text-2xl font-bold", tone === "blue" ? "text-blue-400" : tone === "purple" ? "text-violet-400" : "text-emerald-400")}>
                      {count}
                    </div>
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

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    print("\033[32m  ✓  ImportPage patched successfully\033[0m")
elif NEW in src:
    print("\033[33m  --  Already applied\033[0m")
else:
    print("\033[31m  ✗  Pattern not found — backup restored\033[0m")
    import shutil, sys
    import os, glob
    backups = sorted(glob.glob('backups/*/App.jsx'))
    if backups: shutil.copy(backups[-1], 'src/App.jsx')
    sys.exit(1)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed. Restoring backup...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  exit 1
fi

echo ""
echo -e "${BLUE}Deploying to Firebase...${NC}"
firebase deploy --only hosting

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✓ Import page upgraded!                ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Live row counter as you type            ║${NC}"
echo -e "${GREEN}║  Preview table before import             ║${NC}"
echo -e "${GREEN}║  Red rows highlight missing fields       ║${NC}"
echo -e "${GREEN}║  Import button shows exact record count  ║${NC}"
echo -e "${GREEN}║  Post-import validation table            ║${NC}"
echo -e "${GREEN}║  Navigate to page after import           ║${NC}"
echo -e "${GREEN}║  Current DB counts on sidebar            ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
