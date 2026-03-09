#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Page Upgrades (Offboarding/Audit/     ║"
echo -e "║  Billing/Import)                                         ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1

TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

def replace_fn(name, new_code):
    idx = app.find(f'function {name}()')
    if idx == -1:
        print(f"  ✗  {name}: not found")
        return False
    end = app.find('\nfunction ', idx + 10)
    if end == -1:
        end = app.find('\nexport ', idx + 10)
    return idx, end

def do_replace(name, new_code):
    global app
    result = replace_fn(name, new_code)
    if result is False: return
    idx, end = result
    app = app[:idx] + new_code + app[end:]
    print(f"  ✓  {name}: replaced")

# ══════════════════════════════════════════════════════════════
# 1. OFFBOARDING PAGE
# ══════════════════════════════════════════════════════════════
OFFBOARDING = r'''function OffboardingPage() {
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

  const [tab, setTab] = useState("queue"); // "queue" | "history"
  const [employeeId, setEmployeeId] = useState(pre || employees[0]?.id || "");

  useEffect(() => {
    if (!employeeId && employees[0]?.id) setEmployeeId(employees[0].id);
  }, [employeeId, employees]);

  const employee = employees.find((e) => e.id === employeeId);
  const activeRecords = access.filter((a) => a.employee_id === employeeId && a.status === "active");
  const [checked, setChecked] = useState({});

  const revokeOne = (id) => muts.updateAccess.mutate({ id, patch: { status: "revoked" } });
  const revokeAll = () => {
    activeRecords.forEach((r) => revokeOne(r.id));
    muts.updateEmployee.mutate({
      id: employeeId,
      patch: { status: "offboarded", end_date: employee?.end_date || todayISO() },
    });
  };

  // "Next to be offboarded" — employees with offboarding status or end_date coming up
  const upcoming = useMemo(() => {
    if (!db) return [];
    return db.employees
      .filter((e) => e.status === "offboarding" || (e.end_date && e.end_date >= todayISO() && e.status !== "offboarded"))
      .sort((a, b) => (a.end_date || "9999") > (b.end_date || "9999") ? 1 : -1)
      .slice(0, 5);
  }, [db]);

  // Offboarded employees — history
  const offboarded = useMemo(() => {
    if (!db) return [];
    return db.employees
      .filter((e) => e.status === "offboarded")
      .sort((a, b) => (a.end_date || "") < (b.end_date || "") ? 1 : -1);
  }, [db]);

  const daysUntil = (dateStr) => {
    if (!dateStr) return null;
    const diff = Math.ceil((new Date(dateStr) - new Date()) / 86400000);
    return diff;
  };

  return (
    <AppShell
      title={t('offboarding') || 'Offboarding'}
      right={
        <div className="flex gap-2">
          <Button variant="secondary" onClick={() => nav("/employees")}>
            <Users className="h-4 w-4" /> Employees
          </Button>
        </div>
      }
    >
      <div className="grid gap-5 lg:grid-cols-12">

        {/* LEFT: upcoming queue + revoke panel */}
        <div className="lg:col-span-8 space-y-5">

          {/* Tab bar */}
          <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
            {[
              { id: "queue",   label: "Offboarding Queue" },
              { id: "history", label: "Offboarded History" },
            ].map(({ id, label }) => (
              <button
                key={id}
                onClick={() => setTab(id)}
                className={cx(
                  "px-4 py-2 rounded-lg text-sm font-medium transition-colors",
                  tab === id
                    ? "bg-blue-600 text-white shadow"
                    : "text-slate-400 hover:text-slate-200"
                )}
              >
                {label}
              </button>
            ))}
          </div>

          {tab === "queue" && (
            <Card>
              <CardHeader
                title="Next to be offboarded"
                subtitle="Employees with upcoming end dates or offboarding status"
              />
              <CardBody>
                {isLoading || !db ? (
                  <SkeletonRow cols={5} />
                ) : upcoming.length === 0 ? (
                  <EmptyState icon={UserMinus} title="No upcoming offboardings" body="No employees flagged for offboarding." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Employee</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Department</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">End Date</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Days Left</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Status</th>
                          <th className="px-4 py-3 text-right text-slate-400 font-semibold">Action</th>
                        </tr>
                      </thead>
                      <tbody>
                        {upcoming.map((e) => {
                          const days = daysUntil(e.end_date);
                          const urgent = days !== null && days <= 3;
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-medium text-white">{e.full_name}</div>
                                <div className="text-xs text-slate-500">{e.email}</div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department || "—"}</td>
                              <td className="px-4 py-3 text-slate-300">{e.end_date || "—"}</td>
                              <td className="px-4 py-3">
                                {days !== null ? (
                                  <span className={cx(
                                    "inline-flex items-center gap-1 text-xs font-semibold px-2 py-1 rounded-full",
                                    urgent ? "bg-rose-500/20 text-rose-400" : days <= 7 ? "bg-amber-500/20 text-amber-400" : "bg-slate-700 text-slate-300"
                                  )}>
                                    {days === 0 ? "Today" : days < 0 ? `${Math.abs(days)}d overdue` : `${days}d`}
                                  </span>
                                ) : "—"}
                              </td>
                              <td className="px-4 py-3">
                                <span className={cx(
                                  "inline-flex items-center px-2 py-1 rounded-full text-xs font-semibold",
                                  e.status === "offboarding" ? "bg-amber-500/20 text-amber-400" : "bg-blue-500/20 text-blue-400"
                                )}>
                                  {e.status}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-right">
                                <Button size="sm" variant="secondary" onClick={() => { setEmployeeId(e.id); setTab("revoke"); }}>
                                  Revoke access
                                </Button>
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

          {tab === "history" && (
            <Card>
              <CardHeader
                title="Offboarded employees"
                subtitle="Complete history with timestamps"
                right={<Pill tone="slate">{offboarded.length} total</Pill>}
              />
              <CardBody>
                {isLoading || !db ? (
                  <SkeletonRow cols={5} />
                ) : offboarded.length === 0 ? (
                  <EmptyState icon={UserMinus} title="No offboarded employees" body="Employees you offboard will appear here." />
                ) : (
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Employee</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Department</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Role</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Date offboarded</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Access revoked</th>
                        </tr>
                      </thead>
                      <tbody>
                        {offboarded.map((e) => {
                          const revokedCount = access.filter(a => a.employee_id === e.id && a.status === "revoked").length;
                          const remainingCount = access.filter(a => a.employee_id === e.id && a.status === "active").length;
                          return (
                            <tr key={e.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-medium text-white">{e.full_name}</div>
                                <div className="text-xs text-slate-500">{e.email}</div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 capitalize">{e.department || "—"}</td>
                              <td className="px-4 py-3 text-slate-400">{e.role || "—"}</td>
                              <td className="px-4 py-3">
                                <div className="text-slate-300">{e.end_date || "—"}</div>
                                {e.end_date && (
                                  <div className="text-xs text-slate-500">
                                    {new Date(e.end_date).toLocaleDateString(language, { weekday: "short", year: "numeric", month: "short", day: "numeric" })}
                                  </div>
                                )}
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-2">
                                  {revokedCount > 0 && (
                                    <span className="text-xs text-emerald-400 font-semibold">{revokedCount} revoked</span>
                                  )}
                                  {remainingCount > 0 && (
                                    <span className="text-xs text-rose-400 font-semibold">{remainingCount} still active ⚠️</span>
                                  )}
                                  {revokedCount === 0 && remainingCount === 0 && (
                                    <span className="text-xs text-slate-500">No records</span>
                                  )}
                                </div>
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

          {/* Revoke panel — always visible below tabs */}
          <Card>
            <CardHeader title={t('revoke_access') || "Revoke access"} subtitle="Select employee and revoke active access" />
            <CardBody>
              {isLoading || !db ? (
                <SkeletonRow cols={6} />
              ) : (
                <div className="grid gap-5">
                  <div className="grid gap-3 md:grid-cols-2">
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Select employee</div>
                      <Select value={employeeId} onChange={(e) => setEmployeeId(e.target.value)}>
                        {employees.map((e) => (
                          <option key={e.id} value={e.id}>
                            {e.full_name} — {e.status}
                          </option>
                        ))}
                      </Select>
                    </div>
                    <div className="flex items-end justify-end gap-2">
                      <Button variant="danger" disabled={!activeRecords.length} onClick={revokeAll}>
                        <BadgeX className="h-4 w-4" /> Revoke All ({activeRecords.length})
                      </Button>
                    </div>
                  </div>
                  {activeRecords.length ? (
                    <div className="grid gap-2">
                      {activeRecords.map((r) => (
                        <div key={r.id} className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                          <div className="min-w-0">
                            <div className="text-sm font-semibold">{r.tool_name}</div>
                            <div className="mt-2 flex flex-wrap gap-2">
                              <AccessLevelBadge level={r.access_level} />
                              <Pill tone="slate" icon={CalendarClock}>Granted: {r.granted_date || "—"}</Pill>
                            </div>
                          </div>
                          <div className="flex items-center gap-2">
                            <label className="flex items-center gap-2 text-xs text-slate-400">
                              <input type="checkbox" checked={Boolean(checked[r.id])}
                                onChange={(e) => setChecked((m) => ({ ...m, [r.id]: e.target.checked }))} />
                              Verified
                            </label>
                            <Button size="sm" variant="danger" onClick={() => revokeOne(r.id)}>
                              <BadgeX className="h-4 w-4" /> Revoke
                            </Button>
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <EmptyState icon={UserMinus} title="No active access" body="This employee has no active access records." />
                  )}
                </div>
              )}
            </CardBody>
          </Card>
        </div>

        {/* RIGHT: summary stats */}
        <div className="lg:col-span-4 space-y-5">
          <Card>
            <CardHeader title="Summary" subtitle="Offboarding overview" />
            <CardBody>
              <div className="space-y-3">
                {[
                  { label: "Pending offboarding",  value: upcoming.length,                          color: "text-amber-400"  },
                  { label: "Offboarded total",      value: offboarded.length,                        color: "text-slate-300"  },
                  { label: "Active employees",      value: employees.filter(e => e.status === "active").length, color: "text-emerald-400" },
                  { label: "Access records at risk",value: access.filter(a => {
                      const emp = employees.find(e => e.id === a.employee_id);
                      return emp?.status === "offboarded" && a.status === "active";
                    }).length,                                                                        color: "text-rose-400"   },
                ].map(({ label, value, color }) => (
                  <div key={label} className="flex items-center justify-between rounded-xl border border-slate-800 bg-slate-950/30 px-4 py-3">
                    <span className="text-sm text-slate-400">{label}</span>
                    <span className={cx("text-lg font-bold", color)}>{value}</span>
                  </div>
                ))}
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="Offboarding checklist" subtitle="Best practices" />
            <CardBody>
              <div className="space-y-2 text-sm text-slate-400">
                {[
                  "Revoke all SaaS tool access",
                  "Remove from SSO / identity provider",
                  "Transfer ownership of shared docs",
                  "Recover company devices",
                  "Archive or reassign email",
                  "Remove from Slack / Teams",
                  "Cancel user-specific subscriptions",
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-2">
                    <div className="mt-0.5 h-4 w-4 rounded border border-slate-600 flex-shrink-0" />
                    <span>{item}</span>
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
'''

# ══════════════════════════════════════════════════════════════
# 2. AUDIT EXPORT PAGE
# ══════════════════════════════════════════════════════════════
AUDIT = r'''function AuditExportPage() {
  const { data: db, isLoading } = useDbQuery();
  const { language } = useLang();
  const t = useTranslation(language);

  const derived = useMemo(() => {
    if (!db) return null;
    const tools = db.tools.map((tool) => ({
      ...tool,
      derived_status: computeToolDerivedStatus(tool),
      derived_risk: computeToolDerivedRisk(tool),
    }));
    const employeesById = Object.fromEntries(db.employees.map((e) => [e.id, e]));
    const toolsById     = Object.fromEntries(tools.map((t) => [t.id, t]));
    const access = db.access.map((a) => ({
      ...a,
      derived_risk_flag: computeAccessDerivedRiskFlag(a, employeesById, toolsById),
    }));

    // App health
    const activeTools    = tools.filter(t => t.derived_status === "active").length;
    const unusedTools    = tools.filter(t => t.derived_status === "unused" || t.derived_status === "orphaned").length;
    const highRiskCount  = tools.filter(t => t.derived_risk === "high").length;
    const formerEmpAccess = access.filter(a => a.derived_risk_flag === "former_employee").length;
    const spend          = tools.reduce((s, t) => s + Number(t.cost_per_month || 0), 0);

    // Login / usage stats — tools with recent last_used_date
    const now = new Date();
    const toolsWithLogins = tools.filter(t => {
      if (!t.last_used_date) return false;
      const d = new Date(t.last_used_date);
      return (now - d) / (1000 * 60 * 60 * 24) <= 30;
    }).length;

    // Per-tool user count from access records
    const toolUserCount = {};
    db.access.filter(a => a.status === "active").forEach(a => {
      toolUserCount[a.tool_name] = (toolUserCount[a.tool_name] || 0) + 1;
    });
    const topToolsByUsers = Object.entries(toolUserCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);

    return {
      tools, access, employees: db.employees,
      activeTools, unusedTools, highRiskCount, formerEmpAccess, spend,
      toolsWithLogins, topToolsByUsers,
      healthScore: Math.round(Math.max(0, 100 - (highRiskCount * 10) - (formerEmpAccess * 5) - (unusedTools * 3))),
    };
  }, [db]);

  const exportTools = () => {
    if (!derived) return;
    downloadText(`tools_${todayISO()}.csv`, toCsv(derived.tools,
      ["name","category","owner_email","owner_name","criticality","url","description","derived_status","last_used_date","cost_per_month","derived_risk","notes"]
    ));
  };
  const exportEmployees = () => {
    if (!derived) return;
    downloadText(`employees_${todayISO()}.csv`, toCsv(derived.employees,
      ["full_name","email","department","role","status","start_date","end_date"]
    ));
  };
  const exportAccess = () => {
    if (!derived) return;
    downloadText(`access_${todayISO()}.csv`, toCsv(derived.access,
      ["tool_name","employee_name","employee_email","access_level","granted_date","last_accessed_date","last_reviewed_date","status","derived_risk_flag"]
    ));
  };
  const exportAll = () => { exportTools(); exportEmployees(); exportAccess(); };

  const healthColor = (score) =>
    score >= 80 ? "text-emerald-400" : score >= 60 ? "text-amber-400" : "text-rose-400";
  const healthLabel = (score) =>
    score >= 80 ? "Healthy" : score >= 60 ? "Needs attention" : "At risk";

  return (
    <AppShell
      title={t('export_audit') || 'Audit Export'}
      right={
        <Button onClick={exportAll}>
          <Download className="h-4 w-4" /> Full Audit Package
        </Button>
      }
    >
      <div className="grid gap-5">

        {/* Health + summary row */}
        <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-4">
          <Card className="lg:col-span-1">
            <CardBody>
              <div className="flex flex-col items-center justify-center py-4 text-center">
                <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-2">App Health Score</div>
                {isLoading || !derived ? (
                  <div className="h-16 w-16 rounded-full border-4 border-slate-700 animate-pulse" />
                ) : (
                  <>
                    <div className={cx("text-5xl font-black", healthColor(derived.healthScore))}>
                      {derived.healthScore}
                    </div>
                    <div className={cx("text-sm font-semibold mt-1", healthColor(derived.healthScore))}>
                      {healthLabel(derived.healthScore)}
                    </div>
                    <div className="mt-3 w-full bg-slate-800 rounded-full h-2">
                      <div
                        className={cx("h-2 rounded-full transition-all", derived.healthScore >= 80 ? "bg-emerald-500" : derived.healthScore >= 60 ? "bg-amber-500" : "bg-rose-500")}
                        style={{ width: `${derived.healthScore}%` }}
                      />
                    </div>
                  </>
                )}
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">Tool inventory</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">Total tools</span><span className="font-bold text-white">{derived?.tools.length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Active</span><span className="font-bold text-emerald-400">{derived?.activeTools ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Unused / orphaned</span><span className="font-bold text-amber-400">{derived?.unusedTools ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">High risk</span><span className="font-bold text-rose-400">{derived?.highRiskCount ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Active last 30d</span><span className="font-bold text-blue-400">{derived?.toolsWithLogins ?? "—"}</span></div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">Access risk</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">Total access records</span><span className="font-bold text-white">{derived?.access.length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Active</span><span className="font-bold text-emerald-400">{derived?.access.filter(a => a.status === "active").length ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Former employee access</span><span className="font-bold text-rose-400">{derived?.formerEmpAccess ?? "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Employees</span><span className="font-bold text-slate-300">{derived?.employees.length ?? "—"}</span></div>
              </div>
            </CardBody>
          </Card>
          <Card>
            <CardBody>
              <div className="text-xs font-semibold uppercase tracking-widest text-slate-500 mb-3">Spend</div>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="text-slate-400">Monthly total</span><span className="font-bold text-white">{derived ? formatMoney(derived.spend) : "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Annual projection</span><span className="font-bold text-blue-400">{derived ? formatMoney(derived.spend * 12) : "—"}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Avg per tool</span><span className="font-bold text-slate-300">{derived && derived.tools.length ? formatMoney(derived.spend / derived.tools.length) : "—"}</span></div>
              </div>
            </CardBody>
          </Card>
        </div>

        <div className="grid gap-5 lg:grid-cols-2">
          {/* Tool login / user counts */}
          <Card>
            <CardHeader title="Users logged into tools" subtitle="Active access records per tool" />
            <CardBody>
              {isLoading || !derived ? <SkeletonRow cols={3} /> : derived.topToolsByUsers.length === 0 ? (
                <EmptyState icon={Users} title="No access data" body="Import access records to see tool usage." />
              ) : (
                <div className="space-y-3">
                  {derived.topToolsByUsers.map(([toolName, count]) => {
                    const pct = Math.round((count / derived.employees.length) * 100);
                    return (
                      <div key={toolName}>
                        <div className="flex items-center justify-between mb-1 text-sm">
                          <span className="text-slate-300 font-medium">{toolName}</span>
                          <span className="text-slate-400">{count} user{count !== 1 ? "s" : ""} <span className="text-slate-600">({pct}%)</span></span>
                        </div>
                        <div className="h-2 w-full rounded-full bg-slate-800">
                          <div className="h-2 rounded-full bg-blue-500 transition-all" style={{ width: `${Math.min(pct, 100)}%` }} />
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardBody>
          </Card>

          {/* Export buttons */}
          <Card>
            <CardHeader title="Export reports" subtitle="Timestamped CSV files" />
            <CardBody>
              <div className="space-y-3">
                {[
                  { label: "Tools report", sub: "Inventory, ownership, status, risk, spend", fn: exportTools, count: derived?.tools.length },
                  { label: "Employees report", sub: "Directory with department, role, dates, status", fn: exportEmployees, count: derived?.employees.length },
                  { label: "Access report", sub: "Tool-to-employee mappings and risk flags", fn: exportAccess, count: derived?.access.length },
                ].map(({ label, sub, fn, count }) => (
                  <div key={label} className="flex items-center justify-between rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                    <div>
                      <div className="text-sm font-semibold text-white">{label}</div>
                      <div className="text-xs text-slate-500 mt-0.5">{sub}</div>
                      {count !== undefined && <div className="text-xs text-slate-600 mt-0.5">{count} records</div>}
                    </div>
                    <Button size="sm" variant="secondary" onClick={fn}>
                      <Download className="h-4 w-4" /> Export
                    </Button>
                  </div>
                ))}
                <div className="rounded-2xl border border-blue-600/30 bg-blue-600/10 p-4 flex items-center justify-between">
                  <div>
                    <div className="text-sm font-semibold text-white">Full audit package</div>
                    <div className="text-xs text-slate-500 mt-0.5">All three reports at once</div>
                  </div>
                  <Button size="sm" onClick={exportAll}>
                    <Download className="h-4 w-4" /> Export all
                  </Button>
                </div>
              </div>
            </CardBody>
          </Card>
        </div>

        {/* Summary */}
        <Card>
          <CardHeader title="Audit summary" subtitle="Auto-generated compliance overview" />
          <CardBody>
            {isLoading || !derived ? <SkeletonRow cols={4} /> : (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {[
                  { icon: "✅", title: "Active tools", text: `${derived.activeTools} of ${derived.tools.length} tools are active and accounted for.`, ok: true },
                  derived.unusedTools > 0 && { icon: "⚠️", title: "Unused tools", text: `${derived.unusedTools} tools are unused or orphaned — consider reviewing or decommissioning.`, ok: false },
                  derived.highRiskCount > 0 && { icon: "🔴", title: "High-risk tools", text: `${derived.highRiskCount} tool${derived.highRiskCount !== 1 ? "s" : ""} flagged as high-risk require immediate review.`, ok: false },
                  derived.formerEmpAccess > 0 && { icon: "🚨", title: "Former employee access", text: `${derived.formerEmpAccess} access record${derived.formerEmpAccess !== 1 ? "s" : ""} belong to offboarded employees and should be revoked.`, ok: false },
                  derived.formerEmpAccess === 0 && { icon: "✅", title: "No ghost access", text: "No active access records linked to offboarded employees.", ok: true },
                  { icon: "💰", title: "Monthly spend", text: `Total SaaS spend is ${formatMoney(derived.spend)}/month (${formatMoney(derived.spend * 12)}/year).`, ok: true },
                ].filter(Boolean).map((item) => (
                  <div key={item.title} className={cx(
                    "rounded-xl border p-4 text-sm",
                    item.ok ? "border-emerald-800/40 bg-emerald-950/20" : "border-rose-800/40 bg-rose-950/20"
                  )}>
                    <div className="flex items-center gap-2 font-semibold text-white mb-1">
                      <span>{item.icon}</span>{item.title}
                    </div>
                    <div className="text-slate-400">{item.text}</div>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    </AppShell>
  );
}
'''

# ══════════════════════════════════════════════════════════════
# 3. BILLING PAGE
# ══════════════════════════════════════════════════════════════
BILLING = r'''function BillingPage() {
  const { language } = useLang();
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const muts = useDbMutations();
  const [billing, setBilling] = useState("monthly");

  const plan = db?.user?.subscription_plan || "free";

  const tiers = [
    {
      id: "essentials",
      name: "Essentials",
      tagline: "Perfect for small teams getting started",
      price: { monthly: 29, annual: 278 },
      color: "from-slate-500/20 to-slate-600/10",
      border: "border-slate-700",
      badge: null,
      features: [
        { text: "Up to 25 SaaS tools", included: true },
        { text: "Up to 10 employees", included: true },
        { text: "Basic risk alerts", included: true },
        { text: "CSV import & export", included: true },
        { text: "Dashboard & reporting", included: true },
        { text: "Email support", included: true },
        { text: "Advanced risk scoring", included: false },
        { text: "Executive dashboard", included: false },
        { text: "SSO / SCIM", included: false },
        { text: "API access", included: false },
      ],
      limits: { tools: 25, employees: 10 },
    },
    {
      id: "professional",
      name: "Professional",
      tagline: "For growing teams managing SaaS at scale",
      price: { monthly: 79, annual: 758 },
      color: "from-blue-500/20 to-indigo-500/10",
      border: "border-blue-500/60",
      badge: "Most popular",
      features: [
        { text: "Unlimited SaaS tools", included: true },
        { text: "Unlimited employees", included: true },
        { text: "Advanced risk scoring", included: true },
        { text: "Executive dashboard", included: true },
        { text: "Full audit export", included: true },
        { text: "Priority email support", included: true },
        { text: "API access", included: true },
        { text: "Custom reports", included: true },
        { text: "SSO / SCIM", included: false },
        { text: "Dedicated account manager", included: false },
      ],
      limits: { tools: null, employees: null },
    },
    {
      id: "enterprise",
      name: "Enterprise",
      tagline: "Custom contracts for large organisations",
      price: { monthly: "Custom", annual: "Custom" },
      color: "from-purple-500/20 to-violet-500/10",
      border: "border-purple-500/40",
      badge: "Contact sales",
      features: [
        { text: "Everything in Professional", included: true },
        { text: "SSO & SAML / SCIM", included: true },
        { text: "Dedicated account manager", included: true },
        { text: "Custom integrations", included: true },
        { text: "SLA guarantee (99.9%)", included: true },
        { text: "On-premise option", included: true },
        { text: "24/7 phone support", included: true },
        { text: "Unlimited team seats", included: true },
        { text: "Custom data retention", included: true },
        { text: "Audit log access (API)", included: true },
      ],
      limits: { tools: null, employees: null },
    },
    {
      id: "unlimited",
      name: "Unlimited",
      tagline: "Zero limits. One flat rate. Total control.",
      price: { monthly: 199, annual: 1908 },
      color: "from-emerald-500/20 to-teal-500/10",
      border: "border-emerald-500/40",
      badge: "Best value",
      features: [
        { text: "Everything in Enterprise", included: true },
        { text: "Unlimited everything", included: true },
        { text: "White-label option", included: true },
        { text: "Multi-tenant support", included: true },
        { text: "Advanced AI insights", included: true },
        { text: "Custom SLA", included: true },
        { text: "Priority 1-hour support", included: true },
        { text: "Dedicated infrastructure", included: true },
        { text: "Custom data residency", included: true },
        { text: "Executive briefings", included: true },
      ],
      limits: { tools: null, employees: null },
    },
  ];

  const getPrice = (tier) => {
    const v = tier.price[billing];
    if (typeof v !== "number") return { display: v, sub: null };
    return {
      display: billing === "monthly" ? `€${v}` : `€${v}`,
      sub: billing === "monthly" ? "/month" : "/year",
    };
  };

  const getSavings = (tier) => {
    if (billing !== "annual" || typeof tier.price.annual !== "number") return null;
    const saved = tier.price.monthly * 12 - tier.price.annual;
    return saved > 0 ? `Save €${saved}/year` : null;
  };

  const upgrade = (id) => {
    muts.setPlan?.mutate(id);
    alert("Stripe integration is mocked. Plan updated locally.");
  };

  // What features does the current plan NOT have (upsell)
  const currentTier = tiers.find(t => t.id === plan);
  const missingFeatures = currentTier
    ? currentTier.features.filter(f => !f.included).map(f => f.text)
    : [];

  return (
    <AppShell
      title={t('billing') || 'Billing'}
      right={
        <div className="flex items-center gap-3">
          <Pill tone="blue" icon={CreditCard}>
            {tiers.find(t => t.id === plan)?.name || plan.toUpperCase()}
          </Pill>
        </div>
      }
    >
      <div className="space-y-8">

        {/* Current plan banner */}
        {missingFeatures.length > 0 && (
          <div className="rounded-2xl border border-amber-500/30 bg-amber-500/10 p-4 flex flex-wrap items-center justify-between gap-4">
            <div>
              <div className="text-sm font-semibold text-amber-300">Your current plan is missing these features:</div>
              <div className="text-xs text-amber-400/80 mt-1">{missingFeatures.slice(0, 4).join(" · ")}{missingFeatures.length > 4 ? ` · +${missingFeatures.length - 4} more` : ""}</div>
            </div>
            <Button size="sm" onClick={() => {}}>View plans below</Button>
          </div>
        )}

        {/* Billing toggle */}
        <div className="flex items-center justify-center gap-4">
          <span className={cx("text-sm font-medium", billing === "monthly" ? "text-white" : "text-slate-400")}>Monthly</span>
          <button
            onClick={() => setBilling(b => b === "monthly" ? "annual" : "monthly")}
            className="relative w-14 h-7 bg-slate-700 rounded-full hover:bg-slate-600 transition-colors"
          >
            <div className={cx("absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform", billing === "annual" ? "translate-x-7" : "")} />
          </button>
          <span className={cx("text-sm font-medium", billing === "annual" ? "text-white" : "text-slate-400")}>Annual</span>
          {billing === "annual" && (
            <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full">Save 20%</span>
          )}
        </div>

        {/* Tier cards */}
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
          {tiers.map((tier) => {
            const isCurrent = plan === tier.id;
            const price = getPrice(tier);
            const savings = getSavings(tier);
            return (
              <div
                key={tier.id}
                className={cx(
                  "relative rounded-2xl border bg-gradient-to-br p-6 flex flex-col",
                  tier.color, tier.border,
                  isCurrent ? "ring-2 ring-white/20" : ""
                )}
              >
                {isCurrent && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                    <span className="px-3 py-1 bg-white text-slate-900 text-xs font-bold rounded-full shadow">Current plan</span>
                  </div>
                )}
                {tier.badge && !isCurrent && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                    <span className={cx(
                      "px-3 py-1 text-xs font-bold rounded-full shadow text-white",
                      tier.id === "professional" ? "bg-blue-600" :
                      tier.id === "unlimited" ? "bg-emerald-600" : "bg-purple-600"
                    )}>{tier.badge}</span>
                  </div>
                )}

                <div className="mt-2">
                  <h3 className="text-xl font-black text-white">{tier.name}</h3>
                  <p className="text-xs text-slate-400 mt-1">{tier.tagline}</p>
                </div>

                <div className="mt-4 mb-5">
                  <div className="flex items-end gap-1">
                    <span className="text-4xl font-black text-white">{price.display}</span>
                    {price.sub && <span className="text-slate-400 text-sm mb-1">{price.sub}</span>}
                  </div>
                  {savings && <div className="text-xs text-emerald-400 font-semibold mt-1">{savings}</div>}
                </div>

                <ul className="space-y-2 flex-1 mb-6">
                  {tier.features.map((f) => (
                    <li key={f.text} className="flex items-start gap-2 text-sm">
                      {f.included
                        ? <Check className="h-4 w-4 text-emerald-400 flex-shrink-0 mt-0.5" />
                        : <div className="h-4 w-4 rounded-full border border-slate-700 flex-shrink-0 mt-0.5" />}
                      <span className={f.included ? "text-slate-300" : "text-slate-600"}>{f.text}</span>
                    </li>
                  ))}
                </ul>

                <button
                  disabled={isCurrent}
                  onClick={() => tier.id === "enterprise" ? alert("Contact sales@accessguard.com") : upgrade(tier.id)}
                  className={cx(
                    "w-full py-2.5 rounded-xl font-bold text-sm transition-all",
                    isCurrent
                      ? "bg-slate-700 text-slate-400 cursor-not-allowed"
                      : tier.id === "professional"
                        ? "bg-blue-600 hover:bg-blue-500 text-white"
                        : tier.id === "unlimited"
                          ? "bg-emerald-600 hover:bg-emerald-500 text-white"
                          : tier.id === "enterprise"
                            ? "bg-purple-600 hover:bg-purple-500 text-white"
                            : "bg-slate-800 hover:bg-slate-700 text-white"
                  )}
                >
                  {isCurrent ? "Current plan"
                    : tier.id === "enterprise" ? "Contact sales"
                    : `Upgrade to ${tier.name}`}
                </button>
              </div>
            );
          })}
        </div>

        {/* Feature comparison table */}
        <Card>
          <CardHeader title="Full plan comparison" subtitle="See exactly what's included in each plan" />
          <CardBody>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-slate-800">
                    <th className="text-left px-4 py-3 text-slate-400 font-semibold w-48">Feature</th>
                    {tiers.map(tier => (
                      <th key={tier.id} className={cx("px-4 py-3 text-center font-semibold", plan === tier.id ? "text-white" : "text-slate-400")}>
                        {tier.name}
                        {plan === tier.id && <div className="text-xs text-blue-400 font-normal">Your plan</div>}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {[
                    { label: "SaaS tools",     values: ["25", "Unlimited", "Unlimited", "Unlimited"] },
                    { label: "Employees",       values: ["10", "Unlimited", "Unlimited", "Unlimited"] },
                    { label: "Risk scoring",    values: ["Basic", "Advanced", "Advanced", "AI-powered"] },
                    { label: "Audit export",    values: ["✅", "✅", "✅", "✅"] },
                    { label: "Executive dash",  values: ["—", "✅", "✅", "✅"] },
                    { label: "API access",      values: ["—", "✅", "✅", "✅"] },
                    { label: "SSO / SCIM",      values: ["—", "—", "✅", "✅"] },
                    { label: "Dedicated mgr",   values: ["—", "—", "✅", "✅"] },
                    { label: "White-label",     values: ["—", "—", "—", "✅"] },
                    { label: "Support",         values: ["Email", "Priority", "24/7 phone", "1-hour SLA"] },
                  ].map(({ label, values }, rowIdx) => (
                    <tr key={label} className={cx("border-b border-slate-800/50", rowIdx % 2 === 0 ? "" : "bg-slate-900/20")}>
                      <td className="px-4 py-3 text-slate-400">{label}</td>
                      {values.map((v, i) => (
                        <td key={i} className={cx("px-4 py-3 text-center font-medium", plan === tiers[i].id ? "text-white" : "text-slate-400")}>
                          {v}
                        </td>
                      ))}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardBody>
        </Card>

        {/* Trust badges */}
        <div className="flex flex-wrap items-center justify-center gap-8 text-slate-500 text-sm py-4 border-t border-slate-800">
          <span className="flex items-center gap-2"><Shield className="h-4 w-4" /> SOC 2 Type II</span>
          <span className="flex items-center gap-2"><Lock className="h-4 w-4" /> GDPR compliant</span>
          <span className="flex items-center gap-2"><Award className="h-4 w-4" /> 99.9% uptime SLA</span>
          <span className="flex items-center gap-2"><CreditCard className="h-4 w-4" /> Cancel anytime</span>
        </div>
      </div>
    </AppShell>
  );
}
'''

# ══════════════════════════════════════════════════════════════
# 4. IMPORT PAGE
# ══════════════════════════════════════════════════════════════
IMPORT = r'''function ImportPage() {
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
    tools: ["name,category,owner_email,owner_name,criticality,url,description,status,last_used_date,cost_per_month,risk_score,notes",
            "Slack,communication,amina.dupont@acme.com,Amina Dupont,high,https://slack.com,Messaging,active,2026-02-10,240,low,SSO enabled"].join("\n"),
    employees: ["full_name,email,department,role,status,start_date,end_date",
                "Amina Dupont,amina.dupont@acme.com,security,Security Lead,active,2025-01-01,"].join("\n"),
    access: ["tool_name,employee_email,access_level,granted_date,last_accessed_date,last_reviewed_date,status,risk_flag",
             "Slack,amina.dupont@acme.com,admin,2025-01-01,2026-02-10,2025-12-01,active,needs_review"].join("\n"),
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

  const VALID_VALUES = {
    tools:     { status: TOOL_STATUS, criticality: CRITICALITY },
    employees: { status: ["active","offboarding","offboarded"], department: EMP_DEPARTMENTS },
    access:    { access_level: ACCESS_LEVEL, status: ["active","revoked","pending_revoke"], risk_flag: RISK_FLAG },
  };

  const liveRows = useMemo(() => {
    if (!text.trim()) return [];
    try { return parseCsv(text); } catch { return []; }
  }, [text]);

  const isRowValid = (row) => REQUIRED[kind].every(k => row[k]?.trim());
  const validCount   = liveRows.filter(isRowValid).length;
  const invalidCount = liveRows.length - validCount;

  // Deep validation: check field values against allowed lists
  const runValidation = () => {
    const errors = [];
    const rules  = VALID_VALUES[kind] || {};
    liveRows.forEach((row, i) => {
      // Required fields
      REQUIRED[kind].forEach(field => {
        if (!row[field]?.trim()) {
          errors.push({ row: i + 1, field, type: "missing", msg: `Row ${i+1}: '${field}' is required but empty.` });
        }
      });
      // Allowed values
      Object.entries(rules).forEach(([field, allowed]) => {
        if (row[field] && !allowed.includes(row[field].trim())) {
          errors.push({ row: i + 1, field, type: "invalid", msg: `Row ${i+1}: '${field}' = "${row[field]}" — must be one of: ${allowed.join(", ")}.` });
        }
      });
    });
    setValidationErrors(errors);
    setValidated(true);
  };

  const resetValidation = () => { setValidated(false); setValidationErrors([]); };

  const handleImport = async () => {
    if (!validCount) return;
    setImporting(true);
    try {
      await muts.bulkImport.mutateAsync({ kind, records: liveRows.filter(isRowValid) });
      setImported({ count: validCount, kind, rows: liveRows.filter(isRowValid) });
      setText(""); resetValidation();
    } finally { setImporting(false); }
  };

  const cols = COLS[kind];

  return (
    <AppShell title={t('import') || 'Import Data'} right={<Pill tone="slate" icon={Upload}>CSV</Pill>}>
      <div className="grid gap-5 lg:grid-cols-12">

        <div className="lg:col-span-8 space-y-5">
          <Card>
            <CardHeader title={t('bulk_import') || "Bulk import"} subtitle="Paste CSV for Tools, Employees, or Access records" />
            <CardBody>
              <div className="grid gap-3 md:grid-cols-3">
                <div className="md:col-span-1">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Entity type</div>
                  <Select value={kind} onChange={(e) => { setKind(e.target.value); setText(""); setImported(null); resetValidation(); }}>
                    <option value="tools">Tools</option>
                    <option value="employees">Employees</option>
                    <option value="access">Access Records</option>
                  </Select>
                </div>
                <div className="md:col-span-2 flex items-end justify-end gap-2">
                  <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); resetValidation(); }}>
                    <Download className="h-4 w-4" /> Paste template
                  </Button>
                  <Button variant="secondary" onClick={() => downloadText(`${kind}_template.csv`, templates[kind])}>
                    <Download className="h-4 w-4" /> Download
                  </Button>
                </div>
              </div>

              <div className="mt-3">
                <Textarea
                  rows={10}
                  className="font-mono text-xs"
                  value={text}
                  onChange={(e) => { setText(e.target.value); setImported(null); resetValidation(); }}
                  placeholder="Paste CSV here..."
                />
              </div>

              {liveRows.length > 0 && (
                <div className="mt-2 flex flex-wrap items-center gap-3 text-xs">
                  <span className="text-slate-400">{liveRows.length} row(s) detected</span>
                  {validCount > 0 && <span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
                  {invalidCount > 0 && <span className="text-rose-400 font-semibold">✗ {invalidCount} missing required fields</span>}
                </div>
              )}

              <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                <div className="flex gap-2">
                  <Button
                    variant="secondary"
                    disabled={!text.trim() || liveRows.length === 0}
                    onClick={runValidation}
                  >
                    <Check className="h-4 w-4" />
                    Validate data
                  </Button>
                  <Button
                    disabled={!text.trim() || validCount === 0 || importing || (validated && validationErrors.length > 0)}
                    onClick={handleImport}
                  >
                    {importing
                      ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</>
                      : <><Upload className="h-4 w-4" /> Import {validCount > 0 ? `${validCount} record${validCount > 1 ? "s" : ""}` : ""}</>
                    }
                  </Button>
                </div>
                <div className="text-xs text-slate-500">Validate before importing to catch errors.</div>
              </div>
            </CardBody>
          </Card>

          {/* Validation results */}
          {validated && (
            <Card className={validationErrors.length > 0 ? "border-rose-700/40" : "border-emerald-700/40"}>
              <CardHeader
                title={validationErrors.length === 0 ? "✅ Validation passed" : `⚠️ ${validationErrors.length} validation error${validationErrors.length !== 1 ? "s" : ""}`}
                subtitle={validationErrors.length === 0
                  ? "All rows look good. Safe to import."
                  : "Fix these issues before importing or they will be skipped."
                }
              />
              {validationErrors.length > 0 && (
                <CardBody>
                  <div className="space-y-2 max-h-64 overflow-y-auto">
                    {validationErrors.map((err, i) => (
                      <div key={i} className={cx(
                        "flex items-start gap-3 rounded-xl px-3 py-2 text-sm",
                        err.type === "missing" ? "bg-rose-950/30 border border-rose-800/40" : "bg-amber-950/30 border border-amber-800/40"
                      )}>
                        <AlertTriangle className={cx("h-4 w-4 flex-shrink-0 mt-0.5", err.type === "missing" ? "text-rose-400" : "text-amber-400")} />
                        <span className={err.type === "missing" ? "text-rose-300" : "text-amber-300"}>{err.msg}</span>
                      </div>
                    ))}
                  </div>
                </CardBody>
              )}
            </Card>
          )}

          {/* Live preview */}
          {liveRows.length > 0 && !imported && (
            <Card>
              <CardHeader
                title="Preview"
                subtitle={`${liveRows.length} row(s) parsed`}
                right={
                  <div className="flex gap-2">
                    {validCount > 0 && <Pill tone="green">✓ {validCount} valid</Pill>}
                    {invalidCount > 0 && <Pill tone="rose">✗ {invalidCount} invalid</Pill>}
                  </div>
                }
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500 w-8">#</th>
                        {cols.map(c => (
                          <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">
                            {c.replace(/_/g, " ")}{REQUIRED[kind].includes(c) ? " *" : ""}
                          </th>
                        ))}
                        <th className="px-3 py-2 text-left text-slate-500">Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {liveRows.map((row, i) => {
                        const valid = isRowValid(row);
                        const rowErrs = validationErrors.filter(e => e.row === i + 1);
                        return (
                          <tr key={i} className={cx("border-b border-slate-800/60", valid ? "hover:bg-slate-800/30" : "bg-rose-950/20")}>
                            <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                            {cols.map(c => {
                              const hasErr = rowErrs.some(e => e.field === c);
                              return (
                                <td key={c} className={cx("px-3 py-2 max-w-[120px] truncate",
                                  hasErr ? "text-amber-400" :
                                  !row[c]?.trim() && REQUIRED[kind].includes(c) ? "text-rose-400" : "text-slate-300"
                                )}>
                                  {row[c] || <span className="text-slate-600 italic">—</span>}
                                </td>
                              );
                            })}
                            <td className="px-3 py-2">
                              {rowErrs.length > 0
                                ? <span className="inline-flex items-center gap-1 text-amber-400"><AlertTriangle className="h-3 w-3" /> {rowErrs.length} error{rowErrs.length > 1 ? "s" : ""}</span>
                                : valid
                                  ? <span className="inline-flex items-center gap-1 text-emerald-400"><Check className="h-3 w-3" /> OK</span>
                                  : <span className="inline-flex items-center gap-1 text-rose-400"><AlertTriangle className="h-3 w-3" /> Missing</span>
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

          {/* Success view */}
          {imported && (
            <Card>
              <CardHeader
                title={`✅ ${imported.count} ${imported.kind} imported successfully`}
                subtitle="Records added to your workspace"
                right={<Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>}
              />
              <CardBody>
                <div className="overflow-x-auto rounded-xl border border-slate-800">
                  <table className="w-full text-xs">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950/60">
                        <th className="px-3 py-2 text-left text-slate-500 w-8">#</th>
                        {COLS[imported.kind].map(c => (
                          <th key={c} className="px-3 py-2 text-left text-slate-400 font-semibold capitalize">
                            {c.replace(/_/g, " ")}
                          </th>
                        ))}
                        <th className="px-3 py-2 text-left text-slate-500">Result</th>
                      </tr>
                    </thead>
                    <tbody>
                      {imported.rows.map((row, i) => (
                        <tr key={i} className="border-b border-slate-800/60 hover:bg-slate-800/30">
                          <td className="px-3 py-2 text-slate-500">{i + 1}</td>
                          {COLS[imported.kind].map(c => (
                            <td key={c} className="px-3 py-2 text-slate-300 max-w-[120px] truncate">
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
                  <Button size="sm" onClick={() => {
                    window.location.href = imported.kind === "employees" ? "/employees" : imported.kind === "access" ? "/access" : "/tools";
                  }}>
                    View in {imported.kind === "employees" ? "Employees" : imported.kind === "access" ? "Access Control" : "Tools"}
                  </Button>
                  <Button variant="secondary" size="sm" onClick={() => setImported(null)}>Import more</Button>
                </div>
              </CardBody>
            </Card>
          )}
        </div>

        {/* Right sidebar */}
        <div className="lg:col-span-4 space-y-5">
          <Card>
            <CardHeader title="Format guidelines" subtitle="Required fields marked *" />
            <CardBody>
              <div className="space-y-3 text-sm text-slate-300">
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Tools</div>
                  <div className="mt-1 text-slate-400 text-xs">* name</div>
                  <div className="mt-1 text-slate-400 text-xs">category ∈ {CATEGORIES.join(", ")}</div>
                  <div className="mt-1 text-slate-400 text-xs">status ∈ {TOOL_STATUS.join(", ")}</div>
                  <div className="mt-1 text-slate-400 text-xs">criticality ∈ {CRITICALITY.join(", ")}</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Employees</div>
                  <div className="mt-1 text-slate-400 text-xs">* full_name, * email</div>
                  <div className="mt-1 text-slate-400 text-xs">department ∈ {EMP_DEPARTMENTS.join(", ")}</div>
                  <div className="mt-1 text-slate-400 text-xs">status ∈ active, offboarding, offboarded</div>
                </div>
                <div className="rounded-2xl border border-slate-800 bg-slate-950/30 p-4">
                  <div className="font-semibold">Access Records</div>
                  <div className="mt-1 text-slate-400 text-xs">* tool_name, * employee_email</div>
                  <div className="mt-1 text-slate-400 text-xs">access_level ∈ {ACCESS_LEVEL.join(", ")}</div>
                  <div className="mt-1 text-slate-400 text-xs">risk_flag ∈ {RISK_FLAG.join(", ")}</div>
                </div>
              </div>
            </CardBody>
          </Card>

          <Card>
            <CardHeader title="Current workspace" subtitle="Records already imported" />
            <CardBody>
              <div className="grid grid-cols-3 gap-3 text-center">
                {[
                  { label: "Tools",     count: db?.tools?.length ?? "—",     color: "text-blue-400"   },
                  { label: "Employees", count: db?.employees?.length ?? "—", color: "text-violet-400" },
                  { label: "Access",    count: db?.access?.length ?? "—",    color: "text-emerald-400" },
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
}
'''

do_replace('OffboardingPage', OFFBOARDING)
do_replace('AuditExportPage', AUDIT)
do_replace('BillingPage', BILLING)
do_replace('ImportPage', IMPORT)

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed — restoring${NC}"
    cp "backups/$TS/App.jsx" src/App.jsx
    exit 1
fi

echo ""
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ All 4 pages upgraded!                                 ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  OFFBOARDING                                             ║"
echo -e "║    ✓ Queue: next to be offboarded with days countdown   ║"
echo -e "║    ✓ History: full log of offboarded users + dates      ║"
echo -e "║    ✓ Access revoke panel + checklist sidebar            ║"
echo -e "║  AUDIT EXPORT                                           ║"
echo -e "║    ✓ Health score (0-100) with visual indicator         ║"
echo -e "║    ✓ Tool login counts (users per tool)                 ║"
echo -e "║    ✓ Auto-generated compliance summary                  ║"
echo -e "║  BILLING                                                 ║"
echo -e "║    ✓ 4 tiers: Essentials / Professional / Enterprise /  ║"
echo -e "║             Unlimited                                    ║"
echo -e "║    ✓ Monthly/annual toggle with savings                 ║"
echo -e "║    ✓ Feature comparison table                           ║"
echo -e "║    ✓ Missing features banner for current plan           ║"
echo -e "║  IMPORT DATA                                            ║"
echo -e "║    ✓ Validate button — checks required fields +         ║"
echo -e "║      allowed values before import                       ║"
echo -e "║    ✓ Inline error messages per row                      ║"
echo -e "║    ✓ Success view with imported records table           ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
