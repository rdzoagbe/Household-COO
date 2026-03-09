#!/bin/bash
# ============================================================================
# ENHANCE INTEGRATIONS PAGE - COMPREHENSIVE UPGRADE
# ============================================================================
# Adds stats, search, filters, better layout, and empty states

set -e

echo "🎨 Enhancing Integrations Page - Comprehensive Upgrade"
echo "======================================================"
echo ""

cd "$(dirname "$0")"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Creating enhanced IntegrationConnectors component..."

# Create the fully enhanced component
cat > integration_connectors_enhanced.txt << 'ENHANCED_EOF'

// ============================================================================
// ENHANCED INTEGRATION CONNECTORS COMPONENT
// ============================================================================
function IntegrationConnectors() {
  const [connectedIntegrations, setConnectedIntegrations] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  
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
    alert(`Connecting to ${integrationId}...`);
    setConnectedIntegrations([...connectedIntegrations, integrationId]);
  };

  const isConnected = (id) => connectedIntegrations.includes(id);

  // Filter integrations
  const filteredIntegrations = useMemo(() => {
    return integrations.filter(integration => {
      const matchesSearch = integration.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                           integration.description.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesCategory = selectedCategory === 'all' || integration.category === selectedCategory;
      const matchesStatus = selectedStatus === 'all' || 
                           (selectedStatus === 'connected' && isConnected(integration.id)) ||
                           (selectedStatus === 'available' && integration.status === 'available' && !isConnected(integration.id)) ||
                           (selectedStatus === 'coming-soon' && integration.status === 'coming-soon');
      return matchesSearch && matchesCategory && matchesStatus;
    });
  }, [searchQuery, selectedCategory, selectedStatus, connectedIntegrations]);

  const categories = ['all', ...new Set(integrations.map(i => i.category))];
  const connectedCount = connectedIntegrations.length;
  const comingSoonCount = integrations.filter(i => i.status === 'coming-soon').length;

  return (
    <div className="space-y-6">
      {/* Stats Header */}
      <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="p-4 bg-blue-500/20 rounded-2xl">
            <Plug className="h-8 w-8 text-blue-400" />
          </div>
          <div>
            <h2 className="text-2xl font-black text-white">Integration Marketplace</h2>
            <p className="text-slate-400">Connect your tools to automate SaaS management</p>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-blue-400">{integrations.length}</div>
            <div className="text-sm text-slate-400 mt-1">Total Integrations</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-emerald-400">{connectedCount}</div>
            <div className="text-sm text-slate-400 mt-1">Connected</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-orange-400">{integrations.length - comingSoonCount - connectedCount}</div>
            <div className="text-sm text-slate-400 mt-1">Available</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-purple-400">{comingSoonCount}</div>
            <div className="text-sm text-slate-400 mt-1">Coming Soon</div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search integrations..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>

          {/* Category Filter */}
          <select
            value={selectedCategory}
            onChange={(e) => setSelectedCategory(e.target.value)}
            className="px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
          >
            {categories.map(cat => (
              <option key={cat} value={cat}>
                {cat === 'all' ? 'All Categories' : cat}
              </option>
            ))}
          </select>

          {/* Status Filter */}
          <select
            value={selectedStatus}
            onChange={(e) => setSelectedStatus(e.target.value)}
            className="px-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-blue-500"
          >
            <option value="all">All Status</option>
            <option value="connected">Connected</option>
            <option value="available">Available</option>
            <option value="coming-soon">Coming Soon</option>
          </select>
        </div>
      </div>

      {/* Empty State */}
      {connectedCount === 0 && selectedStatus === 'all' && (
        <div className="bg-gradient-to-br from-emerald-500/10 to-teal-500/10 border border-emerald-500/20 rounded-2xl p-8 text-center">
          <div className="inline-flex p-4 bg-emerald-500/20 rounded-2xl mb-4">
            <Zap className="h-12 w-12 text-emerald-400" />
          </div>
          <h3 className="text-2xl font-bold text-white mb-2">Get Started with Integrations</h3>
          <p className="text-slate-400 mb-6 max-w-2xl mx-auto">
            Connect your tools to automatically import users, track licenses, and optimize SaaS spending. 
            Setup takes just minutes and requires no technical knowledge.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-left">
            <div className="bg-slate-900/50 rounded-xl p-4 border border-slate-800">
              <div className="text-emerald-400 font-bold mb-2">1. Choose Integration</div>
              <div className="text-sm text-slate-400">Select from our marketplace of tools</div>
            </div>
            <div className="bg-slate-900/50 rounded-xl p-4 border border-slate-800">
              <div className="text-emerald-400 font-bold mb-2">2. Authorize Access</div>
              <div className="text-sm text-slate-400">Securely connect via OAuth</div>
            </div>
            <div className="bg-slate-900/50 rounded-xl p-4 border border-slate-800">
              <div className="text-emerald-400 font-bold mb-2">3. Start Saving</div>
              <div className="text-sm text-slate-400">Automatic insights and optimization</div>
            </div>
          </div>
        </div>
      )}

      {/* Integration Cards */}
      {filteredIntegrations.length > 0 ? (
        <div className="space-y-8">
          {categories.filter(cat => cat !== 'all').map(category => {
            const categoryIntegrations = filteredIntegrations.filter(i => i.category === category);
            if (categoryIntegrations.length === 0) return null;

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
                        className={`relative bg-slate-900 border rounded-2xl p-6 transition-all h-full flex flex-col ${
                          connected 
                            ? 'border-emerald-500/50 bg-emerald-500/5' 
                            : comingSoon
                            ? 'border-slate-700 opacity-60'
                            : 'border-slate-800 hover:border-blue-500/50'
                        }`}
                      >
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

                        <div className="text-5xl mb-4">{integration.icon}</div>
                        <h4 className="text-xl font-bold text-white mb-2">{integration.name}</h4>
                        <p className="text-sm text-slate-400 mb-4 flex-grow">{integration.description}</p>
                        
                        <div className="space-y-2 mb-4">
                          {integration.features.map((feature, idx) => (
                            <div key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                              <Check className="h-4 w-4 text-blue-400 flex-shrink-0" />
                              {feature}
                            </div>
                          ))}
                        </div>

                        <div className="text-xs text-slate-500 mb-3">
                          ⏱️ Setup time: {integration.setupTime}
                        </div>

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
                          {connected ? 'Connected ✓' : comingSoon ? 'Coming Soon' : 'Connect'}
                        </button>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-12 text-center">
          <div className="text-slate-500 mb-2">🔍</div>
          <h3 className="text-xl font-bold text-white mb-2">No integrations found</h3>
          <p className="text-slate-400">Try adjusting your search or filters</p>
        </div>
      )}

      {/* Bottom Sections */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Request Integration */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">Need a Different Integration?</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Let us know which tools you'd like us to support. We're constantly adding new integrations.
          </p>
          <button className="w-full px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold transition-all">
            Request Integration
          </button>
        </div>

        {/* Need Help */}
        <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">Need Help?</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Our support team is here to help you get connected and optimize your SaaS stack.
          </p>
          <button className="w-full px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold transition-all">
            Contact Support
          </button>
        </div>
      </div>
    </div>
  );
}
ENHANCED_EOF

echo "  ✅ Enhanced component created"
echo ""

echo "🔧 Replacing IntegrationConnectors in App.jsx..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the old IntegrationConnectors component
start_marker = "// INTEGRATION CONNECTORS COMPONENT"
end_marker = "function IntegrationsPage()"

start_pos = content.find(start_marker)
end_pos = content.find(end_marker)

if start_pos == -1 or end_pos == -1:
    print("❌ Could not find component markers")
    exit(1)

# Read the new enhanced component
with open('integration_connectors_enhanced.txt', 'r') as f:
    new_component = f.read()

# Replace the old component with the new one
content = content[:start_pos] + new_component + content[end_pos:]

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Enhanced IntegrationConnectors added")
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
    echo "✅ COMPREHENSIVE INTEGRATIONS UPGRADE DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🎉 WHAT'S NEW:"
    echo "  📊 Stats Header (Total/Connected/Available/Coming Soon)"
    echo "  🔍 Search Bar"
    echo "  🎛️ Category & Status Filters"
    echo "  📏 Uniform Card Heights"
    echo "  🎨 Better Grid Alignment"
    echo "  ✨ Empty State with Getting Started Guide"
    echo "  💬 Request Integration Card"
    echo "  🆘 Need Help? Support Section"
    echo "  ⏱️ Setup Time Indicators"
    echo "  🎯 Improved Button States"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /integrations"
    echo "  2. Try the search bar"
    echo "  3. Filter by category/status"
    echo "  4. Connect an integration"
    echo "  5. See the stats update!"
    echo ""
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
