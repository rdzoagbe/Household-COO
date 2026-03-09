#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Full Page Upgrades + Contracts AI     ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
cp src/translations.js "backups/$TS/translations.js" 2>/dev/null || true
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ══ 1. ADD MISSING ICONS ═══════════════════════════════════════
needed = ['ArrowLeftRight', 'Paperclip', 'Send', 'Bot', 'Clock3', 'TrendingDown', 'BarChart2']
missing = [i for i in needed if i not in app]
if missing:
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  ' + ',\n  '.join(missing) + ',\n} from "lucide-react"'
    )
    ok.append(f"Icons added: {', '.join(missing)}")

# ══ 2. REMOVE ALL STALE languagechange listeners ══════════════
stale_inner = (
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
count = 0
while stale_inner in app:
    idx = app.find(stale_inner)
    ue = app.rfind('\n  useEffect(() => {\n', 0, idx)
    cm = app.rfind('\n  // Auto-update when language', 0, ue)
    start = cm if (cm != -1 and ue - cm < 80) else ue
    app = app[:start] + '\n' + app[idx + len(stale_inner):]
    count += 1
ok.append(f"Removed {count} stale languagechange listener(s)")

# ══ 3. REPLACE OFFBOARDING PAGE ═══════════════════════════════
def replace_fn(name, new_code):
    global app
    idx = app.find(f'function {name}()')
    if idx == -1: warn.append(f"{name}: not found"); return
    end = app.find('\nfunction ', idx + 10)
    app = app[:idx] + new_code + app[end:]
    ok.append(f"{name}: replaced")

OFFBOARDING = r"""function OffboardingPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db, isLoading } = useDbQuery();
  const muts = useDbMutations();
  const nav = useNavigate();
  const location = useLocation();

  const params = new URLSearchParams(location.search);
  const pre = params.get("employee") || "";
  const employees = useMemo(() => db?.employees || [], [db]);
  const access = db?.access || [];
  const [tab, setTab] = useState("queue");
  const [employeeId, setEmployeeId] = useState(pre || "");
  const [checked, setChecked] = useState({});

  useEffect(() => {
    if (!employeeId && employees[0]?.id) setEmployeeId(employees[0].id);
  }, [employeeId, employees]);

  const employee = employees.find(e => e.id === employeeId);
  const activeRecords = access.filter(a => a.employee_id === employeeId && a.status === "active");

  const revokeOne = id => muts.updateAccess.mutate({ id, patch: { status: "revoked" } });
  const revokeAll = () => {
    activeRecords.forEach(r => revokeOne(r.id));
    muts.updateEmployee.mutate({ id: employeeId, patch: { status: "offboarded", end_date: employee?.end_date || todayISO() } });
  };

  const upcoming = useMemo(() => {
    if (!db) return [];
    return db.employees
      .filter(e => e.status === "offboarding" || (e.end_date && e.end_date >= todayISO() && e.status !== "offboarded"))
      .sort((a, b) => (a.end_date || "9999") > (b.end_date || "9999") ? 1 : -1)
      .slice(0, 8);
  }, [db]);

  const offboarded = useMemo(() => {
    if (!db) return [];
    return db.employees.filter(e => e.status === "offboarded")
      .sort((a, b) => (a.end_date || "") < (b.end_date || "") ? 1 : -1);
  }, [db]);

  const daysUntil = d => d ? Math.ceil((new Date(d) - new Date()) / 86400000) : null;

  const riskAccess = access.filter(a => {
    const emp = employees.find(e => e.id === a.employee_id);
    return emp?.status === "offboarded" && a.status === "active";
  });

  return (
    <AppShell title={t('offboarding') || 'Offboarding'}
      right={<Button variant="secondary" onClick={() => nav("/employees")}><Users className="h-4 w-4" /> Employees</Button>}
    >
      <div className="grid gap-5 lg:grid-cols-12">
        <div className="lg:col-span-8 space-y-5">

          {/* Tab bar */}
          <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
            {[{id:"queue",label:"Offboarding Queue"},{id:"history",label:"Offboarded History"},{id:"revoke",label:"Revoke Access"}].map(({id,label}) => (
              <button key={id} onClick={() => setTab(id)} className={cx("px-4 py-2 rounded-lg text-sm font-medium transition-colors", tab===id?"bg-blue-600 text-white shadow":"text-slate-400 hover:text-slate-200")}>{label}</button>
            ))}
          </div>

          {/* QUEUE TAB */}
          {tab === "queue" && (
            <Card>
              <CardHeader title="Next to be offboarded" subtitle="Employees with upcoming end dates or offboarding status" />
              <CardBody>
                {isLoading||!db ? <SkeletonRow cols={6}/> : upcoming.length===0 ? (
                  <EmptyState icon={UserMinus} title="No upcoming offboardings" body="No employees flagged for offboarding soon." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                        {["Employee","Department","End Date","Days Left","Status","Action"].map(h=>(
                          <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold">{h}</th>
                        ))}
                      </tr></thead>
                      <tbody>
                        {upcoming.map(e => {
                          const days = daysUntil(e.end_date);
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3"><div className="font-medium text-white">{e.full_name}</div><div className="text-xs text-slate-500">{e.email}</div></td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department||"—"}</td>
                              <td className="px-4 py-3 text-slate-300">{e.end_date||"—"}</td>
                              <td className="px-4 py-3">
                                {days!==null ? <span className={cx("inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full",days<=0?"bg-rose-500/20 text-rose-400":days<=7?"bg-amber-500/20 text-amber-400":"bg-slate-700 text-slate-300")}>{days<=0?`${Math.abs(days)}d overdue`:days===0?"Today":`${days}d`}</span>:"—"}
                              </td>
                              <td className="px-4 py-3"><span className={cx("px-2 py-1 rounded-full text-xs font-semibold",e.status==="offboarding"?"bg-amber-500/20 text-amber-400":"bg-blue-500/20 text-blue-400")}>{e.status}</span></td>
                              <td className="px-4 py-3"><Button size="sm" variant="secondary" onClick={() => { setEmployeeId(e.id); setTab("revoke"); }}>Revoke access</Button></td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardBody>
            </Card>
          )}

          {/* HISTORY TAB */}
          {tab === "history" && (
            <Card>
              <CardHeader title="Offboarded employees" subtitle="Complete history with timestamps" right={<Pill tone="slate">{offboarded.length} total</Pill>} />
              <CardBody>
                {isLoading||!db ? <SkeletonRow cols={5}/> : offboarded.length===0 ? (
                  <EmptyState icon={UserMinus} title="No offboarded employees" body="Employees you offboard appear here." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                        {["Employee","Department","Role","Date Offboarded","Access Status"].map(h=>(
                          <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold">{h}</th>
                        ))}
                      </tr></thead>
                      <tbody>
                        {offboarded.map(e => {
                          const revoked = access.filter(a=>a.employee_id===e.id&&a.status==="revoked").length;
                          const still = access.filter(a=>a.employee_id===e.id&&a.status==="active").length;
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3"><div className="font-medium text-white">{e.full_name}</div><div className="text-xs text-slate-500">{e.email}</div></td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department||"—"}</td>
                              <td className="px-4 py-3 text-slate-400">{e.role||"—"}</td>
                              <td className="px-4 py-3">
                                <div className="text-slate-300">{e.end_date||"—"}</div>
                                {e.end_date&&<div className="text-xs text-slate-500">{new Date(e.end_date).toLocaleDateString('en-GB',{weekday:"short",year:"numeric",month:"short",day:"numeric"})}</div>}
                              </td>
                              <td className="px-4 py-3">
                                {revoked>0&&<span className="text-xs text-emerald-400 font-semibold mr-2">✓ {revoked} revoked</span>}
                                {still>0&&<span className="text-xs text-rose-400 font-semibold">⚠ {still} still active</span>}
                                {revoked===0&&still===0&&<span className="text-xs text-slate-500">No records</span>}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardBody>
            </Card>
          )}

          {/* REVOKE TAB */}
          {tab === "revoke" && (
            <Card>
              <CardHeader title={t('revoke_access')||"Revoke access"} subtitle="Select employee and revoke active access" />
              <CardBody>
                {isLoading||!db ? <SkeletonRow cols={6}/> : (
                  <div className="grid gap-5">
                    <div className="grid gap-3 md:grid-cols-2">
                      <div>
                        <div className="mb-1 text-xs font-semibold text-slate-400">Select employee</div>
                        <Select value={employeeId} onChange={e => setEmployeeId(e.target.value)}>
                          {employees.map(e => <option key={e.id} value={e.id}>{e.full_name} — {e.status}</option>)}
                        </Select>
                      </div>
                      <div className="flex items-end justify-end">
                        <Button variant="danger" disabled={!activeRecords.length} onClick={revokeAll}>
                          <BadgeX className="h-4 w-4" /> Revoke All ({activeRecords.length})
                        </Button>
                      </div>
                    </div>
                    {activeRecords.length ? (
                      <div className="grid gap-2">
                        {activeRecords.map(r => (
                          <div key={r.id} className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                            <div className="min-w-0">
                              <div className="text-sm font-semibold">{r.tool_name}</div>
                              <div className="mt-2 flex flex-wrap gap-2">
                                <AccessLevelBadge level={r.access_level} />
                                <Pill tone="slate" icon={CalendarClock}>Granted: {r.granted_date||"—"}</Pill>
                              </div>
                            </div>
                            <div className="flex items-center gap-2">
                              <label className="flex items-center gap-2 text-xs text-slate-400">
                                <input type="checkbox" checked={Boolean(checked[r.id])} onChange={e=>setChecked(m=>({...m,[r.id]:e.target.checked}))} /> Verified
                              </label>
                              <Button size="sm" variant="danger" onClick={() => revokeOne(r.id)}><BadgeX className="h-4 w-4" /> Revoke</Button>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : <EmptyState icon={UserMinus} title="No active access" body="This employee has no active access records." />}
                  </div>
                )}
              </CardBody>
            </Card>
          )}

          {/* Risk access alert — always shown */}
          {riskAccess.length > 0 && (
            <div className="rounded-2xl border border-rose-500/30 bg-rose-500/10 p-4">
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 text-rose-400 flex-shrink-0 mt-0.5" />
                <div>
                  <div className="font-semibold text-rose-300">⚠ {riskAccess.length} access record{riskAccess.length!==1?"s":""} still active for offboarded employees</div>
                  <div className="text-xs text-rose-400 mt-1">Go to the Revoke Access tab to clean these up immediately.</div>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* RIGHT SIDEBAR */}
        <div className="lg:col-span-4 space-y-5">
          <Card>
            <CardHeader title="Summary" subtitle="Offboarding overview" />
            <CardBody>
              <div className="space-y-3">
                {[
                  {label:"Pending offboarding", value:upcoming.length, color:"text-amber-400"},
                  {label:"Offboarded total", value:offboarded.length, color:"text-slate-300"},
                  {label:"Active employees", value:employees.filter(e=>e.status==="active").length, color:"text-emerald-400"},
                  {label:"Access records at risk", value:riskAccess.length, color:"text-rose-400"},
                ].map(({label,value,color}) => (
                  <div key={label} className="flex items-center justify-between rounded-xl border border-slate-800 bg-slate-950/30 px-4 py-3">
                    <span className="text-sm text-slate-400">{label}</span>
                    <span className={cx("text-xl font-bold",color)}>{value}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="Offboarding checklist" subtitle="Best practices" />
            <CardBody>
              <div className="space-y-2 text-sm text-slate-400">
                {["Revoke all SaaS tool access","Remove from SSO / identity provider","Transfer ownership of shared docs","Recover company devices","Archive or reassign email","Remove from Slack / Teams","Cancel user-specific subscriptions"].map((item,i) => (
                  <div key={i} className="flex items-start gap-2">
                    <div className="mt-0.5 h-4 w-4 rounded border border-slate-600 flex-shrink-0" />
                    <span>{item}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          {/* Department breakdown */}
          {!isLoading && db && (() => {
            const deptCounts = {};
            upcoming.forEach(e => { deptCounts[e.department||"other"] = (deptCounts[e.department||"other"]||0)+1; });
            const entries = Object.entries(deptCounts);
            return entries.length > 0 ? (
              <Card>
                <CardHeader title="Pending by department" subtitle="Upcoming offboardings" />
                <CardBody>
                  <div className="space-y-2">
                    {entries.map(([dept,count]) => (
                      <div key={dept}>
                        <div className="flex justify-between text-xs mb-1">
                          <span className="text-slate-400 capitalize">{dept}</span>
                          <span className="text-slate-300 font-semibold">{count}</span>
                        </div>
                        <div className="h-1.5 bg-slate-800 rounded-full"><div className="h-1.5 bg-amber-500 rounded-full" style={{width:`${(count/upcoming.length)*100}%`}} /></div>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
            ) : null;
          })()}
        </div>
      </div>
    </AppShell>
  );
}
"""

IMPORT_PAGE = r"""function ImportPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const muts = useDbMutations();
  const { data: db } = useDbQuery();
  const [kind, setKind] = useState("tools");
  const [text, setText] = useState("");
  const [imported, setImported] = useState(null);
  const [importing, setImporting] = useState(false);
  const [validated, setValidated] = useState(false);
  const [validationErrors, setValidationErrors] = useState([]);

  const templates = {
    tools: ["name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes","Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled"].join("\n"),
    employees: ["full_name,email,department,role,status,start_date,end_date","Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,"].join("\n"),
    access: ["tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag","Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review"].join("\n"),
  };

  const COLS = { tools:["name","category","status","criticality","cost_per_month","owner_name"], employees:["full_name","email","department","role","status"], access:["tool_name","employee_email","access_level","status","risk_flag"] };
  const REQUIRED = { tools:["name"], employees:["full_name","email"], access:["tool_name","employee_email"] };
  const VALID_VALUES = {
    tools:     { status: TOOL_STATUS, criticality: CRITICALITY },
    employees: { status: ["active","offboarding","offboarded"], department: EMP_DEPARTMENTS },
    access:    { access_level: ACCESS_LEVEL, status: ["active","revoked","pending_revoke"], risk_flag: RISK_FLAG },
  };

  const liveRows = useMemo(() => { if(!text.trim()) return []; try { return parseCsv(text); } catch { return []; } }, [text]);
  const isRowValid = row => REQUIRED[kind].every(k => row[k]?.trim());
  const validCount   = liveRows.filter(isRowValid).length;
  const invalidCount = liveRows.length - validCount;

  const runValidation = () => {
    const errors = [];
    const rules = VALID_VALUES[kind]||{};
    liveRows.forEach((row,i) => {
      REQUIRED[kind].forEach(f => { if(!row[f]?.trim()) errors.push({row:i+1,field:f,type:"missing",msg:`Row ${i+1}: '${f}' is required but empty.`}); });
      Object.entries(rules).forEach(([f,allowed]) => { if(row[f]&&!allowed.includes(row[f].trim())) errors.push({row:i+1,field:f,type:"invalid",msg:`Row ${i+1}: '${f}' = "${row[f]}" — must be one of: ${allowed.join(", ")}.`}); });
    });
    setValidationErrors(errors); setValidated(true);
  };

  const handleImport = async () => {
    if(!validCount) return;
    setImporting(true);
    try {
      await muts.bulkImport.mutateAsync({kind, records:liveRows.filter(isRowValid)});
      setImported({count:validCount,kind,rows:liveRows.filter(isRowValid)});
      setText(""); setValidated(false); setValidationErrors([]);
    } finally { setImporting(false); }
  };

  const cols = COLS[kind];

  // Import history from localStorage
  const importHistory = useMemo(() => {
    try { return JSON.parse(localStorage.getItem('ag_import_history')||'[]'); } catch { return []; }
  }, [imported]);

  return (
    <AppShell title={t('import')||'Import Data'} right={<Pill tone="slate" icon={Upload}>CSV</Pill>}>
      <div className="grid gap-5 lg:grid-cols-12">
        <div className="lg:col-span-7 space-y-5">
          <Card>
            <CardHeader title={t('bulk_import')||"Bulk import"} subtitle="Paste CSV for Tools, Employees, or Access records" />
            <CardBody>
              <div className="grid gap-3 md:grid-cols-3">
                <div className="md:col-span-1">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Entity type</div>
                  <Select value={kind} onChange={e => { setKind(e.target.value); setText(""); setImported(null); setValidated(false); setValidationErrors([]); }}>
                    <option value="tools">Tools</option>
                    <option value="employees">Employees</option>
                    <option value="access">Access Records</option>
                  </Select>
                </div>
                <div className="md:col-span-2 flex items-end justify-end gap-2">
                  <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); setValidated(false); }}>
                    <Download className="h-4 w-4" /> Paste template
                  </Button>
                  <Button variant="secondary" onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}>
                    <Download className="h-4 w-4" /> Download
                  </Button>
                </div>
              </div>
              <div className="mt-3">
                <Textarea rows={10} className="font-mono text-xs" value={text}
                  onChange={e => { setText(e.target.value); setImported(null); setValidated(false); setValidationErrors([]); }}
                  placeholder="Paste CSV here..." />
              </div>
              {liveRows.length>0&&(
                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs">
                  <span className="text-slate-400">{liveRows.length} row(s) detected</span>
                  {validCount>0&&<span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
                  {invalidCount>0&&<span className="text-rose-400 font-semibold">✗ {invalidCount} missing required fields</span>}
                </div>
              )}
              <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                <div className="flex gap-2">
                  <Button variant="secondary" disabled={!text.trim()||liveRows.length===0} onClick={runValidation}>
                    <Check className="h-4 w-4" /> Validate data
                  </Button>
                  <Button disabled={!text.trim()||validCount===0||importing||(validated&&validationErrors.length>0)} onClick={handleImport}>
                    {importing?<><RefreshCw className="h-4 w-4 animate-spin"/> Importing…</>:<><Upload className="h-4 w-4"/> Import {validCount>0?`${validCount} record${validCount>1?"s":""}`:"" }</>}
                  </Button>
                </div>
                <div className="text-xs text-slate-500">Validate before importing to catch errors.</div>
              </div>
            </CardBody>
          </Card>

          {/* Validation results */}
          {validated&&(
            <Card className={validationErrors.length>0?"border-rose-700/40":"border-emerald-700/40"}>
              <CardHeader
                title={validationErrors.length===0?"✅ Validation passed":`⚠ ${validationErrors.length} error${validationErrors.length!==1?"s":""}`}
                subtitle={validationErrors.length===0?"All rows look good. Safe to import.":"Fix these before importing — invalid rows will be skipped."}
              />
              {validationErrors.length>0&&(
                <CardBody>
                  <div className="space-y-2 max-h-56 overflow-y-auto">
                    {validationErrors.map((err,i)=>(
                      <div key={i} className={cx("flex items-start gap-3 rounded-xl px-3 py-2 text-sm",err.type==="missing"?"bg-rose-950/30 border border-rose-800/40":"bg-amber-950/30 border border-amber-800/40")}>
                        <AlertTriangle className={cx("h-4 w-4 flex-shrink-0 mt-0.5",err.type==="missing"?"text-rose-400":"text-amber-400")} />
                        <span className={err.type==="missing"?"text-rose-300":"text-amber-300"}>{err.msg}</span>
                      </div>
                    ))}
                  </div>
                </CardBody>
              )}
            </Card>
          )}

          {/* Preview table */}
          {liveRows.length>0&&!imported&&(
            <Card>
              <CardHeader title="Preview" subtitle={`${liveRows.length} row(s) parsed`}
                right={<div className="flex gap-2">{validCount>0&&<Pill tone="green">✓ {validCount} valid</Pill>}{invalidCount>0&&<Pill tone="rose">✗ {invalidCount} invalid</Pill>}</div>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                      <th className="px-3 py-2 text-slate-500 w-8">#</th>
                      {cols.map(c=><th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}{REQUIRED[kind].includes(c)?" *":""}</th>)}
                      <th className="px-3 py-2 text-slate-500">Status</th>
                    </tr></thead>
                    <tbody>
                      {liveRows.map((row,i)=>{
                        const valid=isRowValid(row);
                        const rowErrs=validationErrors.filter(e=>e.row===i+1);
                        return(
                          <tr key={i} className={cx("border-b border-slate-800/60",valid?"hover:bg-slate-800/30":"bg-rose-950/20")}>
                            <td className="px-3 py-2 text-slate-500">{i+1}</td>
                            {cols.map(c=>{
                              const hasErr=rowErrs.some(e=>e.field===c);
                              return <td key={c} className={cx("px-3 py-2 max-w-[110px] truncate",hasErr?"text-amber-400":!row[c]?.trim()&&REQUIRED[kind].includes(c)?"text-rose-400":"text-slate-300")}>{row[c]||<span className="text-slate-600 italic">—</span>}</td>;
                            })}
                            <td className="px-3 py-2">
                              {rowErrs.length>0?<span className="inline-flex items-center gap-1 text-amber-400"><AlertTriangle className="h-3 w-3"/>{rowErrs.length} err</span>:valid?<span className="inline-flex items-center gap-1 text-emerald-400"><Check className="h-3 w-3"/> OK</span>:<span className="inline-flex items-center gap-1 text-rose-400"><AlertTriangle className="h-3 w-3"/> Missing</span>}
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

          {/* Success view */}
          {imported&&(
            <Card>
              <CardHeader title={`✅ ${imported.count} ${imported.kind} imported`} subtitle="Records added to your workspace"
                right={<Button variant="secondary" size="sm" onClick={()=>setImported(null)}>Import more</Button>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                      <th className="px-3 py-2 text-slate-500 w-8">#</th>
                      {COLS[imported.kind].map(c=><th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">{c.replace(/_/g," ")}</th>)}
                      <th className="px-3 py-2 text-slate-500">Result</th>
                    </tr></thead>
                    <tbody>
                      {imported.rows.map((row,i)=>(
                        <tr key={i} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                          <td className="px-3 py-2 text-slate-500">{i+1}</td>
                          {COLS[imported.kind].map(c=><td key={c} className="px-3 py-2 text-slate-300 max-w-[110px] truncate">{row[c]||<span className="text-slate-600 italic">—</span>}</td>)}
                          <td className="px-3 py-2"><span className="inline-flex items-center gap-1 text-emerald-400 font-semibold"><CheckCircle className="h-3 w-3"/> Added</span></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="mt-4 flex gap-3">
                  <Button size="sm" onClick={() => { window.location.href=imported.kind==="employees"?"/employees":imported.kind==="access"?"/access":"/tools"; }}>
                    View in {imported.kind==="employees"?"Employees":imported.kind==="access"?"Access Control":"Tools"}
                  </Button>
                  <Button variant="secondary" size="sm" onClick={()=>setImported(null)}>Import more</Button>
                </div>
              </CardBody>
            </Card>
          )}
        </div>

        {/* RIGHT SIDEBAR */}
        <div className="lg:col-span-5 space-y-5">
          <Card>
            <CardHeader title="Format guidelines" subtitle="Required fields marked *" />
            <CardBody>
              <div className="space-y-3 text-sm">
                {[
                  {title:"Tools",lines:[`* name`,`category ∈ ${CATEGORIES.join(", ")}`,`status ∈ ${TOOL_STATUS.join(", ")}`,`criticality ∈ ${CRITICALITY.join(", ")}`]},
                  {title:"Employees",lines:[`* full_name, * email`,`department ∈ ${EMP_DEPARTMENTS.join(", ")}`,`status ∈ active, offboarding, offboarded`]},
                  {title:"Access Records",lines:[`* tool_name, * employee_email`,`access_level ∈ ${ACCESS_LEVEL.join(", ")}`,`risk_flag ∈ ${RISK_FLAG.join(", ")}`]},
                ].map(({title,lines})=>(
                  <div key={title} className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                    <div className="font-semibold text-white mb-2">{title}</div>
                    {lines.map((l,i)=><div key={i} className="text-xs text-slate-400 mt-1">{l}</div>)}
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="Current workspace" subtitle="Records already imported" />
            <CardBody>
              <div className="grid grid-cols-3 gap-3 text-center">
                {[
                  {label:"Tools",    count:db?.tools?.length??0,     color:"text-blue-400",   bg:"bg-blue-500/10"},
                  {label:"Employees",count:db?.employees?.length??0, color:"text-violet-400", bg:"bg-violet-500/10"},
                  {label:"Access",   count:db?.access?.length??0,    color:"text-emerald-400",bg:"bg-emerald-500/10"},
                ].map(({label,count,color,bg})=>(
                  <div key={label} className={cx("rounded-xl border border-slate-800 p-4",bg)}>
                    <div className={cx("text-3xl font-black",color)}>{count}</div>
                    <div className="text-xs text-slate-500 mt-1">{label}</div>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          {/* Import tips */}
          <Card>
            <CardHeader title="Import tips" subtitle="Get the best results" />
            <CardBody>
              <div className="space-y-3">
                {[
                  {icon:"📋",tip:"Always download the template first to ensure column order is correct."},
                  {icon:"✅",tip:"Run 'Validate data' before importing to catch typos and missing fields."},
                  {icon:"🔁",tip:"Duplicate names are auto-merged with existing records."},
                  {icon:"📅",tip:"Use ISO date format: YYYY-MM-DD (e.g. 2026-03-01)."},
                  {icon:"💡",tip:"Import employees first, then tools, then access records."},
                ].map(({icon,tip},i)=>(
                  <div key={i} className="flex items-start gap-3 text-sm">
                    <span className="text-lg flex-shrink-0">{icon}</span>
                    <span className="text-slate-400">{tip}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </div>
    </AppShell>
  );
}
"""

replace_fn('OffboardingPage', OFFBOARDING)
replace_fn('ImportPage', IMPORT_PAGE)

# ══ 4. ADD CONTRACT PAGE + NAV + ROUTE ════════════════════════
CONTRACT_PAGE = r"""
// ============================================================================
// CONTRACT COMPARISON + NEGOTIATION PAGE (AI-powered)
// ============================================================================
function ContractComparisonPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const [tab, setTab] = useState('negotiations');

  /* ── NEGOTIATIONS ── */
  const [negotiations, setNegotiations] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_negotiations')||'[]'); } catch { return []; }
  });
  const saveNeg = list => { localStorage.setItem('ag_negotiations',JSON.stringify(list)); setNegotiations(list); };
  const [showNegForm, setShowNegForm] = useState(false);
  const EMPTY_NEG = {id:null,customer:'',assignee:'',salesPerson:'',createDate:todayISO(),deadline:'',arr:'',status:'In Progress',currentWith:'With Our Legal Team',notes:''};
  const [negForm, setNegForm] = useState(EMPTY_NEG);
  const saveNegRecord = () => {
    if(!negForm.customer.trim()) return;
    saveNeg(negForm.id ? negotiations.map(n=>n.id===negForm.id?{...negForm}:n) : [{...negForm,id:`neg_${Date.now()}`},...negotiations]);
    setShowNegForm(false); setNegForm(EMPTY_NEG);
  };
  const revertNeg = id => {
    const n = negotiations.find(n=>n.id===id); if(!n) return;
    saveNeg([{...n,id:`neg_${Date.now()}`,status:'Reverted',currentWith:'Reverted to Vendor',notes:`Reverted on ${todayISO()}. ${n.notes||''}`.trim()},...negotiations]);
  };
  const STATUS_COLORS = {'In Progress':'bg-blue-500/20 text-blue-400','Waiting on Approval':'bg-amber-500/20 text-amber-400','Ready for Signing':'bg-emerald-500/20 text-emerald-400','Signed':'bg-teal-500/20 text-teal-400','Reverted':'bg-purple-500/20 text-purple-400','On Hold':'bg-slate-500/20 text-slate-400','Rejected':'bg-rose-500/20 text-rose-400'};
  const PIPELINE = ['With Our Legal Team','Waiting on Approval','Ready for Signing','With Customer','Final Review','Reverted to Vendor'];
  const daysLeft = d => d?Math.ceil((new Date(d)-new Date())/86400000):null;

  /* ── CONTRACTS ── */
  const [contracts, setContracts] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_contracts')||'[]'); } catch { return []; }
  });
  const saveContracts = list => { localStorage.setItem('ag_contracts',JSON.stringify(list)); setContracts(list); };
  const [compareIds, setCompareIds] = useState([]);
  const [showCForm, setShowCForm] = useState(false);
  const EMPTY_C = {id:null,vendor:'',tool:'',version:'current',startDate:'',endDate:'',value:'',terms:'',sla:'',autoRenew:false,notes:'',status:'active'};
  const [cForm, setCForm] = useState(EMPTY_C);
  const saveCRecord = () => {
    if(!cForm.vendor.trim()) return;
    saveContracts(cForm.id?contracts.map(c=>c.id===cForm.id?{...cForm}:c):[{...cForm,id:`c_${Date.now()}`},...contracts]);
    setShowCForm(false); setCForm(EMPTY_C);
  };
  const toggleCmp = id => setCompareIds(p=>p.includes(id)?p.filter(i=>i!==id):p.length<2?[...p,id]:[p[1],id]);
  const cmpPair = compareIds.map(id=>contracts.find(c=>c.id===id)).filter(Boolean);
  const CFIELDS = [
    {key:'vendor',label:'Vendor'},{key:'tool',label:'Tool'},{key:'version',label:'Version'},
    {key:'startDate',label:'Start'},{key:'endDate',label:'End'},{key:'value',label:'Value'},
    {key:'sla',label:'SLA'},{key:'autoRenew',label:'Auto-renew',render:v=>v?'Yes':'No'},
    {key:'terms',label:'Terms'},{key:'status',label:'Status'},{key:'notes',label:'Notes'},
  ];

  /* ── AI ── */
  const [doc1,setDoc1] = useState(''); const [doc2,setDoc2] = useState('');
  const [doc1Name,setDoc1Name] = useState(''); const [doc2Name,setDoc2Name] = useState('');
  const [aiResult,setAiResult] = useState(null);
  const [aiLoading,setAiLoading] = useState(false);
  const [aiError,setAiError] = useState('');
  const [chatMsgs,setChatMsgs] = useState([]);
  const [chatInput,setChatInput] = useState('');
  const [chatLoading,setChatLoading] = useState(false);

  const readFile = (file,setName,setContent) => {
    setName(file.name);
    const r=new FileReader(); r.onload=e=>setContent(e.target.result); r.readAsText(file);
  };

  const runAI = async () => {
    if(!doc1.trim()||!doc2.trim()) return;
    setAiLoading(true); setAiError(''); setAiResult(null);
    try {
      const resp = await fetch('https://api.anthropic.com/v1/messages',{
        method:'POST',headers:{'Content-Type':'application/json'},
        body:JSON.stringify({model:'claude-sonnet-4-20250514',max_tokens:1000,messages:[{role:'user',content:`You are a legal contract analyst. Compare these two contracts. Respond ONLY with valid JSON, no markdown fences:\n{"summary":"2-3 sentences","differences":[{"field":"field","doc1":"val","doc2":"val","severity":"high|medium|low","recommendation":"advice"}],"risks":["risk1"],"recommendations":["rec1"],"verdict":"one sentence verdict"}\n\nCONTRACT 1 (${doc1Name||'Doc 1'}):\n${doc1.slice(0,3000)}\n\nCONTRACT 2 (${doc2Name||'Doc 2'}):\n${doc2.slice(0,3000)}`}]})
      });
      const data=await resp.json();
      const text=data.content?.[0]?.text||'';
      const parsed=JSON.parse(text.replace(/```json|```/g,'').trim());
      setAiResult(parsed);
      setChatMsgs([{role:'assistant',content:`Analysis complete. ${parsed.summary} Ask me anything about the contracts.`}]);
    } catch(e) { setAiError('Could not analyse contracts. Ensure both documents contain readable text and try again.'); }
    finally { setAiLoading(false); }
  };

  const sendChat = async () => {
    if(!chatInput.trim()||chatLoading) return;
    const msg={role:'user',content:chatInput};
    const msgs=[...chatMsgs,msg]; setChatMsgs(msgs); setChatInput(''); setChatLoading(true);
    try {
      const ctx=aiResult?`Contract analysis: ${JSON.stringify(aiResult)}\nDoc1: ${doc1.slice(0,1500)}\nDoc2: ${doc2.slice(0,1500)}`:'No documents analysed yet.';
      const resp=await fetch('https://api.anthropic.com/v1/messages',{
        method:'POST',headers:{'Content-Type':'application/json'},
        body:JSON.stringify({model:'claude-sonnet-4-20250514',max_tokens:1000,system:`You are a contract negotiation advisor for SaaS companies. Be concise and actionable. ${ctx}`,messages:msgs.map(m=>({role:m.role,content:m.content}))})
      });
      const data=await resp.json();
      setChatMsgs(p=>[...p,{role:'assistant',content:data.content?.[0]?.text||'Sorry, I could not respond.'}]);
    } catch { setChatMsgs(p=>[...p,{role:'assistant',content:'Connection error. Please try again.'}]); }
    finally { setChatLoading(false); }
  };

  const sevColor = s => s==='high'?'bg-rose-500/20 text-rose-400 border-rose-500/30':s==='medium'?'bg-amber-500/20 text-amber-400 border-amber-500/30':'bg-slate-500/20 text-slate-400 border-slate-500/30';

  return (
    <AppShell title="Contracts"
      right={
        <div className="flex gap-2">
          {tab==='negotiations'&&<Button onClick={()=>{setNegForm(EMPTY_NEG);setShowNegForm(true)}}><Plus className="h-4 w-4"/> New negotiation</Button>}
          {tab==='compare'&&<Button variant="secondary" onClick={()=>{setCForm(EMPTY_C);setShowCForm(true)}}><Plus className="h-4 w-4"/> Add contract</Button>}
        </div>
      }
    >
      <div className="space-y-5">
        {/* Tabs */}
        <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
          {[{id:'negotiations',label:'📋 Negotiation Tracker'},{id:'compare',label:'⇄ Comparison'},{id:'ai',label:'🤖 AI Analysis'}].map(({id,label})=>(
            <button key={id} onClick={()=>setTab(id)} className={cx("px-4 py-2 rounded-lg text-sm font-medium transition-colors",tab===id?"bg-blue-600 text-white shadow":"text-slate-400 hover:text-slate-200")}>{label}</button>
          ))}
        </div>

        {/* ══ NEGOTIATIONS ══════════════════════════════════════ */}
        {tab==='negotiations'&&(
          <div className="space-y-5">
            {/* Stats */}
            <div className="grid gap-4 md:grid-cols-4">
              {[
                {label:'Total deals',value:negotiations.length,color:'text-white'},
                {label:'In Progress',value:negotiations.filter(n=>n.status==='In Progress').length,color:'text-blue-400'},
                {label:'Ready to Sign',value:negotiations.filter(n=>n.status==='Ready for Signing').length,color:'text-emerald-400'},
                {label:'Total ARR',value:'$'+negotiations.reduce((s,n)=>s+Number((n.arr||'0').replace(/[^0-9.]/g,'')),0).toLocaleString(),color:'text-amber-400'},
              ].map(({label,value,color})=>(
                <Card key={label}><CardBody>
                  <div className="text-xs font-semibold uppercase tracking-widest text-slate-500">{label}</div>
                  <div className={cx("text-3xl font-black mt-1",color)}>{value}</div>
                </CardBody></Card>
              ))}
            </div>

            {/* Form */}
            {showNegForm&&(
              <Card className="border-blue-600/30">
                <CardHeader title={negForm.id?'Edit negotiation':'New contract negotiation'} subtitle="Fill in deal details"
                  right={<Button variant="secondary" size="sm" onClick={()=>{setShowNegForm(false);setNegForm(EMPTY_NEG);}}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[
                      {key:'customer',label:'Customer *',type:'text',ph:'e.g. Acme Corp'},
                      {key:'assignee',label:'Assignee',type:'text',ph:'Team member'},
                      {key:'salesPerson',label:'Sales Person',type:'text',ph:'Sales rep'},
                      {key:'arr',label:'ARR of Contract',type:'text',ph:'$0.00'},
                      {key:'createDate',label:'Create Date',type:'date'},
                      {key:'deadline',label:'Deadline',type:'date'},
                    ].map(({key,label,type,ph})=>(
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type} value={negForm[key]} onChange={e=>setNegForm(f=>({...f,[key]:e.target.value}))} placeholder={ph||''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      </div>
                    ))}
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
                      <Select value={negForm.status} onChange={e=>setNegForm(f=>({...f,status:e.target.value}))}>
                        {Object.keys(STATUS_COLORS).map(s=><option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Currently With</div>
                      <Select value={negForm.currentWith} onChange={e=>setNegForm(f=>({...f,currentWith:e.target.value}))}>
                        {PIPELINE.map(s=><option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                      <Textarea rows={2} value={negForm.notes} onChange={e=>setNegForm(f=>({...f,notes:e.target.value}))} placeholder="Key clauses, outstanding issues, history…" />
                    </div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={()=>{setShowNegForm(false);setNegForm(EMPTY_NEG);}}>Cancel</Button>
                    <Button disabled={!negForm.customer.trim()} onClick={saveNegRecord}><Check className="h-4 w-4"/> {negForm.id?'Save':'Add negotiation'}</Button>
                  </div>
                </CardBody>
              </Card>
            )}

            {/* Table */}
            {negotiations.length===0?(
              <EmptyState icon={FileText} title="No negotiations yet" body="Track every deal from first draft to signing. Click 'New negotiation' to start." />
            ):(
              <Card>
                <CardHeader title="Contract Negotiation Tracker" subtitle="Track every deal from draft to close" />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                        {['Customer','Assignee','Create Date','Deadline','ARR','Currently With','Sales Person','Status','Actions'].map(h=>(
                          <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold whitespace-nowrap">{h}</th>
                        ))}
                      </tr></thead>
                      <tbody>
                        {negotiations.map(n=>{
                          const days=daysLeft(n.deadline);
                          return(
                            <tr key={n.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3"><div className="font-semibold text-blue-400 cursor-pointer hover:text-blue-300" onClick={()=>{setNegForm({...n});setShowNegForm(true);}}>{n.customer}</div></td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-2">
                                  <div className="h-7 w-7 rounded-full bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center text-xs font-bold text-white flex-shrink-0">{(n.assignee||'?').charAt(0).toUpperCase()}</div>
                                  <span className="text-slate-300 text-xs">{n.assignee||'—'}</span>
                                </div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 text-xs whitespace-nowrap">{n.createDate||'—'}</td>
                              <td className="px-4 py-3 whitespace-nowrap">
                                <div className="text-slate-300 text-xs">{n.deadline?new Date(n.deadline).toLocaleDateString('en-GB',{day:'2-digit',month:'short',year:'numeric'}):'—'}</div>
                                {days!==null&&<div className={cx("text-xs font-semibold",days<0?'text-rose-400':days<=7?'text-amber-400':'text-slate-500')}>{days<0?`${Math.abs(days)}d overdue`:days===0?'Today':`${days}d`}</div>}
                              </td>
                              <td className="px-4 py-3 font-semibold text-white">{n.arr||'—'}</td>
                              <td className="px-4 py-3"><span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap",n.currentWith==='Ready for Signing'?'bg-emerald-500/20 text-emerald-400':n.currentWith==='Waiting on Approval'?'bg-amber-500/20 text-amber-400':n.currentWith==='Reverted to Vendor'?'bg-purple-500/20 text-purple-400':'bg-slate-500/20 text-slate-400')}>{n.currentWith}</span></td>
                              <td className="px-4 py-3 text-slate-300">{n.salesPerson||'—'}</td>
                              <td className="px-4 py-3"><span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap",STATUS_COLORS[n.status]||'bg-slate-500/20 text-slate-400')}>{n.status}</span></td>
                              <td className="px-4 py-3">
                                <div className="flex gap-1">
                                  <Button size="sm" variant="secondary" onClick={()=>{setNegForm({...n});setShowNegForm(true);}}><Pencil className="h-3 w-3"/></Button>
                                  <Button size="sm" variant="secondary" onClick={()=>revertNeg(n.id)} title="Revert to vendor"><RefreshCw className="h-3 w-3"/></Button>
                                  <Button size="sm" variant="danger" onClick={()=>saveNeg(negotiations.filter(x=>x.id!==n.id))}><Trash2 className="h-3 w-3"/></Button>
                                </div>
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

            {/* Legal pipeline */}
            {negotiations.length>0&&(
              <Card>
                <CardHeader title="Legal Pipeline" subtitle="Deals by stage" />
                <CardBody>
                  <div className="grid gap-3 md:grid-cols-3 lg:grid-cols-6">
                    {PIPELINE.map(stage=>{
                      const deals=negotiations.filter(n=>n.currentWith===stage);
                      return(
                        <div key={stage} className="rounded-xl border border-slate-800 bg-slate-950/30 p-3">
                          <div className="text-xs font-semibold text-slate-400 mb-2 leading-tight">{stage}</div>
                          <div className="text-2xl font-black text-white">{deals.length}</div>
                          <div className="mt-2 space-y-1">{deals.slice(0,3).map(d=><div key={d.id} className="text-xs text-blue-400 truncate">{d.customer}</div>)}{deals.length>3&&<div className="text-xs text-slate-600">+{deals.length-3} more</div>}</div>
                        </div>
                      );
                    })}
                  </div>
                </CardBody>
              </Card>
            )}
          </div>
        )}

        {/* ══ COMPARISON ══════════════════════════════════════ */}
        {tab==='compare'&&(
          <div className="space-y-5">
            {showCForm&&(
              <Card className="border-blue-600/30">
                <CardHeader title={cForm.id?'Edit contract':'Add contract'}
                  right={<Button variant="secondary" size="sm" onClick={()=>{setShowCForm(false);setCForm(EMPTY_C);}}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[{key:'vendor',label:'Vendor *',ph:'e.g. Salesforce'},{key:'tool',label:'Tool *',ph:'e.g. Sales Cloud'},{key:'value',label:'Value',ph:'€12,000/year'},{key:'sla',label:'SLA',ph:'99.9% uptime'},{key:'startDate',label:'Start',type:'date'},{key:'endDate',label:'End',type:'date'}].map(({key,label,ph,type})=>(
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type||'text'} value={cForm[key]} onChange={e=>setCForm(f=>({...f,[key]:e.target.value}))} placeholder={ph||''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                      </div>
                    ))}
                    <div><div className="mb-1 text-xs font-semibold text-slate-400">Version</div><Select value={cForm.version} onChange={e=>setCForm(f=>({...f,version:e.target.value}))}>{['current','new','proposed','old','reverted'].map(v=><option key={v} value={v}>{v}</option>)}</Select></div>
                    <div><div className="mb-1 text-xs font-semibold text-slate-400">Status</div><Select value={cForm.status} onChange={e=>setCForm(f=>({...f,status:e.target.value}))}>{['active','draft','expired','negotiating','reverted'].map(v=><option key={v} value={v}>{v}</option>)}</Select></div>
                    <div className="flex items-center gap-2 mt-4"><input type="checkbox" id="ar" checked={cForm.autoRenew} onChange={e=>setCForm(f=>({...f,autoRenew:e.target.checked}))} className="h-4 w-4 accent-blue-500"/><label htmlFor="ar" className="text-sm text-slate-300">Auto-renews</label></div>
                    <div className="lg:col-span-3"><div className="mb-1 text-xs font-semibold text-slate-400">Key terms</div><Textarea rows={2} value={cForm.terms} onChange={e=>setCForm(f=>({...f,terms:e.target.value}))} placeholder="Key clauses, pricing, conditions…"/></div>
                    <div className="lg:col-span-3"><div className="mb-1 text-xs font-semibold text-slate-400">Notes</div><Textarea rows={2} value={cForm.notes} onChange={e=>setCForm(f=>({...f,notes:e.target.value}))} placeholder="Internal notes…"/></div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={()=>{setShowCForm(false);setCForm(EMPTY_C);}}>Cancel</Button>
                    <Button disabled={!cForm.vendor.trim()} onClick={saveCRecord}><Check className="h-4 w-4"/> {cForm.id?'Save':'Add'}</Button>
                  </div>
                </CardBody>
              </Card>
            )}
            {contracts.length===0?(
              <EmptyState icon={FileText} title="No contracts yet" body="Add contracts to compare them side-by-side. Click 'Add contract' to start." />
            ):(
              <Card>
                <CardHeader title="Select contracts to compare" subtitle="Check 2 contracts to see a side-by-side diff"
                  right={compareIds.length===2&&<Button size="sm"><ArrowLeftRight className="h-4 w-4"/> Compare selected</Button>}
                />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800 mb-5">
                    <table className="w-full text-sm">
                      <thead><tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-3 w-8"></th>
                        {['Vendor','Tool','Version','Value','Expires','Status',''].map(h=><th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold">{h}</th>)}
                      </tr></thead>
                      <tbody>
                        {contracts.map(c=>{
                          const sel=compareIds.includes(c.id);
                          const days=c.endDate?Math.ceil((new Date(c.endDate)-new Date())/86400000):null;
                          return(
                            <tr key={c.id} className={cx("border-b border-slate-800/50 transition-colors",sel?"bg-blue-600/10":"hover:bg-slate-800/30")}>
                              <td className="px-3 py-3 text-center"><input type="checkbox" checked={sel} onChange={()=>toggleCmp(c.id)} className="h-4 w-4 accent-blue-500"/></td>
                              <td className="px-4 py-3 font-semibold text-white">{c.vendor}</td>
                              <td className="px-4 py-3 text-slate-300">{c.tool}</td>
                              <td className="px-4 py-3"><span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",c.version==='current'?'bg-blue-500/20 text-blue-400':c.version==='new'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400')}>{c.version}</span></td>
                              <td className="px-4 py-3 text-slate-300">{c.value||'—'}</td>
                              <td className="px-4 py-3"><div className="text-slate-300 text-xs">{c.endDate||'—'}</div>{days!==null&&<div className={cx("text-xs font-semibold",days<0?'text-rose-400':days<=30?'text-amber-400':'text-slate-600')}>{days<0?`${Math.abs(days)}d over`:`${days}d`}</div>}</td>
                              <td className="px-4 py-3"><span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",c.status==='active'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400')}>{c.status}</span></td>
                              <td className="px-4 py-3"><div className="flex gap-1"><Button size="sm" variant="secondary" onClick={()=>{setCForm({...c});setShowCForm(true);}}><Pencil className="h-3 w-3"/></Button><Button size="sm" variant="danger" onClick={()=>{saveContracts(contracts.filter(x=>x.id!==c.id));setCompareIds(p=>p.filter(i=>i!==c.id));}}><Trash2 className="h-3 w-3"/></Button></div></td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                  {cmpPair.length===2&&(
                    <div className="space-y-4">
                      <div className="grid grid-cols-3 gap-4">
                        <div className="text-xs font-semibold text-slate-500 uppercase pt-3">Field</div>
                        {cmpPair.map((c,i)=>(
                          <div key={c.id} className={cx("rounded-xl border p-4",i===0?'border-blue-600/40':'border-emerald-600/40')}>
                            <div className="flex items-center gap-2"><span className={cx("h-3 w-3 rounded-full",i===0?'bg-blue-500':'bg-emerald-500')}/><span className="font-bold text-white">{c.vendor}</span></div>
                            <div className="text-xs text-slate-400 mt-1">{c.tool} · {c.version}</div>
                          </div>
                        ))}
                      </div>
                      {CFIELDS.map(({key,label,render})=>{
                        const vals=cmpPair.map(c=>render?render(c[key]):String(c[key]||''));
                        const diff=vals[0]!==vals[1];
                        return(
                          <div key={key} className={cx("grid grid-cols-3 gap-4 px-3 py-3 rounded-xl",diff?'bg-amber-500/10 border border-amber-500/20':'hover:bg-slate-800/20')}>
                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-400">{diff&&<span className="h-2 w-2 rounded-full bg-amber-400 flex-shrink-0"/>}{label}</div>
                            {vals.map((v,i)=><div key={i} className={cx("text-sm break-words",diff?(i===0?'text-blue-300':'text-emerald-300'):'text-slate-300')}>{v||<span className="text-slate-600 italic">—</span>}</div>)}
                          </div>
                        );
                      })}
                      {(()=>{
                        const diffs=CFIELDS.filter(({key,render})=>{const vs=cmpPair.map(c=>render?render(c[key]):String(c[key]||''));return vs[0]!==vs[1];});
                        return(
                          <div className={cx("rounded-xl border p-4",diffs.length?'border-amber-500/30':'border-emerald-500/30')}>
                            <div className="font-semibold text-white mb-2">{diffs.length} difference{diffs.length!==1?'s':''} found</div>
                            {diffs.length>0?<div className="flex flex-wrap gap-2">{diffs.map(({label})=><span key={label} className="px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-400">{label}</span>)}</div>:<div className="text-emerald-400 text-sm">Contracts are identical.</div>}
                            <div className="mt-4 flex gap-2">{cmpPair.map(c=><Button key={c.id} size="sm" variant="secondary" onClick={()=>saveContracts([{...c,id:`c_${Date.now()}`,version:'reverted',status:'reverted',notes:`Reverted on ${todayISO()}`},...contracts])}><RefreshCw className="h-3 w-3"/> Revert to "{c.vendor} {c.version}"</Button>)}</div>
                          </div>
                        );
                      })()}
                    </div>
                  )}
                </CardBody>
              </Card>
            )}
          </div>
        )}

        {/* ══ AI ANALYSIS ══════════════════════════════════════ */}
        {tab==='ai'&&(
          <div className="space-y-5">
            <div className="grid gap-5 md:grid-cols-2">
              {[{label:'Contract 1',name:doc1Name,setName:setDoc1Name,setContent:setDoc1,content:doc1},{label:'Contract 2',name:doc2Name,setName:setDoc2Name,setContent:setDoc2,content:doc2}].map(({label,name,setName,setContent,content})=>(
                <Card key={label} className={content?'border-blue-600/30':''}>
                  <CardBody>
                    <div className="text-sm font-semibold text-slate-400 mb-3">{label}</div>
                    {name?(
                      <div className="flex items-center gap-3 p-3 rounded-xl border border-slate-700 bg-slate-900/40 mb-3">
                        <FileText className="h-8 w-8 text-blue-400 flex-shrink-0"/>
                        <div className="min-w-0 flex-1"><div className="font-medium text-white text-sm truncate">{name}</div><div className="text-xs text-slate-500">{content.length.toLocaleString()} chars</div></div>
                        <Button size="sm" variant="secondary" onClick={()=>{setName('');setContent('');}}><X className="h-3 w-3"/></Button>
                      </div>
                    ):(
                      <label className="flex flex-col items-center justify-center h-28 rounded-xl border-2 border-dashed border-slate-700 hover:border-blue-500 transition-colors cursor-pointer bg-slate-900/20 mb-3">
                        <Upload className="h-7 w-7 text-slate-500 mb-1"/>
                        <span className="text-sm text-slate-400">Click to upload .txt or .md</span>
                        <span className="text-xs text-slate-600 mt-0.5">or paste text below</span>
                        <input type="file" className="hidden" accept=".txt,.md,.csv" onChange={e=>e.target.files?.[0]&&readFile(e.target.files[0],setName,setContent)}/>
                      </label>
                    )}
                    <Textarea rows={5} value={content} onChange={e=>{setContent(e.target.value);if(!name)setName('Pasted text');}} placeholder={`Paste ${label.toLowerCase()} text here…`} className="font-mono text-xs"/>
                  </CardBody>
                </Card>
              ))}
            </div>

            <div className="flex justify-center">
              <Button disabled={!doc1.trim()||!doc2.trim()||aiLoading} onClick={runAI} className="px-8">
                {aiLoading?<><RefreshCw className="h-4 w-4 animate-spin"/> Analysing contracts…</>:<><Sparkles className="h-4 w-4"/> Generate AI Comparison</>}
              </Button>
            </div>

            {aiError&&<div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4 text-rose-400 text-sm">{aiError}</div>}

            {aiResult&&(
              <div className="space-y-5">
                <Card className="border-blue-600/30">
                  <CardBody>
                    <div className="flex items-start gap-3">
                      <Sparkles className="h-6 w-6 text-blue-400 flex-shrink-0 mt-0.5"/>
                      <div><div className="text-xs font-semibold uppercase tracking-widest text-blue-400 mb-1">AI Verdict</div><div className="text-white font-semibold">{aiResult.verdict}</div><div className="text-slate-400 text-sm mt-1">{aiResult.summary}</div></div>
                    </div>
                  </CardBody>
                </Card>

                <div className="grid gap-5 lg:grid-cols-2">
                  <Card>
                    <CardHeader title={`${aiResult.differences?.length||0} Differences`} subtitle="Field-by-field comparison"/>
                    <CardBody>
                      <div className="space-y-3">
                        {(aiResult.differences||[]).map((d,i)=>(
                          <div key={i} className={cx("rounded-xl border p-3",sevColor(d.severity))}>
                            <div className="flex items-center justify-between mb-2"><span className="font-semibold text-sm text-white">{d.field}</span><span className={cx("px-2 py-0.5 rounded-full text-xs font-bold border",sevColor(d.severity))}>{d.severity}</span></div>
                            <div className="grid grid-cols-2 gap-3 text-xs mb-2">
                              <div><div className="text-blue-400 font-semibold mb-1">{doc1Name||'Doc 1'}</div><div className="text-slate-300">{d.doc1||'—'}</div></div>
                              <div><div className="text-emerald-400 font-semibold mb-1">{doc2Name||'Doc 2'}</div><div className="text-slate-300">{d.doc2||'—'}</div></div>
                            </div>
                            {d.recommendation&&<div className="text-xs text-slate-400 border-t border-slate-700 pt-2">💡 {d.recommendation}</div>}
                          </div>
                        ))}
                      </div>
                    </CardBody>
                  </Card>
                  <div className="space-y-5">
                    <Card>
                      <CardHeader title="Risks Identified"/>
                      <CardBody><div className="space-y-2">{(aiResult.risks||[]).map((r,i)=><div key={i} className="flex items-start gap-2 text-sm"><AlertTriangle className="h-4 w-4 text-amber-400 flex-shrink-0 mt-0.5"/><span className="text-slate-300">{r}</span></div>)}</div></CardBody>
                    </Card>
                    <Card>
                      <CardHeader title="Recommendations"/>
                      <CardBody><div className="space-y-2">{(aiResult.recommendations||[]).map((r,i)=><div key={i} className="flex items-start gap-2 text-sm"><CheckCircle className="h-4 w-4 text-emerald-400 flex-shrink-0 mt-0.5"/><span className="text-slate-300">{r}</span></div>)}</div></CardBody>
                    </Card>
                  </div>
                </div>

                <Card>
                  <CardHeader title="Ask the AI" subtitle="Follow-up questions about the contracts" right={<Pill tone="blue" icon={Sparkles}>AI Advisor</Pill>}/>
                  <CardBody>
                    <div className="space-y-3 max-h-72 overflow-y-auto mb-4 pr-1">
                      {chatMsgs.map((m,i)=>(
                        <div key={i} className={cx("flex gap-3",m.role==='user'?"flex-row-reverse":"")}>
                          <div className={cx("h-7 w-7 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-bold",m.role==='user'?"bg-blue-600 text-white":"bg-slate-700 text-slate-300")}>{m.role==='user'?'U':'AI'}</div>
                          <div className={cx("rounded-2xl px-4 py-3 text-sm max-w-[80%]",m.role==='user'?"bg-blue-600/20 text-white":"bg-slate-800 text-slate-200")}>{m.content}</div>
                        </div>
                      ))}
                      {chatLoading&&<div className="flex gap-3"><div className="h-7 w-7 rounded-full bg-slate-700 flex items-center justify-center text-xs text-slate-300">AI</div><div className="rounded-2xl px-4 py-3 bg-slate-800 text-slate-400 text-sm"><RefreshCw className="h-4 w-4 animate-spin inline"/></div></div>}
                    </div>
                    <div className="flex gap-2">
                      <input value={chatInput} onChange={e=>setChatInput(e.target.value)} onKeyDown={e=>e.key==='Enter'&&!e.shiftKey&&sendChat()}
                        placeholder="Ask about clauses, risks, negotiation tactics…"
                        className="flex-1 rounded-xl border border-slate-700 bg-slate-900 px-4 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"/>
                      <Button disabled={!chatInput.trim()||chatLoading} onClick={sendChat}><Send className="h-4 w-4"/></Button>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {['Which contract has better SLA?','What should I negotiate?','What are the biggest risks?','Which is better value?'].map(q=>(
                        <button key={q} onClick={()=>setChatInput(q)} className="text-xs px-3 py-1 rounded-full border border-slate-700 text-slate-400 hover:border-blue-500 hover:text-blue-400 transition-colors">{q}</button>
                      ))}
                    </div>
                  </CardBody>
                </Card>
              </div>
            )}
          </div>
        )}
      </div>
    </AppShell>
  );
}

"""

# Insert before export default
ed = app.find('export default function App()')
if ed != -1:
    app = app[:ed] + CONTRACT_PAGE + app[ed:]
    ok.append("ContractComparisonPage: injected")

# Add to NAV
old_nav = '  { to: "/invoices", label: "invoices", icon: Upload },\n];'
new_nav = '  { to: "/invoices", label: "invoices", icon: Upload },\n  { separator: true, label: "Contracts" },\n  { to: "/contracts", label: "contracts", icon: FileText },\n];'
if '{ to: "/contracts"' not in app and old_nav in app:
    app = app.replace(old_nav, new_nav, 1); ok.append("NAV: /contracts added")
elif '{ to: "/contracts"' in app: ok.append("NAV: already present")

# Add route
if '<ContractComparisonPage />' not in app:
    app = app.replace(
        '          <Route path="*" element={<NotFound />} />',
        '          <Route path="/contracts" element={<RequireAuth><ContractComparisonPage /></RequireAuth>} />\n          <Route path="*" element={<NotFound />} />'
    ); ok.append("Route: /contracts added")

# ══ 5. FIX LanguageProvider — remove redundant dispatch ══════
old_lp = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: lang }));\n"
    "  }, []);\n"
)
new_lp = (
    "  const setAndPersist = React.useCallback((lang) => {\n"
    "    localStorage.setItem('language', lang);\n"
    "    setLanguage(lang);\n"
    "  }, []);\n"
)
if old_lp in app:
    app = app.replace(old_lp, new_lp, 1); ok.append("LanguageProvider: removed redundant event dispatch")

print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

python3 - << 'PYEOF'
import os, re
path='src/translations.js'
if not os.path.exists(path): exit()
with open(path,encoding='utf-8') as f: src=f.read()
for lang,val in {'en':'Contracts','es':'Contratos','fr':'Contrats','de':'Verträge','ja':'契約管理'}.items():
    ls=src.find(f'{lang}: {{'); le=src.find('\n  },',ls)
    if '    contracts:' not in src[ls:le]:
        ins=src.find('\n',src.find(f'{lang}: {{'))+1
        src=src[:ins]+f"    contracts: '{val}',\n"+src[ins:]
        print(f"  \033[32m✓\033[0m  {lang}: contracts key")
with open(path,'w',encoding='utf-8') as f: f.write(src)
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ All upgrades deployed!                                ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  FIXES                                                   ║"
echo -e "║    ✓ Paperclip/ArrowLeftRight icon crash fixed          ║"
echo -e "║    ✓ Stack overflow — all stale listeners removed       ║"
echo -e "║  OFFBOARDING — 3 tabs, dept breakdown, risk alert       ║"
echo -e "║  IMPORT — tips panel, bigger workspace stats, validate  ║"
echo -e "║  CONTRACTS — Negotiation tracker + AI analysis          ║"
echo -e "║    ✓ Add negotiation button works                       ║"
echo -e "║    ✓ Upload .txt/.md files for AI comparison            ║"
echo -e "║    ✓ AI chat with suggested prompts                     ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
