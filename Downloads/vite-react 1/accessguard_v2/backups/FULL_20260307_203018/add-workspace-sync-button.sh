#!/bin/bash
# ============================================================================
# ADD GOOGLE WORKSPACE SYNC BUTTON TO DASHBOARD
# ============================================================================
# Creates a button to import users from Google Workspace

set -e

echo "🔄 Adding Google Workspace Sync Button"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Step 1: Adding import for google-workspace functions..."

# Add import at the top
sed -i '22a\import { importGoogleWorkspaceUsers, scanGmailForInvoices, getAccessToken, hasWorkspacePermissions } from "./google-workspace";' src/App.jsx

echo "  ✅ Import added"
echo ""

echo "🔧 Step 2: Creating Google Workspace sync component..."

# Create the sync button component
cat > /tmp/workspace_sync_component.txt << 'COMPONENT_EOF'

// ============================================================================
// GOOGLE WORKSPACE SYNC BUTTON
// ============================================================================
function GoogleWorkspaceSync() {
  const { firebaseUser } = useAuth();
  const muts = useDbMutations();
  const [syncing, setSyncing] = useState(false);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncedCount, setSyncedCount] = useState(0);

  const handleSync = async () => {
    if (!firebaseUser) {
      setSyncStatus({ type: 'error', message: 'Please sign in with Google first' });
      return;
    }

    const accessToken = getAccessToken(firebaseUser);
    if (!accessToken) {
      setSyncStatus({ type: 'error', message: 'No access token found. Please sign in with Google.' });
      return;
    }

    setSyncing(true);
    setSyncStatus({ type: 'loading', message: 'Importing users from Google Workspace...' });

    try {
      // Import users
      const { users, error } = await importGoogleWorkspaceUsers(accessToken);

      if (error) {
        setSyncStatus({ type: 'error', message: `Error: ${error}` });
        setSyncing(false);
        return;
      }

      // Add users to Firestore
      let imported = 0;
      for (const user of users) {
        try {
          await muts.addEmployee.mutateAsync({
            name: user.name,
            email: user.email,
            status: user.status,
            department: user.department,
            role: user.role,
            google_user_id: user.google_user_id,
            imported_from: 'google_workspace',
            imported_at: new Date().toISOString(),
          });
          imported++;
        } catch (err) {
          console.error('Error adding user:', err);
        }
      }

      setSyncedCount(imported);
      setSyncStatus({ 
        type: 'success', 
        message: `Successfully imported ${imported} users from Google Workspace!` 
      });
      setSyncing(false);

      // Refresh the page after 2 seconds
      setTimeout(() => window.location.reload(), 2000);
    } catch (error) {
      setSyncStatus({ type: 'error', message: `Sync failed: ${error.message}` });
      setSyncing(false);
    }
  };

  if (!firebaseUser) return null;

  const hasPermissions = hasWorkspacePermissions(firebaseUser);

  return (
    <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
      <div className="flex items-center gap-4 mb-4">
        <div className="p-3 bg-blue-500/20 rounded-xl">
          <RefreshCw className={`h-6 w-6 text-blue-400 ${syncing ? 'animate-spin' : ''}`} />
        </div>
        <div className="flex-1">
          <h3 className="text-xl font-bold text-white">Google Workspace Integration</h3>
          <p className="text-sm text-slate-300">Import users automatically from your Google Workspace</p>
        </div>
        {hasPermissions && (
          <button
            onClick={handleSync}
            disabled={syncing}
            className={`px-6 py-3 rounded-xl font-semibold transition-all ${
              syncing
                ? 'bg-slate-600 text-slate-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-500 text-white'
            }`}
          >
            {syncing ? 'Syncing...' : 'Sync Now'}
          </button>
        )}
      </div>

      {!hasPermissions && (
        <div className="bg-yellow-500/10 border border-yellow-500/20 rounded-xl p-4">
          <p className="text-sm text-yellow-400">
            ⚠️ To use this feature, please sign in with Google and grant Workspace Admin permissions.
          </p>
        </div>
      )}

      {syncStatus && (
        <div className={`mt-4 p-4 rounded-xl border ${
          syncStatus.type === 'success' ? 'bg-emerald-500/10 border-emerald-500/20' :
          syncStatus.type === 'error' ? 'bg-red-500/10 border-red-500/20' :
          'bg-blue-500/10 border-blue-500/20'
        }`}>
          <p className={`text-sm ${
            syncStatus.type === 'success' ? 'text-emerald-400' :
            syncStatus.type === 'error' ? 'text-red-400' :
            'text-blue-400'
          }`}>
            {syncStatus.message}
          </p>
          {syncStatus.type === 'success' && syncedCount > 0 && (
            <p className="text-xs text-slate-400 mt-2">
              Imported {syncedCount} users. Page will refresh in 2 seconds...
            </p>
          )}
        </div>
      )}
    </div>
  );
}
COMPONENT_EOF

echo "  ✅ Sync component created"
echo ""

echo "🔧 Step 3: Adding sync button to Integrations page..."

# Find the Integrations page and add the component
# This will be added to the IntegrationsPage function

# For now, let's add it to the Dashboard page as a test
# Find Dashboard page and add it before AI Insights

echo "  ⚠️  Manual step: Adding to Dashboard for testing"
echo ""

cat >> /tmp/add_to_dashboard.py << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find where to insert the component definition (before DashboardPage)
dashboard_pos = content.find('function DashboardPage() {')

# Insert the component before DashboardPage
component = open('/tmp/workspace_sync_component.txt', 'r').read()
content = content[:dashboard_pos] + component + '\n' + content[dashboard_pos:]

# Now add the sync button to the Dashboard render
# Find AIInsights usage and add GoogleWorkspaceSync before it
ai_insights_pos = content.find('<AIInsights')
if ai_insights_pos != -1:
    # Add GoogleWorkspaceSync before AIInsights
    insert_text = '\n      <GoogleWorkspaceSync />\n\n'
    content = content[:ai_insights_pos] + insert_text + content[ai_insights_pos:]

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added to Dashboard")
PYEOF

python3 /tmp/add_to_dashboard.py

echo ""
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  
  echo "🚀 Deploying..."
  if firebase deploy --only hosting; then
    echo ""
    echo "=============================================="
    echo "✅ GOOGLE WORKSPACE SYNC BUTTON DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🎉 WHAT'S NEW:"
    echo "  🔄 Google Workspace Sync button on Dashboard"
    echo "  📥 Click to import users from Google Workspace"
    echo "  ✅ Auto-detects permissions"
    echo "  📊 Shows sync status"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /dashboard"
    echo "  2. Look for 'Google Workspace Integration' card"
    echo "  3. Click 'Sync Now'"
    echo "  4. Users will be imported!"
    echo ""
    echo "⚠️  NOTE: Make sure you've:"
    echo "  • Enabled Admin SDK API in Google Cloud"
    echo "  • Enabled Gmail API in Google Cloud"
    echo "  • Signed in with a Google Workspace admin account"
    echo ""
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
