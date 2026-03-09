#!/bin/bash
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'

echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗"
echo -e "║  AccessGuard V2 — AI Contract Comparison + Negotiation  ║"
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

# ── 1. Remove ALL stale languagechange listeners ──────────────
stale = (
    "    const handleLangChange = (e) => {\n"
    "      const newLang = e.detail || localStorage.getItem('language') || 'en';\n"
    "      setLanguage(newLang);\n"
    "    };\n"
    "    window.addEventListener('languagechange', handleLangChange);\n"
    "    return () => window.removeEventListener('languagechange', handleLangChange);\n"
    "  }, []);\n"
)
# Find & remove each useEffect block containing the stale listener
count = 0
while True:
    idx = app.find(stale)
    if idx == -1: break
    # Walk back to find the opening useEffect
    ue_start = app.rfind('\n  useEffect(() => {\n', 0, idx)
    if ue_start == -1: break
    # Also remove the comment line before it if present
    comment_pat = '\n  // Auto-update when language changes'
    cm = app.rfind(comment_pat, 0, ue_start)
    if cm != -1 and ue_start - cm < 60:
        ue_start = cm
    end_of_block = idx + len(stale)
    app = app[:ue_start] + '\n' + app[end_of_block:]
    count += 1
ok.append(f"Removed {count} stale languagechange listener(s)")

# ── 2. Remove force-sync useEffect from Sidebar ──────────────
force = (
    "\n  // Force sync language from localStorage on mount\n"
    "  useEffect(() => {\n"
    "    const savedLang = localStorage.getItem('language');\n"
    "    if (savedLang && savedLang !== language) {\n"
    "      setLanguage(savedLang);\n"
    "    }\n"
    "  }, []);\n"
)
if force in app:
    app = app.replace(force, '\n')
    ok.append("Removed Sidebar force-sync useEffect")

# ── 3. Fix SidebarFooter changeLanguage ──────────────────────
old_cl = re.search(
    r"  const changeLanguage = \(code\) => \{[^}]+window\.dispatchEvent[^}]+\};",
    app, re.DOTALL
)
if old_cl:
    app = app[:old_cl.start()] + (
        "  const changeLanguage = (code) => {\n"
        "    setLanguage(code);\n"
        "    setShowLangMenu(false);\n"
        "  };"
    ) + app[old_cl.end():]
    ok.append("SidebarFooter: changeLanguage uses context only")

# ── 4. Add icons ──────────────────────────────────────────────
needed = ['ArrowLeftRight', 'FileDiff', 'Scale', 'Gavel', 'Bot', 'Send', 'Paperclip', 'Clock']
missing = [i for i in needed if i not in app]
if missing:
    app = app.replace(
        '  MessageCircle,\n} from "lucide-react"',
        '  MessageCircle,\n  ' + ',\n  '.join(missing) + ',\n} from "lucide-react"'
    )
    ok.append(f"Icons added: {', '.join(missing)}")

# ── 5. Remove any existing ContractComparisonPage ────────────
occ = [m.start() for m in re.finditer(r'\nfunction ContractComparisonPage\(\)', app)]
if occ:
    for start in reversed(occ):
        end = app.find('\nexport default function App()', start)
        if end == -1: end = app.find('\nfunction ', start + 10)
        app = app[:start] + app[end:]
    ok.append(f"Removed {len(occ)} old ContractComparisonPage(s)")

# ── 6. Add NAV entry ──────────────────────────────────────────
old_nav = '  { to: "/invoices", label: "invoices", icon: Upload },\n];'
new_nav = (
    '  { to: "/invoices", label: "invoices", icon: Upload },\n'
    '  { separator: true, label: "Contracts" },\n'
    '  { to: "/contracts", label: "contracts", icon: FileText },\n'
    '];'
)
if '{ to: "/contracts"' not in app and old_nav in app:
    app = app.replace(old_nav, new_nav, 1)
    ok.append("NAV: /contracts added")
elif '{ to: "/contracts"' in app:
    ok.append("NAV: /contracts already present")

# ── 7. Inject the full ContractComparisonPage ─────────────────
CONTRACT_PAGE = '''
// ============================================================================
// CONTRACT COMPARISON + NEGOTIATION PAGE  (AI-powered)
// ============================================================================
function ContractComparisonPage() {
  const { language } = useLang();
  const t = useTranslation(language);

  // ── tabs ──────────────────────────────────────────────────
  const [tab, setTab] = useState('negotiations'); // negotiations | compare | ai

  // ── negotiations state ────────────────────────────────────
  const [negotiations, setNegotiations] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_negotiations') || '[]'); }
    catch { return []; }
  });
  const saveNegotiations = (list) => {
    localStorage.setItem('ag_negotiations', JSON.stringify(list));
    setNegotiations(list);
  };
  const [showAddNeg, setShowAddNeg] = useState(false);
  const [negForm, setNegForm] = useState({
    id: null, customer: '', assignee: '', salesPerson: '',
    createDate: todayISO(), deadline: '', arr: '', status: 'In Progress',
    currentWith: 'With Our Legal Team', notes: '',
  });
  const resetNegForm = () => setNegForm({
    id: null, customer: '', assignee: '', salesPerson: '',
    createDate: todayISO(), deadline: '', arr: '', status: 'In Progress',
    currentWith: 'With Our Legal Team', notes: '',
  });
  const saveNeg = () => {
    if (!negForm.customer.trim()) return;
    const list = negForm.id
      ? negotiations.map(n => n.id === negForm.id ? { ...negForm } : n)
      : [{ ...negForm, id: `neg_${Date.now()}` }, ...negotiations];
    saveNegotiations(list);
    setShowAddNeg(false);
    resetNegForm();
  };
  const deleteNeg = (id) => saveNegotiations(negotiations.filter(n => n.id !== id));
  const editNeg = (n) => { setNegForm({ ...n }); setShowAddNeg(true); };
  const revertNeg = (id) => {
    const n = negotiations.find(n => n.id === id);
    if (!n) return;
    saveNegotiations([{
      ...n, id: `neg_${Date.now()}`,
      status: 'Reverted', currentWith: 'Reverted to Vendor',
      notes: `Reverted on ${todayISO()}. ${n.notes || ''}`.trim(),
    }, ...negotiations]);
  };

  const STATUS_COLORS = {
    'In Progress':     'bg-blue-500/20 text-blue-400',
    'Waiting on Approval': 'bg-amber-500/20 text-amber-400',
    'Ready for Signing':   'bg-emerald-500/20 text-emerald-400',
    'Signed':          'bg-teal-500/20 text-teal-400',
    'Reverted':        'bg-purple-500/20 text-purple-400',
    'On Hold':         'bg-slate-500/20 text-slate-400',
    'Rejected':        'bg-rose-500/20 text-rose-400',
  };
  const PIPELINE_STAGES = [
    'With Our Legal Team', 'Waiting on Approval', 'Ready for Signing',
    'With Customer', 'Final Review', 'Reverted to Vendor',
  ];

  const daysLeft = (d) => d ? Math.ceil((new Date(d) - new Date()) / 86400000) : null;

  // ── comparison state ──────────────────────────────────────
  const [contracts, setContracts] = useState(() => {
    try { return JSON.parse(localStorage.getItem('ag_contracts') || '[]'); }
    catch { return []; }
  });
  const saveContracts = (list) => {
    localStorage.setItem('ag_contracts', JSON.stringify(list));
    setContracts(list);
  };
  const [compareIds, setCompareIds] = useState([]);
  const [showAddContract, setShowAddContract] = useState(false);
  const [cForm, setCForm] = useState({
    id: null, vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '', terms: '', sla: '',
    autoRenew: false, notes: '', status: 'active',
  });
  const resetCForm = () => setCForm({
    id: null, vendor: '', tool: '', version: 'current',
    startDate: '', endDate: '', value: '', terms: '', sla: '',
    autoRenew: false, notes: '', status: 'active',
  });
  const saveContract = () => {
    if (!cForm.vendor.trim()) return;
    const list = cForm.id
      ? contracts.map(c => c.id === cForm.id ? { ...cForm } : c)
      : [{ ...cForm, id: `c_${Date.now()}` }, ...contracts];
    saveContracts(list);
    setShowAddContract(false);
    resetCForm();
  };
  const toggleCompare = (id) => setCompareIds(prev =>
    prev.includes(id) ? prev.filter(i => i !== id)
      : prev.length < 2 ? [...prev, id] : [prev[1], id]
  );
  const cmpContracts = compareIds.map(id => contracts.find(c => c.id === id)).filter(Boolean);
  const CFIELDS = [
    { key: 'vendor', label: 'Vendor' }, { key: 'tool', label: 'Tool' },
    { key: 'version', label: 'Version' }, { key: 'startDate', label: 'Start' },
    { key: 'endDate', label: 'End' }, { key: 'value', label: 'Value' },
    { key: 'sla', label: 'SLA' },
    { key: 'autoRenew', label: 'Auto-renew', render: v => v ? 'Yes' : 'No' },
    { key: 'terms', label: 'Terms' }, { key: 'status', label: 'Status' },
    { key: 'notes', label: 'Notes' },
  ];

  // ── AI comparison state ───────────────────────────────────
  const [doc1, setDoc1] = useState('');
  const [doc2, setDoc2] = useState('');
  const [doc1Name, setDoc1Name] = useState('');
  const [doc2Name, setDoc2Name] = useState('');
  const [aiResult, setAiResult] = useState(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiError, setAiError] = useState('');
  const [chatMessages, setChatMessages] = useState([]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);

  const readFile = (file, setName, setContent) => {
    setName(file.name);
    const reader = new FileReader();
    reader.onload = (e) => setContent(e.target.result);
    reader.readAsText(file);
  };

  const runAiComparison = async () => {
    if (!doc1.trim() || !doc2.trim()) return;
    setAiLoading(true); setAiError(''); setAiResult(null);
    try {
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1000,
          messages: [{
            role: 'user',
            content: `You are a legal contract analyst. Compare these two contracts and respond ONLY with a valid JSON object (no markdown, no explanation outside JSON) with this exact structure:
{
  "summary": "2-3 sentence overview of main differences",
  "differences": [
    { "field": "field name", "doc1": "value in doc1", "doc2": "value in doc2", "severity": "high|medium|low", "recommendation": "what to do" }
  ],
  "risks": ["risk 1", "risk 2"],
  "recommendations": ["rec 1", "rec 2"],
  "verdict": "which contract is better and why in one sentence"
}

CONTRACT 1 (${doc1Name || 'Document 1'}):
${doc1.slice(0, 3000)}

CONTRACT 2 (${doc2Name || 'Document 2'}):
${doc2.slice(0, 3000)}`
          }]
        })
      });
      const data = await resp.json();
      const text = data.content?.[0]?.text || '';
      const clean = text.replace(/```json|```/g, '').trim();
      const parsed = JSON.parse(clean);
      setAiResult(parsed);
      setChatMessages([{
        role: 'assistant',
        content: `I've compared both contracts. ${parsed.summary} Ask me anything about specific clauses, risks, or negotiation strategies.`
      }]);
    } catch (e) {
      setAiError('Could not analyse contracts. Check that both documents contain readable text.');
    } finally { setAiLoading(false); }
  };

  const sendChat = async () => {
    if (!chatInput.trim() || chatLoading) return;
    const userMsg = { role: 'user', content: chatInput };
    const newMessages = [...chatMessages, userMsg];
    setChatMessages(newMessages);
    setChatInput('');
    setChatLoading(true);
    try {
      const context = aiResult
        ? `Context: The user is comparing two contracts. Analysis: ${JSON.stringify(aiResult)}\n\nDoc1 excerpt: ${doc1.slice(0, 1500)}\nDoc2 excerpt: ${doc2.slice(0, 1500)}`
        : 'The user is asking about contract negotiation.';
      const resp = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'claude-sonnet-4-20250514',
          max_tokens: 1000,
          system: `You are an expert contract negotiation advisor for SaaS companies. Be concise and actionable. ${context}`,
          messages: newMessages.map(m => ({ role: m.role, content: m.content }))
        })
      });
      const data = await resp.json();
      const reply = data.content?.[0]?.text || 'Sorry, I could not respond.';
      setChatMessages(prev => [...prev, { role: 'assistant', content: reply }]);
    } catch {
      setChatMessages(prev => [...prev, { role: 'assistant', content: 'Error reaching AI. Please try again.' }]);
    } finally { setChatLoading(false); }
  };

  const sevColor = (s) =>
    s === 'high' ? 'bg-rose-500/20 text-rose-400 border-rose-500/30' :
    s === 'medium' ? 'bg-amber-500/20 text-amber-400 border-amber-500/30' :
    'bg-slate-500/20 text-slate-400 border-slate-500/30';

  return (
    <AppShell
      title="Contracts"
      right={
        <div className="flex gap-2">
          {tab === 'negotiations' && (
            <Button onClick={() => { resetNegForm(); setShowAddNeg(true); }}>
              <Plus className="h-4 w-4" /> New negotiation
            </Button>
          )}
          {tab === 'compare' && (
            <Button variant="secondary" onClick={() => { resetCForm(); setShowAddContract(true); }}>
              <Plus className="h-4 w-4" /> Add contract
            </Button>
          )}
        </div>
      }
    >
      <div className="space-y-5">
        {/* Tab bar */}
        <div className="flex gap-1 rounded-xl border border-slate-800 bg-slate-900/60 p-1 w-fit">
          {[
            { id: 'negotiations', label: '📋 Negotiation Tracker' },
            { id: 'compare',      label: '⇄ Contract Comparison' },
            { id: 'ai',           label: '🤖 AI Analysis' },
          ].map(({ id, label }) => (
            <button key={id} onClick={() => setTab(id)}
              className={cx("px-4 py-2 rounded-lg text-sm font-medium transition-colors",
                tab === id ? "bg-blue-600 text-white shadow" : "text-slate-400 hover:text-slate-200"
              )}>
              {label}
            </button>
          ))}
        </div>

        {/* ══ TAB: NEGOTIATION TRACKER ══════════════════════════════ */}
        {tab === 'negotiations' && (
          <div className="space-y-5">
            {/* Stats row */}
            <div className="grid gap-4 md:grid-cols-4">
              {[
                { label: 'Total',           value: negotiations.length,                                        color: 'text-white' },
                { label: 'In Progress',     value: negotiations.filter(n => n.status === 'In Progress').length, color: 'text-blue-400' },
                { label: 'Ready to Sign',   value: negotiations.filter(n => n.status === 'Ready for Signing').length, color: 'text-emerald-400' },
                { label: 'Total ARR',       value: '$' + negotiations.reduce((s, n) => s + Number((n.arr || '0').replace(/[^0-9.]/g,'')), 0).toLocaleString(), color: 'text-amber-400' },
              ].map(({ label, value, color }) => (
                <Card key={label}><CardBody>
                  <div className="text-xs font-semibold uppercase tracking-widest text-slate-500">{label}</div>
                  <div className={cx("text-3xl font-black mt-1", color)}>{value}</div>
                </CardBody></Card>
              ))}
            </div>

            {/* Add / edit form */}
            {showAddNeg && (
              <Card className="border-blue-600/30">
                <CardHeader
                  title={negForm.id ? 'Edit negotiation' : 'New contract negotiation'}
                  subtitle="Fill in the deal details"
                  right={<Button variant="secondary" size="sm" onClick={() => { setShowAddNeg(false); resetNegForm(); }}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[
                      { key: 'customer',    label: 'Customer *',    type: 'text', ph: 'e.g. Acme Corp' },
                      { key: 'assignee',    label: 'Assignee',      type: 'text', ph: 'Assigned to' },
                      { key: 'salesPerson', label: 'Sales Person',  type: 'text', ph: 'Sales rep name' },
                      { key: 'arr',         label: 'ARR of Contract', type: 'text', ph: '$0.00' },
                      { key: 'createDate',  label: 'Create Date',   type: 'date' },
                      { key: 'deadline',    label: 'Deadline',      type: 'date' },
                    ].map(({ key, label, type, ph }) => (
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type} value={negForm[key]}
                          onChange={e => setNegForm(f => ({ ...f, [key]: e.target.value }))}
                          placeholder={ph || ''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    ))}
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
                      <Select value={negForm.status} onChange={e => setNegForm(f => ({ ...f, status: e.target.value }))}>
                        {Object.keys(STATUS_COLORS).map(s => <option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Currently With</div>
                      <Select value={negForm.currentWith} onChange={e => setNegForm(f => ({ ...f, currentWith: e.target.value }))}>
                        {PIPELINE_STAGES.map(s => <option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                      <Textarea rows={2} value={negForm.notes}
                        onChange={e => setNegForm(f => ({ ...f, notes: e.target.value }))}
                        placeholder="Key clauses, outstanding issues, history…" />
                    </div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={() => { setShowAddNeg(false); resetNegForm(); }}>Cancel</Button>
                    <Button disabled={!negForm.customer.trim()} onClick={saveNeg}>
                      <Check className="h-4 w-4" /> {negForm.id ? 'Save changes' : 'Add negotiation'}
                    </Button>
                  </div>
                </CardBody>
              </Card>
            )}

            {/* Negotiation table */}
            {negotiations.length === 0 ? (
              <EmptyState icon={FileText} title="No negotiations yet"
                body="Track contract negotiations from first draft to signing." />
            ) : (
              <Card>
                <CardHeader title="Contract Negotiation Tracker" subtitle="Track every deal from draft to close" />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          {['Customer','Assignee','Create Date','Deadline','ARR of Contract','Currently With','Sales Person','Status','Actions'].map(h => (
                            <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold whitespace-nowrap">{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {negotiations.map((n) => {
                          const days = daysLeft(n.deadline);
                          return (
                            <tr key={n.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
                              <td className="px-4 py-3">
                                <div className="font-semibold text-blue-400 hover:text-blue-300 cursor-pointer" onClick={() => editNeg(n)}>{n.customer}</div>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-2">
                                  <div className="h-7 w-7 rounded-full bg-gradient-to-br from-blue-500 to-violet-600 flex items-center justify-center text-xs font-bold text-white flex-shrink-0">
                                    {(n.assignee || '?').charAt(0).toUpperCase()}
                                  </div>
                                  <span className="text-slate-300 text-xs">{n.assignee || '—'}</span>
                                </div>
                              </td>
                              <td className="px-4 py-3 text-slate-400 whitespace-nowrap text-xs">
                                {n.createDate ? `${n.createDate} | ${new Date(n.createDate).toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})}` : '—'}
                              </td>
                              <td className="px-4 py-3 whitespace-nowrap">
                                <div className="text-slate-300 text-xs">{n.deadline ? new Date(n.deadline).toLocaleDateString('en-GB', { day:'2-digit', month:'short', year:'numeric'}) : '—'}</div>
                                {days !== null && (
                                  <div className={cx("text-xs font-semibold",
                                    days < 0 ? 'text-rose-400' : days <= 7 ? 'text-amber-400' : 'text-slate-500'
                                  )}>
                                    {days < 0 ? `${Math.abs(days)}d overdue` : days === 0 ? 'Today' : `${days}d left`}
                                  </div>
                                )}
                              </td>
                              <td className="px-4 py-3 font-semibold text-white">{n.arr || '—'}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap",
                                  n.currentWith === 'Ready for Signing' ? 'bg-emerald-500/20 text-emerald-400' :
                                  n.currentWith === 'Waiting on Approval' ? 'bg-amber-500/20 text-amber-400' :
                                  n.currentWith === 'Reverted to Vendor' ? 'bg-purple-500/20 text-purple-400' :
                                  'bg-slate-500/20 text-slate-400'
                                )}>{n.currentWith}</span>
                              </td>
                              <td className="px-4 py-3 text-slate-300">{n.salesPerson || '—'}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-1 rounded-full text-xs font-semibold whitespace-nowrap", STATUS_COLORS[n.status] || 'bg-slate-500/20 text-slate-400')}>
                                  {n.status}
                                </span>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex items-center gap-1">
                                  <Button size="sm" variant="secondary" onClick={() => editNeg(n)}><Pencil className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="secondary" onClick={() => revertNeg(n.id)} title="Revert to vendor"><RefreshCw className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="danger" onClick={() => deleteNeg(n.id)}><Trash2 className="h-3 w-3" /></Button>
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

            {/* Legal pipeline view */}
            {negotiations.length > 0 && (
              <Card>
                <CardHeader title="Legal Pipeline" subtitle="Deals by stage" />
                <CardBody>
                  <div className="grid gap-3 md:grid-cols-3 lg:grid-cols-6">
                    {PIPELINE_STAGES.map(stage => {
                      const deals = negotiations.filter(n => n.currentWith === stage);
                      return (
                        <div key={stage} className="rounded-xl border border-slate-800 bg-slate-950/30 p-3">
                          <div className="text-xs font-semibold text-slate-400 mb-2 leading-tight">{stage}</div>
                          <div className="text-2xl font-black text-white">{deals.length}</div>
                          {deals.length > 0 && (
                            <div className="mt-2 space-y-1">
                              {deals.slice(0,3).map(d => (
                                <div key={d.id} className="text-xs text-blue-400 truncate">{d.customer}</div>
                              ))}
                              {deals.length > 3 && <div className="text-xs text-slate-600">+{deals.length-3} more</div>}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </CardBody>
              </Card>
            )}
          </div>
        )}

        {/* ══ TAB: SIDE-BY-SIDE COMPARE ════════════════════════════ */}
        {tab === 'compare' && (
          <div className="space-y-5">
            {showAddContract && (
              <Card className="border-blue-600/30">
                <CardHeader
                  title={cForm.id ? 'Edit contract' : 'Add contract'}
                  right={<Button variant="secondary" size="sm" onClick={() => { setShowAddContract(false); resetCForm(); }}>✕</Button>}
                />
                <CardBody>
                  <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {[
                      { key: 'vendor', label: 'Vendor *', type: 'text', ph: 'e.g. Salesforce' },
                      { key: 'tool',   label: 'Tool *',   type: 'text', ph: 'e.g. Sales Cloud' },
                      { key: 'value',  label: 'Value',    type: 'text', ph: '€12,000/year' },
                      { key: 'sla',    label: 'SLA',      type: 'text', ph: '99.9% uptime' },
                      { key: 'startDate', label: 'Start', type: 'date' },
                      { key: 'endDate',   label: 'End',   type: 'date' },
                    ].map(({ key, label, type, ph }) => (
                      <div key={key}>
                        <div className="mb-1 text-xs font-semibold text-slate-400">{label}</div>
                        <input type={type} value={cForm[key]}
                          onChange={e => setCForm(f => ({ ...f, [key]: e.target.value }))}
                          placeholder={ph || ''}
                          className="w-full rounded-xl border border-slate-700 bg-slate-900 px-3 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>
                    ))}
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Version</div>
                      <Select value={cForm.version} onChange={e => setCForm(f => ({ ...f, version: e.target.value }))}>
                        {['current','new','proposed','old','reverted'].map(v => <option key={v} value={v}>{v}</option>)}
                      </Select>
                    </div>
                    <div>
                      <div className="mb-1 text-xs font-semibold text-slate-400">Status</div>
                      <Select value={cForm.status} onChange={e => setCForm(f => ({ ...f, status: e.target.value }))}>
                        {['active','draft','expired','negotiating','reverted'].map(v => <option key={v} value={v}>{v}</option>)}
                      </Select>
                    </div>
                    <div className="flex items-center gap-2 mt-4">
                      <input type="checkbox" id="ar" checked={cForm.autoRenew}
                        onChange={e => setCForm(f => ({ ...f, autoRenew: e.target.checked }))}
                        className="h-4 w-4 accent-blue-500" />
                      <label htmlFor="ar" className="text-sm text-slate-300">Auto-renews</label>
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Key terms</div>
                      <Textarea rows={2} value={cForm.terms}
                        onChange={e => setCForm(f => ({ ...f, terms: e.target.value }))}
                        placeholder="Key clauses, pricing, conditions…" />
                    </div>
                    <div className="lg:col-span-3">
                      <div className="mb-1 text-xs font-semibold text-slate-400">Notes</div>
                      <Textarea rows={2} value={cForm.notes}
                        onChange={e => setCForm(f => ({ ...f, notes: e.target.value }))}
                        placeholder="Internal notes…" />
                    </div>
                  </div>
                  <div className="mt-4 flex justify-end gap-2">
                    <Button variant="secondary" onClick={() => { setShowAddContract(false); resetCForm(); }}>Cancel</Button>
                    <Button disabled={!cForm.vendor.trim()} onClick={saveContract}>
                      <Check className="h-4 w-4" /> {cForm.id ? 'Save' : 'Add'}
                    </Button>
                  </div>
                </CardBody>
              </Card>
            )}

            {contracts.length === 0 ? (
              <EmptyState icon={FileText} title="No contracts" body="Add contracts to compare them side-by-side." />
            ) : (
              <Card>
                <CardHeader
                  title="Select contracts to compare"
                  subtitle="Check 2 contracts then click Compare"
                  right={compareIds.length === 2 && (
                    <Button size="sm" onClick={() => {}}>
                      <ArrowLeftRight className="h-4 w-4" /> Compare selected
                    </Button>
                  )}
                />
                <CardBody>
                  <div className="overflow-x-auto rounded-xl border border-slate-800 mb-5">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b border-slate-800 bg-slate-950/60">
                          <th className="px-3 py-3 w-8"></th>
                          {['Vendor','Tool','Version','Value','Expires','Status',''].map(h => (
                            <th key={h} className="px-4 py-3 text-left text-slate-400 font-semibold">{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {contracts.map(c => {
                          const sel = compareIds.includes(c.id);
                          const days = c.endDate ? Math.ceil((new Date(c.endDate) - new Date()) / 86400000) : null;
                          return (
                            <tr key={c.id} className={cx("border-b border-slate-800/50 transition-colors", sel ? "bg-blue-600/10" : "hover:bg-slate-800/30")}>
                              <td className="px-3 py-3 text-center">
                                <input type="checkbox" checked={sel} onChange={() => toggleCompare(c.id)} className="h-4 w-4 accent-blue-500" />
                              </td>
                              <td className="px-4 py-3 font-semibold text-white">{c.vendor}</td>
                              <td className="px-4 py-3 text-slate-300">{c.tool}</td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                                  c.version==='current'?'bg-blue-500/20 text-blue-400':
                                  c.version==='new'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400'
                                )}>{c.version}</span>
                              </td>
                              <td className="px-4 py-3 text-slate-300">{c.value||'—'}</td>
                              <td className="px-4 py-3">
                                <div className="text-slate-300 text-xs">{c.endDate||'—'}</div>
                                {days!==null && <div className={cx("text-xs font-semibold", days<0?'text-rose-400':days<=30?'text-amber-400':'text-slate-600')}>{days<0?`${Math.abs(days)}d over`:`${days}d`}</div>}
                              </td>
                              <td className="px-4 py-3">
                                <span className={cx("px-2 py-0.5 rounded-full text-xs font-semibold",
                                  c.status==='active'?'bg-emerald-500/20 text-emerald-400':'bg-slate-500/20 text-slate-400'
                                )}>{c.status}</span>
                              </td>
                              <td className="px-4 py-3">
                                <div className="flex gap-1">
                                  <Button size="sm" variant="secondary" onClick={() => { setCForm({...c}); setShowAddContract(true); }}><Pencil className="h-3 w-3" /></Button>
                                  <Button size="sm" variant="danger" onClick={() => { saveContracts(contracts.filter(x=>x.id!==c.id)); setCompareIds(p=>p.filter(i=>i!==c.id)); }}><Trash2 className="h-3 w-3" /></Button>
                                </div>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>

                  {/* Side-by-side diff */}
                  {cmpContracts.length === 2 && (
                    <div className="space-y-4">
                      <div className="grid grid-cols-3 gap-4">
                        <div className="text-xs font-semibold text-slate-500 uppercase pt-3">Field</div>
                        {cmpContracts.map((c,i) => (
                          <div key={c.id} className={cx("rounded-xl border p-4", i===0?'border-blue-600/40':'border-emerald-600/40')}>
                            <div className="flex items-center gap-2">
                              <span className={cx("h-3 w-3 rounded-full", i===0?'bg-blue-500':'bg-emerald-500')} />
                              <span className="font-bold text-white">{c.vendor}</span>
                            </div>
                            <div className="text-xs text-slate-400 mt-1">{c.tool} · {c.version}</div>
                          </div>
                        ))}
                      </div>
                      {CFIELDS.map(({ key, label, render }) => {
                        const vals = cmpContracts.map(c => render ? render(c[key]) : String(c[key]||''));
                        const diff = vals[0] !== vals[1];
                        return (
                          <div key={key} className={cx("grid grid-cols-3 gap-4 px-3 py-3 rounded-xl",
                            diff ? 'bg-amber-500/10 border border-amber-500/20' : 'hover:bg-slate-800/20'
                          )}>
                            <div className="flex items-center gap-2 text-sm font-semibold text-slate-400">
                              {diff && <span className="h-2 w-2 rounded-full bg-amber-400 flex-shrink-0" />}
                              {label}
                            </div>
                            {vals.map((v,i) => (
                              <div key={i} className={cx("text-sm break-words", diff?(i===0?'text-blue-300':'text-emerald-300'):'text-slate-300')}>
                                {v || <span className="text-slate-600 italic">—</span>}
                              </div>
                            ))}
                          </div>
                        );
                      })}
                      {/* Differences badge */}
                      {(() => {
                        const diffs = CFIELDS.filter(({ key, render }) => {
                          const vs = cmpContracts.map(c => render?render(c[key]):String(c[key]||''));
                          return vs[0]!==vs[1];
                        });
                        return (
                          <div className={cx("rounded-xl border p-4", diffs.length?'border-amber-500/30':'border-emerald-500/30')}>
                            <div className="font-semibold text-white mb-2">{diffs.length} difference{diffs.length!==1?'s':''} found</div>
                            {diffs.length > 0 ? (
                              <div className="flex flex-wrap gap-2">
                                {diffs.map(({label}) => (
                                  <span key={label} className="px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-400">{label}</span>
                                ))}
                              </div>
                            ) : (
                              <div className="text-emerald-400 text-sm">Both contracts are identical.</div>
                            )}
                            <div className="mt-4 flex gap-2">
                              {cmpContracts.map(c => (
                                <Button key={c.id} size="sm" variant="secondary" onClick={() => {
                                  saveContracts([{...c, id:`c_${Date.now()}`, version:'reverted', status:'reverted', notes:`Reverted on ${todayISO()}`}, ...contracts]);
                                }}>
                                  <RefreshCw className="h-3 w-3" /> Revert to "{c.vendor} {c.version}"
                                </Button>
                              ))}
                            </div>
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

        {/* ══ TAB: AI ANALYSIS ══════════════════════════════════════ */}
        {tab === 'ai' && (
          <div className="space-y-5">
            {/* Upload row */}
            <div className="grid gap-5 md:grid-cols-2">
              {[
                { label: 'Contract 1', name: doc1Name, setName: setDoc1Name, setContent: setDoc1, content: doc1 },
                { label: 'Contract 2', name: doc2Name, setName: setDoc2Name, setContent: setDoc2, content: doc2 },
              ].map(({ label, name, setName, setContent, content }, idx) => (
                <Card key={label} className={content ? 'border-blue-600/30' : ''}>
                  <CardBody>
                    <div className="text-sm font-semibold text-slate-400 mb-3">{label}</div>
                    {name ? (
                      <div className="flex items-center gap-3 p-3 rounded-xl border border-slate-700 bg-slate-900/40">
                        <FileText className="h-8 w-8 text-blue-400 flex-shrink-0" />
                        <div className="min-w-0">
                          <div className="font-medium text-white text-sm truncate">{name}</div>
                          <div className="text-xs text-slate-500">{content.length.toLocaleString()} characters</div>
                        </div>
                        <Button size="sm" variant="secondary" onClick={() => { setName(''); setContent(''); }}>
                          <X className="h-3 w-3" />
                        </Button>
                      </div>
                    ) : (
                      <label className="flex flex-col items-center justify-center h-32 rounded-xl border-2 border-dashed border-slate-700 hover:border-blue-500 transition-colors cursor-pointer bg-slate-900/20 hover:bg-slate-800/20">
                        <Paperclip className="h-8 w-8 text-slate-500 mb-2" />
                        <span className="text-sm text-slate-400">Upload .txt or .md file</span>
                        <span className="text-xs text-slate-600 mt-1">or paste text below</span>
                        <input type="file" className="hidden" accept=".txt,.md,.csv"
                          onChange={e => e.target.files?.[0] && readFile(e.target.files[0], setName, setContent)} />
                      </label>
                    )}
                    <div className="mt-3">
                      <Textarea rows={4} value={content}
                        onChange={e => { setContent(e.target.value); if(!name) setName('Pasted text'); }}
                        placeholder={`Paste ${label.toLowerCase()} text here…`}
                        className="font-mono text-xs" />
                    </div>
                  </CardBody>
                </Card>
              ))}
            </div>

            {/* Generate button */}
            <div className="flex justify-center">
              <Button
                disabled={!doc1.trim() || !doc2.trim() || aiLoading}
                onClick={runAiComparison}
                className="px-8"
              >
                {aiLoading
                  ? <><RefreshCw className="h-4 w-4 animate-spin" /> Analysing contracts…</>
                  : <><Sparkles className="h-4 w-4" /> Generate AI Comparison</>
                }
              </Button>
            </div>

            {aiError && (
              <div className="rounded-xl border border-rose-500/30 bg-rose-500/10 p-4 text-rose-400 text-sm">{aiError}</div>
            )}

            {/* AI Results */}
            {aiResult && (
              <div className="space-y-5">
                {/* Verdict */}
                <Card className="border-blue-600/30">
                  <CardBody>
                    <div className="flex items-start gap-3">
                      <Bot className="h-6 w-6 text-blue-400 flex-shrink-0 mt-0.5" />
                      <div>
                        <div className="text-xs font-semibold uppercase tracking-widest text-blue-400 mb-1">AI Verdict</div>
                        <div className="text-white font-semibold">{aiResult.verdict}</div>
                        <div className="text-slate-400 text-sm mt-1">{aiResult.summary}</div>
                      </div>
                    </div>
                  </CardBody>
                </Card>

                <div className="grid gap-5 lg:grid-cols-2">
                  {/* Differences */}
                  <Card>
                    <CardHeader title={`${aiResult.differences?.length || 0} Differences Found`} subtitle="Field-by-field comparison" />
                    <CardBody>
                      <div className="space-y-3">
                        {(aiResult.differences || []).map((d, i) => (
                          <div key={i} className={cx("rounded-xl border p-3", sevColor(d.severity))}>
                            <div className="flex items-center justify-between mb-2">
                              <span className="font-semibold text-sm text-white">{d.field}</span>
                              <span className={cx("px-2 py-0.5 rounded-full text-xs font-bold border", sevColor(d.severity))}>
                                {d.severity}
                              </span>
                            </div>
                            <div className="grid grid-cols-2 gap-3 text-xs mb-2">
                              <div>
                                <div className="text-blue-400 font-semibold mb-1">{doc1Name || 'Doc 1'}</div>
                                <div className="text-slate-300">{d.doc1 || '—'}</div>
                              </div>
                              <div>
                                <div className="text-emerald-400 font-semibold mb-1">{doc2Name || 'Doc 2'}</div>
                                <div className="text-slate-300">{d.doc2 || '—'}</div>
                              </div>
                            </div>
                            {d.recommendation && (
                              <div className="text-xs text-slate-400 border-t border-slate-700 pt-2 mt-1">
                                💡 {d.recommendation}
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    </CardBody>
                  </Card>

                  {/* Risks + Recommendations */}
                  <div className="space-y-5">
                    <Card>
                      <CardHeader title="Risks Identified" />
                      <CardBody>
                        <div className="space-y-2">
                          {(aiResult.risks || []).map((r, i) => (
                            <div key={i} className="flex items-start gap-2 text-sm">
                              <AlertTriangle className="h-4 w-4 text-amber-400 flex-shrink-0 mt-0.5" />
                              <span className="text-slate-300">{r}</span>
                            </div>
                          ))}
                        </div>
                      </CardBody>
                    </Card>
                    <Card>
                      <CardHeader title="Recommendations" />
                      <CardBody>
                        <div className="space-y-2">
                          {(aiResult.recommendations || []).map((r, i) => (
                            <div key={i} className="flex items-start gap-2 text-sm">
                              <CheckCircle className="h-4 w-4 text-emerald-400 flex-shrink-0 mt-0.5" />
                              <span className="text-slate-300">{r}</span>
                            </div>
                          ))}
                        </div>
                      </CardBody>
                    </Card>
                  </div>
                </div>

                {/* AI Chat */}
                <Card>
                  <CardHeader
                    title="Ask the AI"
                    subtitle="Ask follow-up questions about the contracts"
                    right={<Pill tone="blue" icon={Bot}>AI Advisor</Pill>}
                  />
                  <CardBody>
                    <div className="space-y-3 max-h-80 overflow-y-auto mb-4 pr-1">
                      {chatMessages.map((m, i) => (
                        <div key={i} className={cx("flex gap-3", m.role === 'user' ? "flex-row-reverse" : "")}>
                          <div className={cx("h-7 w-7 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-bold",
                            m.role === 'user' ? "bg-blue-600 text-white" : "bg-slate-700 text-slate-300"
                          )}>
                            {m.role === 'user' ? 'U' : <Bot className="h-4 w-4" />}
                          </div>
                          <div className={cx("rounded-2xl px-4 py-3 text-sm max-w-[80%]",
                            m.role === 'user' ? "bg-blue-600/20 text-white" : "bg-slate-800 text-slate-200"
                          )}>
                            {m.content}
                          </div>
                        </div>
                      ))}
                      {chatLoading && (
                        <div className="flex gap-3">
                          <div className="h-7 w-7 rounded-full bg-slate-700 flex items-center justify-center">
                            <Bot className="h-4 w-4 text-slate-300" />
                          </div>
                          <div className="rounded-2xl px-4 py-3 bg-slate-800 text-slate-400 text-sm">
                            <RefreshCw className="h-4 w-4 animate-spin inline" />
                          </div>
                        </div>
                      )}
                    </div>
                    <div className="flex gap-2">
                      <input
                        value={chatInput}
                        onChange={e => setChatInput(e.target.value)}
                        onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendChat()}
                        placeholder="Ask about specific clauses, risks, negotiation tactics…"
                        className="flex-1 rounded-xl border border-slate-700 bg-slate-900 px-4 py-2 text-sm text-slate-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <Button disabled={!chatInput.trim() || chatLoading} onClick={sendChat}>
                        <Send className="h-4 w-4" />
                      </Button>
                    </div>
                    <div className="mt-2 flex flex-wrap gap-2">
                      {[
                        'Which contract has better SLA terms?',
                        'What should I negotiate on?',
                        'What are the biggest risks?',
                        'Which is better value?',
                      ].map(q => (
                        <button key={q} onClick={() => { setChatInput(q); }}
                          className="text-xs px-3 py-1 rounded-full border border-slate-700 text-slate-400 hover:border-blue-500 hover:text-blue-400 transition-colors">
                          {q}
                        </button>
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

'''

insert_at = app.find('export default function App()')
if insert_at != -1:
    app = app[:insert_at] + CONTRACT_PAGE + app[insert_at:]
    ok.append("ContractComparisonPage: injected")

# ── 8. Add route ──────────────────────────────────────────────
if '<ContractComparisonPage />' not in app:
    app = app.replace(
        '          <Route path="*" element={<NotFound />} />',
        '          <Route path="/contracts" element={<RequireAuth><ContractComparisonPage /></RequireAuth>} />\n          <Route path="*" element={<NotFound />} />'
    )
    ok.append("Router: /contracts route added")

# ── Report ────────────────────────────────────────────────────
print()
for s in ok:   print(f"  \033[32m✓\033[0m  {s}")
for s in warn: print(f"  \033[33m!\033[0m  {s}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print(f"\n  Done — {app.count(chr(10))} lines")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# translations
python3 - << 'PYEOF'
import os
path = 'src/translations.js'
if not os.path.exists(path): exit()
with open(path, encoding='utf-8') as f: src = f.read()
for lang, val in {'en':'Contracts','es':'Contratos','fr':'Contrats','de':'Verträge','ja':'契約管理'}.items():
    ls = src.find(f'{lang}: {{')
    le = src.find('\n  },', ls)
    if '    contracts:' not in src[ls:le]:
        ins = src.find('\n', src.find(f'{lang}: {{')) + 1
        src = src[:ins] + f"    contracts: '{val}',\n" + src[ins:]
        print(f"  \033[32m✓\033[0m  {lang}: contracts key added")
with open(path, 'w', encoding='utf-8') as f: f.write(src)
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }

echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  ✓ Deployed! AI Contract page is live.                   ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  STACK OVERFLOW — fixed (stale listeners removed)        ║"
echo -e "║  CONTRACTS — 3-tab page:                                 ║"
echo -e "║    📋 Negotiation Tracker                                ║"
echo -e "║       Table with Customer, Assignee, ARR, Deadline,      ║"
echo -e "║       Currently With, Sales Person, Status               ║"
echo -e "║       Legal Pipeline kanban by stage                     ║"
echo -e "║    ⇄  Side-by-side Contract Comparison                   ║"
echo -e "║       Field diff with amber highlights + revert          ║"
echo -e "║    🤖 AI Analysis (Claude API)                           ║"
echo -e "║       Upload/paste 2 contracts → AI compares them        ║"
echo -e "║       Severity-coded differences (high/med/low)          ║"
echo -e "║       Risks + recommendations                            ║"
echo -e "║       Follow-up chat with AI contract advisor            ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
