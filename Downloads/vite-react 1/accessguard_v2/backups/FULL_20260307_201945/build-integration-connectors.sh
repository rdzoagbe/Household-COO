#!/bin/bash
# ============================================================================
# BUILD INTEGRATION CONNECTORS UI
# ============================================================================
# Adds beautiful integration cards with connect buttons

set -e

echo "🔌 Building Integration Connectors"
echo "==================================="
echo ""

cd "$(dirname "$0")"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🎨 Creating integration connector components..."

# Create integration connectors component
cat > /tmp/integration_connectors.txt << 'CONNECTORS_EOF'

// ============================================================================
// INTEGRATION CONNECTORS COMPONENT
// ============================================================================
function IntegrationConnectors() {
  const [connectedIntegrations, setConnectedIntegrations] = useState([]);
  
  const integrations = [
    {
      id: 'google-workspace',
      name: 'Google Workspace',
      description: 'Import users, track licenses, scan Gmail for invoices',
      icon: '🔵',
      category: 'Identity & Directory',
      features: ['User Sync', 'License Detection', 'Invoice Scanning'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'slack',
      name: 'Slack',
      description: 'Send alerts, track usage, manage members',
      icon: '💬',
      category: 'Communication',
      features: ['User Sync', 'Usage Analytics', 'Alert Notifications'],
      status: 'available',
      setupTime: '3 min',
    },
    {
      id: 'microsoft-365',
      name: 'Microsoft 365',
      description: 'Azure AD sync, license tracking, usage monitoring',
      icon: '🟦',
      category: 'Identity & Directory',
      features: ['Azure AD Sync', 'License Management', 'Usage Reports'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'github',
      name: 'GitHub',
      description: 'Track seats, monitor activity, manage team access',
      icon: '🐙',
      category: 'Development',
      features: ['Seat Tracking', 'Activity Monitoring', 'Team Management'],
      status: 'available',
      setupTime: '2 min',
    },
    {
      id: 'okta',
      name: 'Okta',
      description: 'SSO integration, user provisioning, app discovery',
      icon: '🔐',
      category: 'Identity & Directory',
      features: ['SSO', 'User Provisioning', 'App Discovery'],
      status: 'available',
      setupTime: '10 min',
    },
    {
      id: 'salesforce',
      name: 'Salesforce',
      description: 'Track licenses, monitor usage, optimize seats',
      icon: '☁️',
      category: 'CRM',
      features: ['License Tracking', 'Usage Monitoring', 'Cost Optimization'],
      status: 'available',
      setupTime: '5 min',
    },
    {
      id: 'zoom',
      name: 'Zoom',
      description: 'Track meeting licenses, monitor usage',
      icon: '📹',
      category: 'Communication',
      features: ['License Management', 'Usage Analytics'],
      status: 'coming-soon',
      setupTime: '3 min',
    },
    {
      id: 'asana',
      name: 'Asana',
      description: 'Project management tool tracking',
      icon: '📊',
      category: 'Productivity',
      features: ['Seat Tracking', 'Usage Reports'],
      status: 'coming-soon',
      setupTime: '3 min',
    },
  ];

  const handleConnect = (integrationId) => {
    // Placeholder for OAuth flow
    alert(`Connecting to ${integrationId}... (OAuth flow will be implemented)`);
    setConnectedIntegrations([...connectedIntegrations, integrationId]);
  };

  const isConnected = (id) => connectedIntegrations.includes(id);

  const categories = [...new Set(integrations.map(i => i.category))];

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
        <div className="flex items-center gap-4">
          <div className="p-4 bg-blue-500/20 rounded-2xl">
            <Plug className="h-8 w-8 text-blue-400" />
          </div>
          <div>
            <h2 className="text-2xl font-black text-white">Integration Marketplace</h2>
            <p className="text-slate-400">Connect your tools to automate SaaS management</p>
          </div>
        </div>
        <div className="grid grid-cols-3 gap-4 mt-6">
          <div className="text-center">
            <div className="text-3xl font-black text-blue-400">{integrations.length}</div>
            <div className="text-sm text-slate-400">Integrations</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-black text-emerald-400">{connectedIntegrations.length}</div>
            <div className="text-sm text-slate-400">Connected</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-black text-purple-400">
              {integrations.filter(i => i.status === 'coming-soon').length}
            </div>
            <div className="text-sm text-slate-400">Coming Soon</div>
          </div>
        </div>
      </div>

      {/* Integration Cards by Category */}
      {categories.map(category => {
        const categoryIntegrations = integrations.filter(i => i.category === category);
        
        return (
          <div key={category}>
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Zap className="h-5 w-5 text-blue-400" />
              {category}
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {categoryIntegrations.map(integration => {
                const connected = isConnected(integration.id);
                const comingSoon = integration.status === 'coming-soon';
                
                return (
                  <div
                    key={integration.id}
                    className={`relative bg-slate-900 border rounded-2xl p-6 transition-all ${
                      connected 
                        ? 'border-emerald-500/50 bg-emerald-500/5' 
                        : comingSoon
                        ? 'border-slate-700 opacity-60'
                        : 'border-slate-800 hover:border-blue-500/50'
                    }`}
                  >
                    {/* Status Badge */}
                    {connected && (
                      <div className="absolute top-4 right-4">
                        <span className="px-3 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full flex items-center gap-1">
                          <CheckCircle className="h-3 w-3" />
                          Connected
                        </span>
                      </div>
                    )}
                    
                    {comingSoon && (
                      <div className="absolute top-4 right-4">
                        <span className="px-3 py-1 bg-slate-700 text-slate-400 text-xs font-bold rounded-full">
                          Coming Soon
                        </span>
                      </div>
                    )}

                    {/* Icon & Title */}
                    <div className="flex items-center gap-4 mb-4">
                      <div className="text-5xl">{integration.icon}</div>
                      <div>
                        <h4 className="text-xl font-bold text-white">{integration.name}</h4>
                        <div className="text-xs text-slate-500">{integration.setupTime} setup</div>
                      </div>
                    </div>

                    {/* Description */}
                    <p className="text-sm text-slate-400 mb-4">{integration.description}</p>

                    {/* Features */}
                    <div className="space-y-2 mb-4">
                      {integration.features.map((feature, idx) => (
                        <div key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                          <Check className="h-4 w-4 text-blue-400" />
                          {feature}
                        </div>
                      ))}
                    </div>

                    {/* Connect Button */}
                    <button
                      onClick={() => !comingSoon && handleConnect(integration.id)}
                      disabled={connected || comingSoon}
                      className={`w-full py-3 rounded-xl font-bold transition-all ${
                        connected
                          ? 'bg-emerald-600 text-white cursor-default'
                          : comingSoon
                          ? 'bg-slate-700 text-slate-500 cursor-not-allowed'
                          : 'bg-blue-600 hover:bg-blue-500 text-white'
                      }`}
                    >
                      {connected ? 'Connected' : comingSoon ? 'Coming Soon' : 'Connect'}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}

      {/* Request Integration */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 text-center">
        <h3 className="text-xl font-bold text-white mb-2">Need a different integration?</h3>
        <p className="text-slate-400 mb-4">Let us know which tools you'd like us to support</p>
        <button className="px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold">
          Request Integration
        </button>
      </div>
    </div>
  );
}
CONNECTORS_EOF

echo "  ✅ Integration connectors component created"
echo ""

echo "🔧 Adding to Integrations page..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find IntegrationsPage function
integrations_pos = content.find('function IntegrationsPage() {')
if integrations_pos == -1:
    print("❌ Could not find IntegrationsPage")
    exit(1)

# Add component before IntegrationsPage
component = open('/tmp/integration_connectors.txt', 'r').read()
content = content[:integrations_pos] + component + '\n' + content[integrations_pos:]

# Now replace the content of IntegrationsPage with our new component
# Find the return statement in IntegrationsPage
pageheader_pos = content.find('<PageHeader', integrations_pos)
if pageheader_pos != -1:
    # Find the closing of PageHeader
    pageheader_close = content.find('>', pageheader_pos)
    # Find what comes after PageHeader (likely empty or placeholder content)
    # Replace with IntegrationConnectors
    appshell_close = content.find('</AppShell>', pageheader_close)
    
    # Insert IntegrationConnectors after PageHeader
    new_content = "\n      <IntegrationConnectors />\n"
    content = content[:pageheader_close + 1] + new_content + content[appshell_close:]

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Integration connectors added to Integrations page")
PYEOF

echo ""
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  
  echo "🚀 Deploying..."
  if firebase deploy --only hosting; then
    echo ""
    echo "=============================================="
    echo "✅ INTEGRATION CONNECTORS DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🔌 WHAT'S NEW:"
    echo "  ✅ 8 Integration cards"
    echo "  ✅ Google Workspace, Slack, Microsoft 365"
    echo "  ✅ GitHub, Okta, Salesforce, Zoom, Asana"
    echo "  ✅ Connect buttons (OAuth placeholder)"
    echo "  ✅ Status indicators (Connected/Coming Soon)"
    echo "  ✅ Feature lists for each integration"
    echo "  ✅ Setup time estimates"
    echo "  ✅ Request Integration button"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /integrations"
    echo "  2. See beautiful integration marketplace"
    echo "  3. Click Connect buttons"
    echo "  4. Integrations show as 'Connected'"
    echo ""
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
