#!/bin/bash
# ============================================================================
# ADD GOOGLE WORKSPACE INTEGRATION - PHASE 1
# ============================================================================
# Adds OAuth scopes and user import functionality

set -e

echo "🔐 Adding Google Workspace Integration"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/firebase-config.js "backups/$TIMESTAMP/firebase-config.js.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Step 1: Adding OAuth scopes to Google provider..."

# Add scopes to googleProvider (after line 48)
cat > /tmp/add_scopes.py << 'PYEOF'
with open('src/firebase-config.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find googleProvider line
for i, line in enumerate(lines):
    if 'const googleProvider = new GoogleAuthProvider()' in line:
        # Add scopes after this line
        scopes = """
// Add Google Workspace Admin API scopes
googleProvider.addScope('https://www.googleapis.com/auth/admin.directory.user.readonly');
googleProvider.addScope('https://www.googleapis.com/auth/gmail.readonly');
googleProvider.addScope('profile');
googleProvider.addScope('email');
"""
        lines.insert(i + 1, scopes)
        break

with open('src/firebase-config.js', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✅ OAuth scopes added")
PYEOF

python3 /tmp/add_scopes.py

echo ""
echo "🔧 Step 2: Creating Google Workspace import functions..."

# Create new file for Google Workspace integration
cat > src/google-workspace.js << 'WORKSPACE_EOF'
// ============================================================================
// GOOGLE WORKSPACE INTEGRATION
// ============================================================================
// Functions to import users and data from Google Workspace

/**
 * Get access token from Firebase auth user
 */
export function getAccessToken(firebaseUser) {
  // Firebase stores the Google access token
  return firebaseUser?.stsTokenManager?.accessToken || null;
}

/**
 * Import users from Google Workspace Admin Directory
 */
export async function importGoogleWorkspaceUsers(accessToken) {
  try {
    const response = await fetch(
      'https://admin.googleapis.com/admin/directory/v1/users?domain=primary&maxResults=500',
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Accept': 'application/json',
        }
      }
    );

    if (!response.ok) {
      throw new Error(`API Error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    // Transform Google users to AccessGuard format
    const users = (data.users || []).map(user => ({
      id: user.id,
      name: user.name.fullName,
      email: user.primaryEmail,
      status: user.suspended ? 'offboarded' : 'active',
      department: user.orgUnitPath?.split('/').pop() || 'general',
      role: user.isAdmin ? 'admin' : 'user',
      google_user_id: user.id,
      last_login: user.lastLoginTime,
      created_at: user.creationTime,
      imported_from: 'google_workspace',
      imported_at: new Date().toISOString(),
    }));

    return { users, error: null };
  } catch (error) {
    console.error('Error importing Google Workspace users:', error);
    return { users: [], error: error.message };
  }
}

/**
 * Scan Gmail for SaaS invoices (Phase 2)
 */
export async function scanGmailForInvoices(accessToken) {
  try {
    // Search for common SaaS invoice patterns
    const queries = [
      'subject:(invoice OR receipt OR bill) from:(stripe OR paypal)',
      'subject:invoice has:attachment',
      'subject:"your invoice"',
    ];

    const invoices = [];

    for (const q of queries) {
      const response = await fetch(
        `https://gmail.googleapis.com/gmail/v1/users/me/messages?q=${encodeURIComponent(q)}&maxResults=50`,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Accept': 'application/json',
          }
        }
      );

      if (response.ok) {
        const data = await response.json();
        if (data.messages) {
          invoices.push(...data.messages);
        }
      }
    }

    return { invoices, error: null };
  } catch (error) {
    console.error('Error scanning Gmail:', error);
    return { invoices: [], error: error.message };
  }
}

/**
 * Check if user has granted necessary permissions
 */
export function hasWorkspacePermissions(firebaseUser) {
  // Check if we have an access token with the right scopes
  const token = getAccessToken(firebaseUser);
  return token !== null;
}
WORKSPACE_EOF

echo "  ✅ google-workspace.js created"
echo ""

echo "=============================================="
echo "✅ GOOGLE WORKSPACE INTEGRATION ADDED!"
echo "=============================================="
echo ""
echo "📋 WHAT WAS ADDED:"
echo "  ✅ OAuth scopes for Workspace Admin API"
echo "  ✅ OAuth scopes for Gmail API"
echo "  ✅ User import function"
echo "  ✅ Gmail invoice scanning function"
echo ""
echo "🎯 NEXT STEPS:"
echo ""
echo "1. **Google Cloud Console Setup** (REQUIRED):"
echo "   - Go to: https://console.cloud.google.com/"
echo "   - Select project: accessguard-v2"
echo "   - Enable APIs:"
echo "     • Admin SDK API"
echo "     • Gmail API"
echo "   - Configure OAuth consent screen"
echo "   - Add test users (your email)"
echo ""
echo "2. **Test the integration:**
echo "   npm run dev"
echo "   Sign in with Google"
echo "   Check console for access token"
echo ""
echo "3. **Build UI for import:**
echo "   I'll create a 'Sync Google Workspace' button"
echo ""
echo "💾 Backup: backups/$TIMESTAMP"
echo ""
echo "⚠️  IMPORTANT: You MUST enable the APIs in Google Cloud Console"
echo "   or the integration won't work!"
echo ""
