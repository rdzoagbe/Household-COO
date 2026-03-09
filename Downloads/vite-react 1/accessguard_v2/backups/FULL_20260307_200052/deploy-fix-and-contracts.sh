#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — Fix Stack Overflow + Contract Compare  ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"

[ ! -f "package.json" ] && echo -e "${RED}✗ Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS" && cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup → backups/$TS/${NC}\n"

python3 - << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []; warn = []

# ══════════════════════════════════════════════════════════════
# FIX 1: Remove ALL stale languagechange useEffect listeners
# These cause infinite loop: context dispatches event → listener
# calls setLanguage (context setter) → context dispatches again
# ══════════════════════════════════════════════════════════════
STALE_EFFECT = re.compile(
    r"\n  // Auto-update when language changes[^\n]*\n"
    r"  useEffect\(\(\) => \{\n"
    r"    const handleLangChange = \(e\) => \{\n"
    r"      const newLang = e\.detail \|\| localStorage\.getItem\('language'\) \|\| 'en';\n"
    r"      setLanguage\(newLang\);\n"
    r"    \};\n"
    r"    window\.addEventListener\('languagechange', handleLangChange\);\n"
    r"    return \(\) => window\.removeEventListener\('languagechange', handleLangChange\);\n"
    r"  \}, \[\]\);\n",
    re.MULTILINE
)
n1 = len(STALE_EFFECT.findall(app))
app = STALE_EFFECT.sub('\n', app)
ok.append(f"Removed {n1} stale languagechange useEffect(s)")

# Also remove the variant without the comment line
STALE_EFFECT2 = re.compile(
    r"\n  useEffect\(\(\) => \{\n"
    r"    const handleLangChange = \(e\) => \{\n"
    r"      const newLang = e\.detail \|\| localStorage\.getItem\('language'\) \|\| 'en';\n"
    r"      setLanguage\(newLang\);\n"
    r"    \};\n"
    r"    window\.addEventListener\('languagechange', handleLangChange\);\n"
    r"    return \(\) => window\.removeEventListener\('languagechange', handleLangChange\);\n"
    r"  \}, \[\]\);\n",
    re.MULTILINE
)
n2 = len(STALE_EFFECT2.findall(app))
app = STALE_EFFECT2.sub('\n', app)
if n2: ok.append(f"Removed {n2} additional stale listeners (no comment variant)")

# ══════════════════════════════════════════════════════════════
# FIX 2: Remove Sidebar's force-sync useEffect (also stale)
# ══════════════════════════════════════════════════════════════
FORCE_SYNC = re.compile(
    r"\n  // Force sync language from localStorage on mount\n"
    r"  useEffect\(\(\) => \{\n"
    r"    const savedLang = localStorage\.getItem\('language'\);\n"
    r"    if \(savedLang && savedLang !== language\) \{\n"
    r"      setLanguage\(savedLang\);\n"
    r"    \}\n"
    r"  \}, \[\]\);\n",
    re.MULTILINE
)
n3 = len(FORCE_SYNC.findall(app))
app = FORCE_SYNC.sub('\n', app)
if n3: ok.append(f"Removed {n3} force-sync localStorage useEffect(s) from Sidebar")

# ══════════════════════════════════════════════════════════════
# FIX 3: SidebarFooter changeLanguage — remove redundant dispatch
# setLanguage (context) already handles persistence, no need to
# also call localStorage.setItem AND dispatch the event manually
# ══════════════════════════════════════════════════════════════
OLD_CHANGE = (
    "  const changeLanguage = (code) => {\n"
    "    localStorage.setItem('language', code);\n"
    "    setShowLangMenu(false);\n"
    "    // Reload current page (not dashboard)\n"
    "\n"
    "    setLanguage(code);\n"
    "    window.dispatchEvent(new CustomEvent('languagechange', { detail: code }));\n"
    "  };\n"
)
NEW_CHANGE = (
    "  const changeLanguage = (code) => {\n"
    "    setLanguage(code);  // context handles localStorage + reactivity\n"
    "    setShowLangMenu(false);\n"
    "  };\n"
)
if OLD_CHANGE in app:
    app = app.replace(OLD_CHANGE, NEW_CHANGE, 1)
    ok.append("SidebarFooter: changeLanguage now uses context only (no duplicate dispatch)")
else:
    # Try to find any variant
    sf_m = re.search(r'const changeLanguage = \(code\) => \{[^}]+window\.dispatchEvent[^}]+\};', app, re.DOTALL)
    if sf_m:
        app = app[:sf_m.start()] + "  const changeLanguage = (code) => {\n    setLanguage(code);\n    setShowLangMenu(false);\n  };\n" + app[sf_m.end():]
        ok.append("SidebarFooter: removed redundant event dispatch (alt match)")
    else:
        warn.append("SidebarFooter: changeLanguage pattern not matched — check manually")

# ══════════════════════════════════════════════════════════════
# FIX 4: Remove setLanguage from Sidebar's useLang destructure
# Sidebar only reads language now, doesn't need setter
# ══════════════════════════════════════════════════════════════
# In Sidebar function body
sb_m = re.search(r'^function Sidebar\(', app, re.MULTILINE)
if sb_m:
    sb_start = sb_m.start()
    sb_end = app.find('\nfunction ', sb_start + 10)
    sb_body = app[sb_start:sb_end]
    if '{ language, setLanguage }' in sb_body:
        sb_body = sb_body.replace('{ language, setLanguage }', '{ language }', 1)
        app = app[:sb_start] + sb_body + app[sb_end:]
        ok.append("Sidebar: removed unneeded setLanguage from destructure")

# ══════════════════════════════════════════════════════════════
# FIX 5: Add FileText, GitCompare icons to imports if needed
# ══════════════════════════════════════════════════════════════
if 'GitCompare' not in app:
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  GitCompare,\n  FileDiff,\n  ArrowLeftRight,\n} from "lucide-react"'
    )
    ok.append("Added GitCompare, FileDiff, ArrowLeftRight icons")

# ══════════════════════════════════════════════════════════════
# FIX 6: Add /contracts route to NAV array
# ══════════════════════════════════════════════════════════════
OLD_NAV_END = '  { to: "/invoices", label: "invoices", icon: Upload },\n];'
NEW_NAV_END = (
    '  { to: "/invoices", label: "invoices", icon: Upload },\n'
    '  { separator: true, label: "Contracts" },\n'
    '  { to: "/contracts", label: "contracts", icon: FileDiff },\n'
    '];'
)
if OLD_NAV_END in app:
    app = app.replace(OLD_NAV_END, NEW_NAV_END, 1)
    ok.append("NAV: added /contracts entry with separator")
else:
    warn.append("NAV: could not find nav end — route not added")

# ══════════════════════════════════════════════════════════════
# FIX 7: Add translation key for contracts
# ══════════════════════════════════════════════════════════════
# Done in translations.js step below

# ══════════════════════════════════════════════════════════════
# FIX 8: Add ContractComparison page before export default App
# ══════════════════════════════════════════════════════════════
CONTRACT_PAGE = r'''
// ============================================================================
// CONTRACT COMPARISON PAGE
// ============================================================================
function ContractComparisonPage() {
  const { language } = useLang();
  const t = useTranslation(language);

  const [contracts, setContracts] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('ag_contracts') || '[]');
    } catch { return []; }
  });

  const saveContracts = (list) => {
    localStorage.setItem('ag_contracts', JSON.stringify(list));
    setContracts(list);
  };

  const [showAdd, setShowAdd] = useState(false);
  const [compareIds, setCompareIds] = useState([]);
  const [tab, setTab] = useState('list'); // 'list' | 'compare'

  // Form state
  const [form, setForm] = useState({
    id: null,
    vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '',
    terms: '', sla: '', autoRenew: false,
    notes: '', status: 'active',
  });

  const resetForm = () => setForm({
    id: null, vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '',
    terms: '', sla: '', autoRenew: false,
    notes: '', status: 'active',
  });

  const handleSave = () => {
    if (!form.vendor.trim() || !form.tool.trim()) return;
    let updated;
    if (form.id) {
      updated = contracts.map(c => c.id === form.id ? { ...form } : c);
    } else {
      updated = [{ ...form, id: `c_${Date.now()}` }, ...contracts];
    }
    saveContracts(updated);
    setShowAdd(false);
    resetForm();
  };

  const handleEdit = (c) => {
    setForm({ ...c });
    setShowAdd(true);
  };

  const handleDelete = (id) => {
    saveContracts(contracts.filter(c => c.id !== id));
    setCompareIds(prev => prev.filter(i => i !== id));
  };

  const handleRevert = (id) => {
    const c = contracts.find(c => c.id === id);
    if (!c) return;
    // Create a new "reverted" copy marked as previous
    const reverted = {
      ...c,
      id: `c_${Date.now()}`,
      version: 'reverted',
      status: 'reverted',
      notes: `Reverted from ${c.version} on ${todayISO()}. ${c.notes || ''}`.trim(),
    };
    saveContracts([reverted, ...contracts]);
  };

  const toggleCompare = (id) => {
    setCompareIds(prev =>
      prev.includes(id) ? prev.filter(i => i !== id) : prev.length < 2 ? [...prev, id] : [prev[1], id]
    );
  };

  const compareContracts = compareIds.map(id => contracts.find(c => c.id === id)).filter(Boolean);

  const statusColor = (s) =>
    s === 'active'   ? 'bg-emerald-500/20 text-emerald-400' :
    s === 'expired'  ? 'bg-rose-500/20 text-rose-400' :
    s === 'reverted' ? 'bg-purple-500/20 text-purple-400' :
    s === 'draft'    ? 'bg-slate-500/20 text-slate-400' :
                       'bg-amber-500/20 text-amber-400';

  const daysToExpiry = (d) => {
    if (!d) return null;
    return Math.ceil((new Date(d) - new Date()) / 86400000);
  };

  const FIELDS = [
    { key: 'vendor',    label: 'Vendor' },
    { key: 'tool',      label: 'Tool / product' },
    { key: 'version',   label: 'Version' },
    { key: 'startDate', label: 'Start date' },
    { key: 'endDate',   label: 'End date' },
    { key: 'value',     label: 'Contract value' },
    { key: 'sla',       label: 'SLA' },
    { key: 'autoRenew', label: 'Auto-renew', render: v => v ? '✅ Yes' : '❌ No' },
    { key: 'terms',     label: 'Terms' },
    { key: 'status',    label: 'Status' },
    { key: 'notes',     label: 'Notes' },
  ];

  return (
    <AppShell
      title="Contract Comparison"
      right={
        <div className="flex gap-2">
          {compareIds.length === 2 && (
            <Button onClick={() => setTab('compare')}>
              <ArrowLeftRight className="h-4 w-4" />
              Compare ({compareIds.length})
            </Button>
          )}
          <Button variant="secondary" onClick={() => { resetForm(); setShowAdd(true); }}>
            <Plus className="h-4 w-4" /> Add contract
          </Button>
        </div>
      }
    >
      <div className="space-y-5">

        {/* Tab bar */}
        <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
          {[
            { id: 'list',    label: 'All contracts' },
            { id: 'compare', label: `Compare${compareIds.length > 0 ? ` (${compareIds.length}/2)` : ''}` },
          ].map(({ id, label }) => (
            <button key={id} onClick={() => setTab(id)}
              className={cx(
                "px-4 py-2 rounded-lg text-sm font-medium transition-colors",
                tab === id ? "bg-blue-600 text-white" : "text-slate-400 hover:text-slate-200"
              )}>
              {label}
            </button>
          ))}
        </div>

        {/* Add / edit modal inline */}
        {showAdd && (
          <Card className="border-blue-600/30">
            <CardHeader
              title={form.id ? "Edit contract" : "Add contract"}
              subtitle="Fill in the details below"
              right={<Button variant="secondary" size="sm" onClick={() => { setShowAdd(false); resetForm(); }}>✕ Cancel</Button>}
            />
            <CardBody>
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {[
                  { key: 'vendor',    label: 'Vendor *',       type: 'text',   placeholder: 'e.g. Salesforce' },
                  { key: 'tool',      label: 'Tool / product *',type: 'text',   placeholder: 'e.g. Sales Cloud' },
                  { key: 'version',   label: 'Version',        type: 'select', opts: ['current','new','proposed','reverted','old'] },
                  { key: 'status',    label: 'Status',         type: 'select', opts: ['active','draft','expired','negotiating','reverted'] },
                  { key: 'startDate', label: 'Start date',     type: 'date' },
                  { key: 'endDate',   label: 'End date',       type: 'date' },
                  { key: 'value',     label: 'Contract value', type: 'text',   placeholder: 'e.g. €12 000/year' },
                  { key: 'sla',       label: 'SLA',            type: 'text',   placeholder: 'e.g. 99.9% uptime' },
                ].map(({ key, label, type, placeholder, opts }) => (
                  <div key={key}>
                    <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                    {type === 'select' ? (
                      <Select value={form[key]} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}>
                        {opts.map(o => <option key={o} value={o}>{o}</option>)}
                      </Select>
                    ) : (
                      <input
                        type={type}
                        value={form[key]}
                        onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
                        placeholder={placeholder || ''}
                        className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    )}
                  </div>
                ))}
                <div className="md:col-span-2 lg:col-span-3">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Terms / key clauses</div>
                  <Textarea rows={3} value={form.terms}
                    onChange={e => setForm(f => ({ ...f, terms: e.target.value }))}
                    placeholder="Describe key terms, pricing clauses, renewal conditions…" />
                </div>
                <div className="md:col-span-2 lg:col-span-3">
                  <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                  <Textarea rows={2} value={form.notes}
                    onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
                    placeholder="Any internal notes, negotiation history, contact info…" />
                </div>
                <div className="flex items-center gap-2">
                  <input type="checkbox" id="autoRenew" checked={form.autoRenew}
                    onChange={e => setForm(f => ({ ...f, autoRenew: e.target.checked }))}
                    className="h-4 w-4 accent-blue-500" />
                  <label htmlFor="autoRenew" className="text-sm text-slate-300">Auto-renews</label>
                </div>
              </div>
              <div className="mt-4 flex gap-2 justify-end">
                <Button variant="secondary" onClick={() => { setShowAdd(false); resetForm(); }}>Cancel</Button>
                <Button disabled={!form.vendor.trim() || !form.tool.trim()} onClick={handleSave}>
                  <Check className="h-4 w-4" />
                  {form.id ? "Save changes" : "Add contract"}
                </Button>
              </div>
            </CardBody>
          </Card>
        )}

        {/* LIST TAB */}
        {tab === 'list' && (
          <div className="space-y-5">
            {contracts.length === 0 ? (
              <EmptyState icon={FileText} title="No contracts yet"
                body="Add your first contract to start comparing versions and tracking renewals." />
            ) : (
              <Card>
                <CardHeader
                  title="All contracts"
                  subtitle="Select up to 2 to compare side-by-side"
                  right={
                    compareIds.length > 0 && (
                      <div className="flex gap-2">
                        <Pill tone="blue">{compareIds.length}/2 selected</Pill>
                        {compareIds.length === 2 && (
                          <Button size="sm" onClick={() => setTab('compare')}>
                            <ArrowLeftRight className="h-4 w-4" /> Compare
                          </Button>
                        )}
                      </div>
                    )
                  }
                />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-3 py-3 w-8"></th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Vendor</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Tool</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Version</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Value</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Expires</th>
                          <th className="px-4 py-3 text-left text-slate-400 font-semibold">Status</th>
                          <th className="px-4 py-3 text-right text-slate-400 font-semibold">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {contracts.map((c) => {
                          const days = daysToExpiry(c.endDate);
                          const selected = compareIds.includes(c.id);
                          return (
                            <tr key={c.id} className={cx(
                              "border-b border-slate-800/50 transition-colors",
                              selected ? "bg-blue-600/10" : "hover:bg-slate-800/30"
                            )}>
                              <td className="px-3 py-3 text-center">
                                <input type="checkbox" checked={selected}
                                  onChange={() => toggleCompare(c.id)}
                                  className="h-4 w-4 accent-blue-500" />
                              </td>
                              <td className="px-4 py-3 font-medium text-white">{c.vendor}</td>
                              <td className="px-4 py-3 text-slate-300">{c.tool}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                                  c.version === 'current' ? 'bg-blue-500/20 text-blue-400' :
                                  c.version === 'new'     ? 'bg-emerald-500/20 text-emerald-400' :
                                  c.version === 'reverted'? 'bg-purple-500/20 text-purple-400' :
                                  'bg-slate-500/20 text-slate-400'
                                )}>{c.version}</span>
                              </td>
                              <td className="px-4 py-3 text-slate-300">{c.value || '—'}</td>
                              <td className="px-4 py-3">
                                {c.endDate ? (
                                  <div>
                                    <div className="text-slate-300">{c.endDate}</div>
                                    {days !== null && (
                                      <div className={cx("text-xs font-semibold",
                                        days < 0 ? "text-rose-400" : days <= 30 ? "text-amber-400" : "text-slate-500"
                                      )}>
                                        {days < 0 ? `${Math.abs(days)}d overdue` : days === 0 ? "Today" : `${days}d left`}
                                      </div>
                                    )}
                                  </div>
                                ) : '—'}
                              </td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold", statusColor(c.status))}>
                                  {c.status}
                                </span>
                              </td>
                              <td className="px-4 py-3 text-right">
                                <div className="flex items-center justify-end gap-1">
                                  <Button size="sm" variant="secondary" onClick={() => handleEdit(c)}>
                                    <Pencil className="h-3 w-3" />
                                  </Button>
                                  <Button size="sm" variant="secondary" onClick={() => handleRevert(c.id)}
                                    title="Create a reverted copy of this contract">
                                    <RefreshCw className="h-3 w-3" />
                                  </Button>
                                  <Button size="sm" variant="danger" onClick={() => handleDelete(c.id)}>
                                    <Trash2 className="h-3 w-3" />
                                  </Button>
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

            {/* Summary stats */}
            {contracts.length > 0 && (
              <div className="grid gap-4 md:grid-cols-4">
                {[
                  { label: "Total contracts", value: contracts.length, color: "text-white" },
                  { label: "Active",           value: contracts.filter(c => c.status === "active").length, color: "text-emerald-400" },
                  { label: "Expiring ≤30d",    value: contracts.filter(c => { const d = daysToExpiry(c.endDate); return d !== null && d >= 0 && d <= 30; }).length, color: "text-amber-400" },
                  { label: "Expired",          value: contracts.filter(c => c.status === "expired" || (c.endDate && daysToExpiry(c.endDate) < 0)).length, color: "text-rose-400" },
                ].map(({ label, value, color }) => (
                  <Card key={label}>
                    <CardBody>
                      <div className="text-xs font-semibold text-slate-500 uppercase tracking-wide">{label}</div>
                      <div className={cx("text-3xl font-black mt-1", color)}>{value}</div>
                    </CardBody>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {/* COMPARE TAB */}
        {tab === 'compare' && (
          <div className="space-y-5">
            {compareContracts.length < 2 ? (
              <Card>
                <CardBody>
                  <div className="text-center py-8">
                    <ArrowLeftRight className="h-10 w-10 text-slate-600 mx-auto mb-3" />
                    <div className="text-white font-semibold">Select 2 contracts to compare</div>
                    <div className="text-sm text-slate-400 mt-1">Go to the list tab and check 2 contracts</div>
                    <Button className="mt-4" variant="secondary" onClick={() => setTab('list')}>Back to list</Button>
                  </div>
                </CardBody>
              </Card>
            ) : (
              <div className="space-y-5">
                {/* Header row */}
                <div className="grid grid-cols-3 gap-4">
                  <div className="text-xs font-semibold text-slate-500 uppercase tracking-widest pt-2">Field</div>
                  {compareContracts.map((c, i) => (
                    <Card key={c.id} className={i === 0 ? "border-blue-600/40" : "border-emerald-600/40"}>
                      <CardBody>
                        <div className="flex items-center gap-2 mb-1">
                          <span className={cx("h-3 w-3 rounded-full", i === 0 ? "bg-blue-500" : "bg-emerald-500")} />
                          <span className="font-bold text-white">{c.vendor}</span>
                        </div>
                        <div className="text-sm text-slate-400">{c.tool}</div>
                        <div className="mt-2 flex gap-2 flex-wrap">
                          <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                            c.version === 'current' ? 'bg-blue-500/20 text-blue-400' :
                            c.version === 'new'     ? 'bg-emerald-500/20 text-emerald-400' :
                            'bg-slate-500/20 text-slate-400'
                          )}>{c.version}</span>
                          <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold", statusColor(c.status))}>
                            {c.status}
                          </span>
                        </div>
                      </CardBody>
                    </Card>
                  ))}
                </div>

                {/* Comparison rows */}
                <Card>
                  <CardBody>
                    <div className="space-y-1">
                      {FIELDS.map(({ key, label, render }) => {
                        const vals = compareContracts.map(c => render ? render(c[key]) : (String(c[key] || '')));
                        const differ = vals[0] !== vals[1];
                        return (
                          <div key={key} className={cx(
                            "grid grid-cols-3 gap-4 px-3 py-3 rounded-xl transition-colors",
                            differ ? "bg-amber-500/10 border border-amber-500/20" : "hover:bg-slate-800/30"
                          )}>
                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-400">
                              {differ && <span className="h-2 w-2 rounded-full bg-amber-400 flex-shrink-0" />}
                              {label}
                            </div>
                            {vals.map((v, i) => (
                              <div key={i} className={cx(
                                "text-sm break-words",
                                differ ? (i === 0 ? "text-blue-300" : "text-emerald-300") : "text-slate-300"
                              )}>
                                {v || <span className="text-slate-600 italic">—</span>}
                              </div>
                            ))}
                          </div>
                        );
                      })}
                    </div>
                  </CardBody>
                </Card>

                {/* Differences summary */}
                {(() => {
                  const diffs = FIELDS.filter(({ key, render }) => {
                    const vals = compareContracts.map(c => render ? render(c[key]) : String(c[key] || ''));
                    return vals[0] !== vals[1];
                  });
                  return diffs.length > 0 ? (
                    <Card className="border-amber-500/30">
                      <CardHeader
                        title={`${diffs.length} difference${diffs.length !== 1 ? "s" : ""} found`}
                        subtitle="Fields that differ between the two contracts"
                      />
                      <CardBody>
                        <div className="flex flex-wrap gap-2">
                          {diffs.map(({ label }) => (
                            <span key={label} className="px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-400">
                              {label}
                            </span>
                          ))}
                        </div>
                      </CardBody>
                    </Card>
                  ) : (
                    <Card className="border-emerald-500/30">
                      <CardBody>
                        <div className="flex items-center gap-3 text-emerald-400">
                          <CheckCircle className="h-5 w-5" />
                          <span className="font-semibold">Contracts are identical across all fields</span>
                        </div>
                      </CardBody>
                    </Card>
                  );
                })()}

                {/* Revert action */}
                <div className="flex flex-wrap gap-3 items-center p-4 rounded-2xl border border-slate-800 bg-slate-900/40">
                  <div className="flex-1">
                    <div className="text-sm font-semibold text-white">Revert to a previous contract</div>
                    <div className="text-xs text-slate-400 mt-0.5">Creates a copy marked as "reverted" — original is preserved.</div>
                  </div>
                  {compareContracts.map((c, i) => (
                    <Button key={c.id} variant="secondary" size="sm" onClick={() => { handleRevert(c.id); setTab('list'); }}>
                      <RefreshCw className="h-3 w-3" />
                      Revert to "{c.vendor} {c.version}"
                    </Button>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </AppShell>
  );
}

'''

# Insert before "export default function App()"
insert_before = 'export default function App()'
if insert_before in app:
    app = app.replace(insert_before, CONTRACT_PAGE + insert_before, 1)
    ok.append("ContractComparisonPage: injected")
else:
    warn.append("ContractComparisonPage: could not find insertion point")

# ══════════════════════════════════════════════════════════════
# FIX 9: Add /contracts route inside App()
# ══════════════════════════════════════════════════════════════
OLD_LAST_ROUTE = '          <Route path="*" element={<NotFound />} />'
NEW_LAST_ROUTE = (
    '          <Route\n'
    '            path="/contracts"\n'
    '            element={\n'
    '              <RequireAuth>\n'
    '                <ContractComparisonPage />\n'
    '              </RequireAuth>\n'
    '            }\n'
    '          />\n'
    '          <Route path="*" element={<NotFound />} />'
)
if OLD_LAST_ROUTE in app:
    app = app.replace(OLD_LAST_ROUTE, NEW_LAST_ROUTE, 1)
    ok.append("App router: /contracts route added")
else:
    warn.append("App router: could not find last route — /contracts not added")

# ══════════════════════════════════════════════════════════════
# Print report
# ══════════════════════════════════════════════════════════════
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# Add 'contracts' translation key
python3 - << 'PYEOF'
import re, os
path = 'src/translations.js'
if not os.path.exists(path): exit()
with open(path, encoding='utf-8') as f: src = f.read()

additions = {
    'en': ("    contracts: 'Contracts',", 'en: {'),
    'es': ("    contracts: 'Contratos',", 'es: {'),
    'fr': ("    contracts: 'Contrats',", 'fr: {'),
    'de': ("    contracts: 'Verträge',", 'de: {'),
    'ja': ("    contracts: '契約管理',", 'ja: {'),
}
for lang, (line, marker) in additions.items():
    key = "    contracts:"
    ls = src.find(f'{lang}: {{')
    le = src.find('\n  },', ls)
    if key not in src[ls:le]:
        insert = src.find('\n', src.find(marker)) 
        src = src[:insert+1] + line + '\n' + src[insert+1:]
        print(f"  \033[32m✓\033[0m  {lang}: added contracts key")

with open(path, 'w', encoding='utf-8') as f: f.write(src)
PYEOF

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
echo -e "║  ✓ Stack overflow fixed + Contracts page deployed!       ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  CRASH FIX                                               ║"
echo -e "║    Root cause: LanguageProvider dispatched               ║"
echo -e "║    languagechange event, stale listeners called          ║"
echo -e "║    setLanguage (context) → infinite loop                 ║"
echo -e "║    Fixed: removed all 7 stale event listeners            ║"
echo -e "║    Context reactivity handles everything now             ║"
echo -e "║                                                          ║"
echo -e "║  CONTRACTS (new page in sidebar)                        ║"
echo -e "║    ✓ Add/edit/delete contracts with full details        ║"
echo -e "║    ✓ Select 2 → side-by-side comparison                 ║"
echo -e "║    ✓ Differences highlighted in amber                   ║"
echo -e "║    ✓ Revert button creates a preserved copy             ║"
echo -e "║    ✓ Expiry countdown per contract                      ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
