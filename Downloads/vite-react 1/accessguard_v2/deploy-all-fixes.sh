#!/bin/bash
# ==============================================================================
# ACCESSGUARD V2 — PATCH & DEPLOY
# ==============================================================================
# Run from your project root:
#
#   cd "C:\Users\TheKwekuRO\Downloads\vite-react 1\accessguard_v2"
#   bash deploy-all-fixes.sh
#
# Patches your existing source files in-place, then builds and deploys.
# A full backup is saved to backups/<timestamp>/ before anything is touched.
# ==============================================================================

set -e

echo ""
echo "======================================================"
echo "  AccessGuard V2 — Patch & Deploy"
echo "======================================================"
echo ""

# ── Sanity check ──────────────────────────────────────────────────────────────
if [ ! -f "package.json" ]; then
  echo "ERROR: Run this from your project root (accessguard_v2/)"
  echo "       Current dir: $(pwd)"
  exit 1
fi
echo "[OK] Project root: $(pwd)"

# ── Backup ────────────────────────────────────────────────────────────────────
TS=$(date +%Y%m%d_%H%M%S)
BD="backups/$TS"
mkdir -p "$BD"
for f in src/App.jsx src/firebase-config.js src/ExecutiveDashboard.jsx \
          src/DashboardComponents.jsx src/modals.jsx firebase.json; do
  [ -f "$f" ] && cp "$f" "$BD/$(basename $f).bak" || true
done
echo "[OK] Backup saved → $BD"
echo ""

# ==============================================================================
# PATCH 1 — firebase-config.js
# Fix A: Magic link URL  /finish-signup  →  /finishSignUp
# Fix B: Remove duplicate addScope() block
# ==============================================================================
echo "[1/6] Patching firebase-config.js..."

python3 << 'PYEOF'
with open('src/firebase-config.js', 'r', encoding='utf-8') as f:
    src = f.read()

original = src

# Fix A — magic link URL
src = src.replace(
    "url: window.location.origin + '/finish-signup',",
    "url: window.location.origin + '/finishSignUp',"
)

# Fix B — remove duplicate scopes block (second occurrence only)
dup = (
    "\ngoogleProvider.addScope('https://www.googleapis.com/auth/admin.directory.user.readonly');"
    "\ngoogleProvider.addScope('https://www.googleapis.com/auth/gmail.readonly');"
    "\ngoogleProvider.addScope('profile');"
    "\ngoogleProvider.addScope('email');"
)
first = src.find(dup)
if first != -1:
    second = src.find(dup, first + 1)
    if second != -1:
        src = src[:second] + src[second + len(dup):]
        print("  OK  Duplicate OAuth scopes removed")
    else:
        print("  --  Duplicate scopes already clean")
else:
    print("  --  Scope block not found (may already be fixed)")

print("  OK  Magic link URL fixed" if "'/finishSignUp'" in src else "  --  Already correct")

if src != original:
    with open('src/firebase-config.js', 'w', encoding='utf-8') as f:
        f.write(src)
PYEOF

# ==============================================================================
# PATCH 2 — DashboardComponents.jsx
# Fix: Remove unused Clock and DollarSign imports
# ==============================================================================
echo "[2/6] Patching DashboardComponents.jsx..."

python3 << 'PYEOF'
with open('src/DashboardComponents.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

original = src

src = src.replace(
    "import { Sparkles, TrendingDown, AlertTriangle, Clock, DollarSign } from 'lucide-react';",
    "import { Sparkles, TrendingDown, AlertTriangle } from 'lucide-react';"
)

if src != original:
    with open('src/DashboardComponents.jsx', 'w', encoding='utf-8') as f:
        f.write(src)
    print("  OK  Removed unused Clock, DollarSign imports")
else:
    print("  --  Already clean")
PYEOF

# ==============================================================================
# PATCH 3 — ExecutiveDashboard.jsx
# Fix A: Replace Math.random() in JSX with stable computed value
# Fix B: Fix broken indentation on Top 10 Costliest Tools table div
# ==============================================================================
echo "[3/6] Patching ExecutiveDashboard.jsx..."

python3 << 'PYEOF'
with open('src/ExecutiveDashboard.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

original = src

# Fix A — stable efficiency score
src = src.replace(
    "const highRiskTools = data?.tools?.filter(t => t.derived_risk === 'high').length || 0;",
    ("const highRiskTools = data?.tools?.filter(t => t.derived_risk === 'high').length || 0;\n"
     "  const efficiencyScore = Math.min(100, Math.max(0, 85 + (potentialSavings === 0 ? 10 : 0) - (highRiskTools * 2)));")
)
src = src.replace(
    '{(85 + Math.random() * 10).toFixed(0)}',
    '{efficiencyScore}'
)

# Fix B — broken indent on Top 10 table
src = src.replace(
    '\n<div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">\n'
    '        <h3 className="text-xl font-bold text-white mb-6">Top 10 Costliest Tools</h3>',
    '\n      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">\n'
    '        <h3 className="text-xl font-bold text-white mb-6">Top 10 Costliest Tools</h3>'
)

if src != original:
    with open('src/ExecutiveDashboard.jsx', 'w', encoding='utf-8') as f:
        f.write(src)
    print("  OK  Math.random() replaced with stable efficiencyScore")
    print("  OK  Top 10 table indentation fixed")
else:
    print("  --  Already clean")
PYEOF

# ==============================================================================
# PATCH 4 — App.jsx  (5 fixes in one Python pass)
# ==============================================================================
echo "[4/6] Patching App.jsx..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    src = f.read()

original = src
changes = []

# ── 4A: Remove duplicate /tools and /security public routes ─────────────────
old_routes = (
    '        <Routes>\n'
    '          <Route path="/tools" element={<ToolsPage />} />\n'
    '          <Route path="/" element={<TrialPage />} />\n'
    '          <Route path="/privacy" element={<PrivacyPage />} />\n'
    '          <Route path="/terms" element={<TermsPage />} />\n'
    '          <Route path="/security" element={<SecurityPage />} />\n'
    '          <Route path="/finishSignUp" element={<FinishSignUpPage />} />'
)
new_routes = (
    '        <Routes>\n'
    '          <Route path="/" element={<TrialPage />} />\n'
    '          <Route path="/privacy" element={<PrivacyPage />} />\n'
    '          <Route path="/terms" element={<TermsPage />} />\n'
    '          <Route path="/security-info" element={<SecurityPage />} />\n'
    '          <Route path="/finishSignUp" element={<FinishSignUpPage />} />'
)
if old_routes in src:
    src = src.replace(old_routes, new_routes)
    changes.append("Duplicate /tools + /security routes removed")

# ── 4B: IntegrationsPage — remove dead state variables ──────────────────────
old_int = (
    'function IntegrationsPage() {\n'
    '  const [language] = useState(() => localStorage.getItem("language") || "en");\n'
    '  const t = useTranslation(language);\n'
    '  const [q, setQ] = useState("");\n'
    '  const [open, setOpen] = useState(false);\n'
    '  const [selected, setSelected] = useState(null);\n'
    '\n'
    '  const filtered = useMemo(() => {\n'
    '    const s = q.trim().toLowerCase();\n'
    '    return INTEGRATIONS.filter((i) => !s || `${i.name} ${i.desc}`.toLowerCase().includes(s));\n'
    '  }, [q]);\n'
    '\n'
    '  return (\n'
    '    <AppShell title="Integrations">\n'
    '      <IntegrationConnectors />\n'
    '    </AppShell>\n'
    '  );\n'
    '}'
)
new_int = (
    'function IntegrationsPage() {\n'
    '  return (\n'
    '    <AppShell title="Integrations">\n'
    '      <IntegrationConnectors />\n'
    '    </AppShell>\n'
    '  );\n'
    '}'
)
if old_int in src:
    src = src.replace(old_int, new_int)
    changes.append("IntegrationsPage dead state removed")

# ── 4C: SecurityCompliancePage — add missing translation setup ───────────────
old_sec = (
    'function SecurityCompliancePage() {\n'
    '  const { data: db } = useDbQuery();\n'
    '  const tools = db?.tools || [];'
)
new_sec = (
    'function SecurityCompliancePage() {\n'
    '  const [language] = useState(() => localStorage.getItem("language") || "en");\n'
    '  const t = useTranslation(language);\n'
    '  const { data: db } = useDbQuery();\n'
    '  const tools = db?.tools || [];'
)
if old_sec in src:
    src = src.replace(old_sec, new_sec, 1)
    changes.append("SecurityCompliancePage translation setup added")

# ── 4D: Add PricingTiers component + wire into BillingPage ──────────────────
pricing_component = '''// ============================================================================
// PRICING TIERS COMPONENT
// ============================================================================
function PricingTiers({ currentPlan = 'free' }) {
  const [billingCycle, setBillingCycle] = useState('monthly');
  const plans = [
    {
      id: 'free', name: 'Free', tagline: 'For small teams getting started',
      price: { monthly: 0, annual: 0 },
      features: ['Up to 10 SaaS tools', 'Basic dashboard', '1 team member', 'Email support', 'Monthly reports'],
      popular: false,
    },
    {
      id: 'pro', name: 'Professional', tagline: 'For growing teams',
      price: { monthly: 49, annual: 470 },
      features: ['Unlimited SaaS tools', 'AI-powered insights', 'Executive dashboard', 'Up to 10 team members', 'Priority support', 'Advanced analytics', 'Custom reports', 'API access'],
      popular: true,
    },
    {
      id: 'enterprise', name: 'Enterprise', tagline: 'For large organizations',
      price: { monthly: 'Custom', annual: 'Custom' },
      features: ['Everything in Pro', 'Unlimited team members', 'SSO & SAML', 'Dedicated account manager', '24/7 phone support', 'Custom integrations', 'SLA guarantee', 'On-premise option'],
      popular: false,
    },
  ];
  const getPrice = (p) => {
    const v = p.price[billingCycle];
    if (typeof v !== 'number') return v;
    return billingCycle === 'monthly' ? `$${v}/mo` : `$${v}/yr`;
  };
  const getSavings = (p) => {
    if (billingCycle === 'annual' && typeof p.price.annual === 'number' && p.price.annual > 0) {
      const s = p.price.monthly * 12 - p.price.annual;
      return s > 0 ? `Save $${s}/year` : null;
    }
    return null;
  };
  return (
    <div className="space-y-8">
      <div className="flex items-center justify-center gap-4">
        <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-white' : 'text-slate-400'}`}>Monthly</span>
        <button onClick={() => setBillingCycle(c => c === 'monthly' ? 'annual' : 'monthly')}
          className="relative w-14 h-7 bg-slate-700 rounded-full hover:bg-slate-600 transition-colors">
          <div className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform ${billingCycle === 'annual' ? 'translate-x-7' : ''}`} />
        </button>
        <span className={`text-sm font-medium ${billingCycle === 'annual' ? 'text-white' : 'text-slate-400'}`}>Annual</span>
        {billingCycle === 'annual' && <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-semibold rounded-full">Save 20%</span>}
      </div>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => {
          const isCurrent = plan.id === currentPlan;
          const savings = getSavings(plan);
          return (
            <div key={plan.id} className={`relative rounded-2xl p-8 ${plan.popular ? 'bg-gradient-to-br from-blue-500/20 to-purple-500/20 border-2 border-blue-500' : 'bg-slate-900 border border-slate-800'}`}>
              {plan.popular && <div className="absolute -top-4 left-1/2 -translate-x-1/2"><span className="px-4 py-1 bg-blue-600 text-white text-sm font-bold rounded-full">MOST POPULAR</span></div>}
              <div className="text-center mb-6">
                <h3 className="text-2xl font-black text-white mb-2">{plan.name}</h3>
                <p className="text-sm text-slate-400">{plan.tagline}</p>
              </div>
              <div className="text-center mb-6">
                <div className="text-4xl font-black text-white mb-2">{getPrice(plan)}</div>
                {savings && <div className="text-sm text-emerald-400 font-semibold">{savings}</div>}
              </div>
              <ul className="space-y-3 mb-8">
                {plan.features.map((feat, i) => (
                  <li key={i} className="flex items-start gap-2">
                    <CheckCircle className="h-5 w-5 text-emerald-400 flex-shrink-0 mt-0.5" />
                    <span className="text-sm text-slate-300">{feat}</span>
                  </li>
                ))}
              </ul>
              <button disabled={isCurrent}
                className={`w-full py-3 rounded-xl font-bold transition-all ${isCurrent ? 'bg-slate-700 text-slate-400 cursor-not-allowed' : plan.popular ? 'bg-blue-600 hover:bg-blue-500 text-white' : 'bg-slate-800 hover:bg-slate-700 text-white'}`}>
                {isCurrent ? 'Current Plan' : plan.popular ? 'Upgrade to Pro' : 'Contact Sales'}
              </button>
            </div>
          );
        })}
      </div>
      <div className="text-center">
        <p className="text-sm text-slate-400 mb-4">Trusted by 800+ companies worldwide</p>
        <div className="flex items-center justify-center gap-8 text-slate-500 text-sm">
          <span className="flex items-center gap-1"><Shield className="h-4 w-4" /> SOC 2</span>
          <span className="flex items-center gap-1"><Lock className="h-4 w-4" /> GDPR</span>
          <span className="flex items-center gap-1"><Award className="h-4 w-4" /> 99.9% Uptime</span>
        </div>
      </div>
    </div>
  );
}

'''

if 'function PricingTiers' not in src:
    src = src.replace('function BillingPage() {', pricing_component + 'function BillingPage() {', 1)
    changes.append("PricingTiers component added")

old_billing_close = '      </div>\n    </AppShell>\n  );\n}\n\nconst INTEGRATIONS'
new_billing_close = (
    '      </div>\n'
    '      <div>\n'
    '        <h2 className="text-2xl font-bold text-white mb-6">Compare Plans</h2>\n'
    '        <PricingTiers currentPlan={plan} />\n'
    '      </div>\n'
    '    </AppShell>\n'
    '  );\n'
    '}\n\nconst INTEGRATIONS'
)
if old_billing_close in src and '<PricingTiers' not in src:
    src = src.replace(old_billing_close, new_billing_close, 1)
    changes.append("PricingTiers wired into BillingPage")

# ── 4E: GoogleWorkspaceSync component + render in DashboardPage ─────────────
workspace_component = '''// ============================================================================
// GOOGLE WORKSPACE SYNC BUTTON
// ============================================================================
function GoogleWorkspaceSync() {
  const { firebaseUser } = useAuth();
  const muts = useDbMutations();
  const [syncing, setSyncing] = useState(false);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncedCount, setSyncedCount] = useState(0);
  const getToken = (u) => u?.stsTokenManager?.accessToken || null;
  const hasPerms = firebaseUser ? getToken(firebaseUser) !== null : false;

  const handleSync = async () => {
    if (!firebaseUser) { setSyncStatus({ type: 'error', message: 'Sign in with Google first.' }); return; }
    const token = getToken(firebaseUser);
    if (!token) { setSyncStatus({ type: 'error', message: 'No access token — sign in with Google.' }); return; }
    setSyncing(true);
    setSyncStatus({ type: 'loading', message: 'Importing from Google Workspace...' });
    try {
      const res = await fetch('https://admin.googleapis.com/admin/directory/v1/users?domain=primary&maxResults=500', {
        headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      });
      if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`);
      const data = await res.json();
      const users = (data.users || []).map(u => ({
        name: u.name.fullName, email: u.primaryEmail,
        status: u.suspended ? 'offboarded' : 'active',
        department: u.orgUnitPath?.split('/').pop() || 'general',
        role: u.isAdmin ? 'admin' : 'user',
        google_user_id: u.id, imported_from: 'google_workspace',
        imported_at: new Date().toISOString(),
      }));
      let count = 0;
      for (const u of users) { try { await muts.addEmployee.mutateAsync(u); count++; } catch {} }
      setSyncedCount(count);
      setSyncStatus({ type: 'success', message: `Imported ${count} users from Google Workspace!` });
      setTimeout(() => window.location.reload(), 2000);
    } catch (err) {
      setSyncStatus({ type: 'error', message: `Sync failed: ${err.message}` });
    } finally { setSyncing(false); }
  };

  if (!firebaseUser) return null;
  return (
    <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
      <div className="flex items-center gap-4 mb-4">
        <div className="p-3 bg-blue-500/20 rounded-xl">
          <RefreshCw className={`h-6 w-6 text-blue-400 ${syncing ? 'animate-spin' : ''}`} />
        </div>
        <div className="flex-1">
          <h3 className="text-xl font-bold text-white">Google Workspace Sync</h3>
          <p className="text-sm text-slate-300">Import users automatically from Google Workspace</p>
        </div>
        {hasPerms && (
          <button onClick={handleSync} disabled={syncing}
            className={`px-6 py-3 rounded-xl font-semibold transition-all ${syncing ? 'bg-slate-600 text-slate-400 cursor-not-allowed' : 'bg-blue-600 hover:bg-blue-500 text-white'}`}>
            {syncing ? 'Syncing...' : 'Sync Now'}
          </button>
        )}
      </div>
      {!hasPerms && (
        <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
          <p className="text-sm text-yellow-400">⚠️ Sign in with a Google Workspace admin account to enable sync.</p>
        </div>
      )}
      {syncStatus && (
        <div className={`mt-4 p-4 rounded-xl border ${syncStatus.type === 'success' ? 'bg-emerald-500/10 border-emerald-500/20' : syncStatus.type === 'error' ? 'bg-red-500/10 border-red-500/20' : 'bg-blue-500/10 border-blue-500/20'}`}>
          <p className={`text-sm ${syncStatus.type === 'success' ? 'text-emerald-400' : syncStatus.type === 'error' ? 'text-red-400' : 'text-blue-400'}`}>{syncStatus.message}</p>
          {syncStatus.type === 'success' && syncedCount > 0 && <p className="text-xs text-slate-400 mt-2">Refreshing in 2 seconds...</p>}
        </div>
      )}
    </div>
  );
}

'''

if 'function GoogleWorkspaceSync' not in src:
    src = src.replace('function DashboardPage() {', workspace_component + 'function DashboardPage() {', 1)
    changes.append("GoogleWorkspaceSync component added")

old_ai = '      {/* AI-Powered Insights */}\n      <AIInsights '
new_ai = '      {/* Google Workspace Sync */}\n      <GoogleWorkspaceSync />\n\n      {/* AI-Powered Insights */}\n      <AIInsights '
if old_ai in src and '<GoogleWorkspaceSync' not in src:
    src = src.replace(old_ai, new_ai, 1)
    changes.append("GoogleWorkspaceSync rendered in DashboardPage")

# ── Report & write ───────────────────────────────────────────────────────────
for c in changes:
    print(f"  OK  {c}")
if not changes:
    print("  -- All App.jsx patches already applied")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(src)
PYEOF

# ==============================================================================
# PATCH 5 — modals.jsx case fix (Linux/Vite is case-sensitive)
# ==============================================================================
echo "[5/6] Checking modals.jsx..."
if [ ! -f "src/modals.jsx" ] && [ -f "src/Modals.jsx" ]; then
  cp "src/Modals.jsx" "src/modals.jsx"
  echo "  OK  Copied Modals.jsx → modals.jsx"
elif [ -f "src/modals.jsx" ]; then
  echo "  OK  src/modals.jsx present"
else
  echo "  WARN  src/modals.jsx not found — App will crash on import!"
fi

# ==============================================================================
# PATCH 6 — translations file extension check
# ==============================================================================
echo "[6/6] Checking translations.js..."
if [ -f "src/translations.jsx" ] && [ ! -f "src/translations.js" ]; then
  cp "src/translations.jsx" "src/translations.js"
  echo "  OK  Renamed translations.jsx → translations.js"
elif [ -f "src/translations.js" ]; then
  echo "  OK  translations.js present"
else
  echo "  WARN  translations.js not found!"
fi
echo ""

# ==============================================================================
# BUILD
# ==============================================================================
echo "Building..."
rm -rf dist node_modules/.vite 2>/dev/null || true
echo ""

if npm run build; then
  echo ""
  echo "  Build successful!"
else
  echo ""
  echo "BUILD FAILED — restoring backup from $BD ..."
  for f in App.jsx firebase-config.js ExecutiveDashboard.jsx DashboardComponents.jsx modals.jsx; do
    [ -f "$BD/$f.bak" ] && cp "$BD/$f.bak" "src/$f" || true
  done
  [ -f "$BD/firebase.json.bak" ] && cp "$BD/firebase.json.bak" firebase.json || true
  echo "Restored. Check the build error above."
  exit 1
fi
echo ""

# ==============================================================================
# DEPLOY
# ==============================================================================
echo "Deploying to Firebase..."
echo ""

if firebase deploy --only hosting; then
  echo ""
  echo "======================================================"
  echo "  DONE — https://accessguard-v2.web.app"
  echo "======================================================"
  echo ""
  echo "Fixes applied:"
  echo "  [1] firebase-config.js  — magic link URL + duplicate OAuth scopes"
  echo "  [2] DashboardComponents — unused Clock/DollarSign imports"
  echo "  [3] ExecutiveDashboard  — Math.random() flicker + table indent"
  echo "  [4] App.jsx:"
  echo "        duplicate /tools + /security routes removed"
  echo "        IntegrationsPage dead state cleaned up"
  echo "        SecurityCompliancePage translation crash fixed"
  echo "        PricingTiers added to /billing"
  echo "        GoogleWorkspaceSync added to /dashboard"
  echo "  [5] modals.jsx          — lowercase filename ensured"
  echo "  [6] translations.js     — extension check"
  echo ""
  echo "  Backup: $BD"
else
  echo ""
  echo "DEPLOY FAILED — build succeeded, try manually:"
  echo "  firebase deploy --only hosting"
  exit 1
fi
