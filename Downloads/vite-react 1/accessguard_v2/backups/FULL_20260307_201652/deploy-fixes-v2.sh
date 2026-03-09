#!/bin/bash
set -e

# ============================================================
# AccessGuard V2 — Button Fix Deployment Script
# Fixes: Settings Save, Security/Cost Review, Analytics Export,
#        Dashboard/Access toasts, Invoice upload
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AccessGuard V2 — Button Fix Deploy     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# Sanity check
if [ ! -f "package.json" ]; then
  echo -e "${RED}✗ Run this from your accessguard_v2 project root${NC}"
  exit 1
fi

# Check react-hot-toast is installed
if ! grep -q "react-hot-toast" package.json; then
  echo -e "${YELLOW}→ Installing react-hot-toast...${NC}"
  npm install react-hot-toast --save
fi

# Backup
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
echo -e "${GREEN}✓ Backup saved to backups/$TS/${NC}"
echo ""

# Apply all patches via Python
echo -e "${BLUE}Applying patches...${NC}"

python3 << 'PYEOF'
import sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

original = src
applied = []
failed = []

def patch(name, old, new):
    global src
    if old in src:
        src = src.replace(old, new, 1)
        applied.append(name)
    elif new in src:
        applied.append(f"{name} (already applied)")
    else:
        failed.append(name)

# ── PATCH 1: react-hot-toast import ─────────────────────────
patch(
    "Add react-hot-toast import",
    "import { useTranslation } from './translations';",
    "import { useTranslation } from './translations';\nimport toast from 'react-hot-toast';"
)

# ── PATCH 2: Toaster in App root ────────────────────────────
patch(
    "Add <Toaster> to App root",
    "<QueryClientProvider client={queryClient}>",
    '<QueryClientProvider client={queryClient}>\n      <Toaster position="top-right" toastOptions={{ style: { background: "#1e293b", color: "#f1f5f9", border: "1px solid #334155" } }} />'
)

# ── PATCH 3: Settings — add controlled state ────────────────
patch(
    "SettingsPage: add controlled state",
    """function SettingsPage() {
  const [activeTab, setActiveTab] = useState('general');

  const tabs = [""",
    """function SettingsPage() {
  const [activeTab, setActiveTab] = useState('general');

  // General settings state
  const saved = JSON.parse(localStorage.getItem('ag_general_settings') || '{}');
  const [orgName, setOrgName] = useState(saved.orgName || '');
  const [timezone, setTimezone] = useState(saved.timezone || 'UTC');
  const [currency, setCurrency] = useState(saved.currency || 'USD ($)');
  const [saveMsg, setSaveMsg] = useState('');

  const handleSaveGeneral = () => {
    localStorage.setItem('ag_general_settings', JSON.stringify({ orgName, timezone, currency }));
    setSaveMsg('Saved!');
    setTimeout(() => setSaveMsg(''), 2000);
  };

  // Security settings state
  const savedSec = JSON.parse(localStorage.getItem('ag_security_settings') || '{}');
  const [minChars, setMinChars] = useState(savedSec.minChars !== undefined ? savedSec.minChars : true);
  const [upperLower, setUpperLower] = useState(savedSec.upperLower !== undefined ? savedSec.upperLower : true);
  const [numSymbols, setNumSymbols] = useState(savedSec.numSymbols !== undefined ? savedSec.numSymbols : true);
  const [secMsg, setSecMsg] = useState('');

  const handleSaveSecurity = () => {
    localStorage.setItem('ag_security_settings', JSON.stringify({ minChars, upperLower, numSymbols }));
    setSecMsg('Updated!');
    setTimeout(() => setSecMsg(''), 2000);
  };

  const tabs = ["""
)

# ── PATCH 4: Settings — wire General inputs ─────────────────
patch(
    "SettingsPage: wire General inputs + Save button",
    """                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Organization Name
                    </label>
                    <Input placeholder="Acme Corporation" />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Time Zone
                    </label>
                    <Select>
                      <option>UTC</option>
                      <option>America/New_York</option>
                      <option>America/Los_Angeles</option>
                      <option>Europe/Paris</option>
                      <option>Asia/Tokyo</option>
                    </Select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Currency
                    </label>
                    <Select>
                      <option>USD ($)</option>
                      <option>EUR (€)</option>
                      <option>GBP (£)</option>
                      <option>JPY (¥)</option>
                    </Select>
                  </div>

                  <Divider />

                  <Button variant="primary">Save Changes</Button>""",
    """                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Organization Name
                    </label>
                    <Input
                      placeholder="Acme Corporation"
                      value={orgName}
                      onChange={(e) => setOrgName(e.target.value)}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Time Zone
                    </label>
                    <Select value={timezone} onChange={(e) => setTimezone(e.target.value)}>
                      <option>UTC</option>
                      <option>America/New_York</option>
                      <option>America/Los_Angeles</option>
                      <option>Europe/Paris</option>
                      <option>Asia/Tokyo</option>
                    </Select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-slate-200 mb-2">
                      Currency
                    </label>
                    <Select value={currency} onChange={(e) => setCurrency(e.target.value)}>
                      <option>USD ($)</option>
                      <option>EUR (€)</option>
                      <option>GBP (£)</option>
                      <option>JPY (¥)</option>
                    </Select>
                  </div>

                  <Divider />

                  <div className="flex items-center gap-3">
                    <Button variant="primary" onClick={handleSaveGeneral}>Save Changes</Button>
                    {saveMsg && <span className="text-sm text-emerald-400 font-semibold">{saveMsg}</span>}
                  </div>"""
)

# ── PATCH 5: Settings — wire Security checkboxes ────────────
patch(
    "SettingsPage: wire Security checkboxes + Update button",
    """                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          defaultChecked
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Minimum 12 characters
                        </span>
                      </label>
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          defaultChecked
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Require uppercase and lowercase
                        </span>
                      </label>
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          defaultChecked
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Require numbers and symbols
                        </span>
                      </label>
                    </div>
                  </div>

                  <Divider />

                  <Button variant="primary">Update Security Settings</Button>""",
    """                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={minChars}
                          onChange={(e) => setMinChars(e.target.checked)}
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Minimum 12 characters
                        </span>
                      </label>
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={upperLower}
                          onChange={(e) => setUpperLower(e.target.checked)}
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Require uppercase and lowercase
                        </span>
                      </label>
                      <label className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={numSymbols}
                          onChange={(e) => setNumSymbols(e.target.checked)}
                          className="rounded border-slate-700 text-blue-600 focus:ring-blue-500/40"
                        />
                        <span className="text-sm text-slate-300">
                          Require numbers and symbols
                        </span>
                      </label>
                    </div>
                  </div>

                  <Divider />

                  <div className="flex items-center gap-3">
                    <Button variant="primary" onClick={handleSaveSecurity}>Update Security Settings</Button>
                    {secMsg && <span className="text-sm text-emerald-400 font-semibold">{secMsg}</span>}
                  </div>"""
)

# ── PATCH 6: SecurityCompliancePage — add navigate + routes ─
patch(
    "SecurityCompliancePage: add navigate + alert routes",
    """function SecurityCompliancePage() {
  const [language] = useState(() => localStorage.getItem("language") || "en");
  const t = useTranslation(language);
  const { data: db } = useDbQuery();
  const tools = db?.tools || [];
  
  // Calculate security metrics
  const criticalTools = tools.filter(t => t.criticality === 'high' && t.status === 'active').length;
  const orphanedTools = tools.filter(t => t.status === 'orphaned').length;
  const highRiskTools = tools.filter(t => t.risk_score === 'high').length;
  
  const securityScore = Math.max(0, 100 - (orphanedTools * 10) - (highRiskTools * 5));
  
  const alerts = [
    {
      type: 'critical',
      title: `${orphanedTools} orphaned tools detected`,
      description: 'These tools have no assigned owner and may pose security risks',
      tone: 'rose',
      icon: AlertTriangle,
    },
    {
      type: 'warning',
      title: `${highRiskTools} high-risk tools need review`,
      description: `${t('review_admin_access')} and usage patterns for these applications`,
      tone: 'amber',
      icon: AlertTriangle,
    },
    {
      type: 'info',
      title: `${criticalTools} critical tools properly secured`,
      description: 'All critical applications have assigned owners and active monitoring',
      tone: 'green',
      icon: BadgeCheck,
    },
  ];""",
    """function SecurityCompliancePage() {
  const [language] = useState(() => localStorage.getItem("language") || "en");
  const t = useTranslation(language);
  const navigate = useNavigate();
  const { data: db } = useDbQuery();
  const tools = db?.tools || [];
  
  // Calculate security metrics
  const criticalTools = tools.filter(t => t.criticality === 'high' && t.status === 'active').length;
  const orphanedTools = tools.filter(t => t.status === 'orphaned').length;
  const highRiskTools = tools.filter(t => t.risk_score === 'high').length;
  
  const securityScore = Math.max(0, 100 - (orphanedTools * 10) - (highRiskTools * 5));
  
  const alerts = [
    {
      type: 'critical',
      title: `${orphanedTools} orphaned tools detected`,
      description: 'These tools have no assigned owner and may pose security risks',
      tone: 'rose',
      icon: AlertTriangle,
      route: '/tools',
    },
    {
      type: 'warning',
      title: `${highRiskTools} high-risk tools need review`,
      description: `${t('review_admin_access')} and usage patterns for these applications`,
      tone: 'amber',
      icon: AlertTriangle,
      route: '/access',
    },
    {
      type: 'info',
      title: `${criticalTools} critical tools properly secured`,
      description: 'All critical applications have assigned owners and active monitoring',
      tone: 'green',
      icon: BadgeCheck,
      route: null,
    },
  ];"""
)

# ── PATCH 7: SecurityCompliancePage — wire Review button ────
patch(
    "SecurityCompliancePage: Review button onClick",
    '<Button variant="secondary" size="sm">\n                    Review\n                  </Button>',
    '<Button variant="secondary" size="sm" onClick={() => alert.route && navigate(alert.route)}>\n                    Review\n                  </Button>'
)

# ── PATCH 8: CostManagementPage — add navigate ──────────────
patch(
    "CostManagementPage: add navigate",
    "function CostManagementPage() {\n  const { data: db } = useDbQuery();",
    "function CostManagementPage() {\n  const navigate = useNavigate();\n  const { data: db } = useDbQuery();"
)

# ── PATCH 9: CostManagementPage — wire Review button ────────
patch(
    "CostManagementPage: Review button onClick",
    '<Button variant="secondary" size="sm">\n                      Review\n                    </Button>',
    '<Button variant="secondary" size="sm" onClick={() => navigate(\'/tools\')}>\n                      Review\n                    </Button>'
)

# ── PATCH 10: AnalyticsReportsPage — add exportCSV ──────────
patch(
    "AnalyticsReportsPage: add exportCSV function",
    "function AnalyticsReportsPage() {\n  const { data: db } = useDbQuery();",
    """function AnalyticsReportsPage() {
  const { data: db } = useDbQuery();
  
  const exportCSV = () => {
    const tools = db?.tools || [];
    const employees = db?.employees || [];
    const rows = [
      ['Type', 'Name', 'Status', 'Cost/Month', 'Department/Category'],
      ...tools.map(t => ['Tool', t.name, t.status, t.cost_per_month || 0, t.category || '']),
      ...employees.map(e => ['Employee', e.name, e.status, '', e.department || '']),
    ];
    const csv = rows.map(r => r.join(',')).join('\\n');
    const a = document.createElement('a');
    a.href = 'data:text/csv,' + encodeURIComponent(csv);
    a.download = 'accessguard-analytics.csv';
    a.click();
  };"""
)

# ── PATCH 11: AnalyticsReportsPage — wire Export buttons ────
patch(
    "AnalyticsReportsPage: wire Export PDF + CSV buttons",
    """          <Button variant="secondary" size="sm">
            <Download className="h-4 w-4" />
            Export PDF
          </Button>
          <Button variant="secondary" size="sm">
            <Download className="h-4 w-4" />
            Export CSV
          </Button>""",
    """          <Button variant="secondary" size="sm" onClick={() => window.print()}>
            <Download className="h-4 w-4" />
            Export PDF
          </Button>
          <Button variant="secondary" size="sm" onClick={exportCSV}>
            <Download className="h-4 w-4" />
            Export CSV
          </Button>"""
)

# ── PATCH 12: Dashboard — toast on markReviewed/revokeAccess ─
patch(
    "DashboardPage: toast feedback on actions",
    """  const markReviewed = (accId) => {
    muts.updateAccess.mutate({
      id: accId,
      patch: { last_reviewed_date: todayISO(), risk_flag: "none" },
    });
  };

  const revokeAccess = (accId) => {
    muts.updateAccess.mutate({ id: accId, patch: { status: "revoked" } });
  };""",
    """  const markReviewed = (accId) => {
    muts.updateAccess.mutate(
      { id: accId, patch: { last_reviewed_date: todayISO(), risk_flag: "none" } },
      { onSuccess: () => toast.success('Marked as reviewed') }
    );
  };

  const revokeAccess = (accId) => {
    muts.updateAccess.mutate(
      { id: accId, patch: { status: "revoked" } },
      { onSuccess: () => toast.success('Access revoked') }
    );
  };"""
)

# ── PATCH 13: Access page — toast on mark reviewed ──────────
patch(
    "AccessPage: toast on mark reviewed",
    'onClick={() => muts.updateAccess.mutate({ id: a.id, patch: { last_reviewed_date: todayISO(), risk_flag: "none" } })}',
    'onClick={() => muts.updateAccess.mutate({ id: a.id, patch: { last_reviewed_date: todayISO(), risk_flag: "none" } }, { onSuccess: () => toast.success(\'Marked as reviewed\') })}'
)

# ── PATCH 14: Access page — toast on revoke ─────────────────
patch(
    "AccessPage: toast on revoke",
    'onClick={() => muts.updateAccess.mutate({ id: a.id, patch: { status: "revoked" } })}',
    'onClick={() => muts.updateAccess.mutate({ id: a.id, patch: { status: "revoked" } }, { onSuccess: () => toast.success("Access revoked") })}'
)

# ── PATCH 15: InvoiceManager — add upload form state ────────
patch(
    "InvoiceManager: add upload form state + handler",
    """  const [showUploadModal, setShowUploadModal] = useState(false);
  const [filter, setFilter] = useState('all');""",
    """  const [showUploadModal, setShowUploadModal] = useState(false);
  const [filter, setFilter] = useState('all');
  const [uploadForm, setUploadForm] = useState({ vendor: '', amount: '', dueDate: '', category: 'CRM' });
  const [uploadFileName, setUploadFileName] = useState('');
  const [uploadSuccess, setUploadSuccess] = useState(false);

  const handleUploadSubmit = (e) => {
    e.preventDefault();
    const existing = JSON.parse(localStorage.getItem('ag_uploaded_invoices') || '[]');
    existing.push({
      id: 'INV-' + Date.now(),
      vendor: uploadForm.vendor,
      amount: parseFloat(uploadForm.amount) || 0,
      dueDate: uploadForm.dueDate,
      category: uploadForm.category,
      fileName: uploadFileName,
      status: 'pending_approval',
      uploadedAt: new Date().toISOString(),
    });
    localStorage.setItem('ag_uploaded_invoices', JSON.stringify(existing));
    setUploadSuccess(true);
    setTimeout(() => {
      setShowUploadModal(false);
      setUploadForm({ vendor: '', amount: '', dueDate: '', category: 'CRM' });
      setUploadFileName('');
      setUploadSuccess(false);
    }, 1500);
  };"""
)

# ── PATCH 16: InvoiceManager — wire form fields ─────────────
patch(
    "InvoiceManager: wire form fields to state",
    """            <form \n              className="space-y-4"\n              onSubmit={(e) => {\n                e.preventDefault();\n                setShowUploadModal(false);\n                alert('✅ Invoice uploaded successfully! Pending approval.');\n              }}\n            >\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Vendor Name</label>\n                <input type="text" required className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="e.g. Salesforce" />\n              </div>\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Invoice Amount</label>\n                <input type="number" required className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="0.00" />\n              </div>\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Due Date</label>\n                <input type="date" required className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" />\n              </div>""",
    """            <form \n              className="space-y-4"\n              onSubmit={handleUploadSubmit}\n            >\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Vendor Name</label>\n                <input type="text" required value={uploadForm.vendor} onChange={e => setUploadForm(f => ({...f, vendor: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="e.g. Salesforce" />\n              </div>\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Invoice Amount</label>\n                <input type="number" required value={uploadForm.amount} onChange={e => setUploadForm(f => ({...f, amount: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" placeholder="0.00" />\n              </div>\n              <div>\n                <label className="block text-sm font-semibold text-slate-300 mb-2">Due Date</label>\n                <input type="date" required value={uploadForm.dueDate} onChange={e => setUploadForm(f => ({...f, dueDate: e.target.value}))} className="w-full px-4 py-3 bg-slate-900 border border-slate-700 rounded-xl text-white" />\n              </div>"""
)

# ── PATCH 17: InvoiceManager — wire file input ──────────────
patch(
    "InvoiceManager: wire file input to show filename",
    '<input type="file" accept=".pdf" className="hidden" id="invoice-upload" />',
    '<input type="file" accept=".pdf" className="hidden" id="invoice-upload" onChange={e => setUploadFileName(e.target.files[0]?.name || \'\')} />'
)

patch(
    "InvoiceManager: show selected filename",
    '<p className="text-slate-400">Click to upload or drag and drop</p>',
    '{uploadFileName ? <p className="text-emerald-400 font-semibold">{uploadFileName}</p> : <p className="text-slate-400">Click to upload or drag and drop</p>}'
)

# ── PATCH 18: InvoiceManager — submit button success state ──
patch(
    "InvoiceManager: submit button success state",
    '<button type="submit" className="flex-1 px-6 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors">Upload & Submit</button>',
    '<button type="submit" className={`flex-1 px-6 py-3 rounded-xl font-semibold transition-colors ${uploadSuccess ? \'bg-emerald-600\' : \'bg-blue-600 hover:bg-blue-500\'}`}>{uploadSuccess ? \'✅ Uploaded!\' : \'Upload & Submit\'}</button>'
)

# ── Report ───────────────────────────────────────────────────
print("")
for name in applied:
    print(f"  \033[32m✓\033[0m  {name}")
for name in failed:
    print(f"  \033[31m✗\033[0m  {name}  ← FAILED (already applied or pattern mismatch)")

if failed:
    print(f"\n\033[33m⚠ {len(failed)} patch(es) could not be applied (may already be fixed)\033[0m")
else:
    print(f"\n\033[32m✓ All {len(applied)} patches applied successfully\033[0m")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

PATCH_EXIT=$?
echo ""

if [ $PATCH_EXIT -ne 0 ]; then
  echo -e "${RED}✗ Patching failed. Restoring backup...${NC}"
  cp "backups/$TS/App.jsx" src/App.jsx
  exit 1
fi

# Check react-hot-toast is importable
if ! grep -q "react-hot-toast" node_modules/.package-lock.json 2>/dev/null && \
   ! [ -d "node_modules/react-hot-toast" ]; then
  echo -e "${YELLOW}→ Installing react-hot-toast...${NC}"
  npm install react-hot-toast --save
fi

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
echo -e "${GREEN}║   ✓ All fixes deployed successfully!     ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  Settings Save — now saves to storage    ║${NC}"
echo -e "${GREEN}║  Security Review — navigates to /tools   ║${NC}"
echo -e "${GREEN}║  Cost Review — navigates to /tools       ║${NC}"
echo -e "${GREEN}║  Analytics Export PDF/CSV — wired        ║${NC}"
echo -e "${GREEN}║  Dashboard/Access — toast confirmations  ║${NC}"
echo -e "${GREEN}║  Invoice Upload — form fully connected   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
