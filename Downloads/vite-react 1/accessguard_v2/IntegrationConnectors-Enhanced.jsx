// ============================================================================
// COMPREHENSIVE INTEGRATION CONNECTORS - OPTION A
// ============================================================================
// Replace lines 4519-4650 in App.jsx with this component

function IntegrationConnectors() {
  const [connectedIntegrations, setConnectedIntegrations] = useState(['google-workspace', 'slack']);
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
      usageStats: {
        activeUsers: 187,
        totalLicenses: 250,
        monthlyCost: 12400,
        lastSync: '2 min ago',
        inactiveUsers: 42,
        potentialSavings: 2780
      },
      badges: ['most-used', 'highest-spend']
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
      usageStats: {
        activeUsers: 412,
        totalLicenses: 450,
        monthlyCost: 2850,
        lastSync: '1 min ago',
        inactiveUsers: 67,
        potentialSavings: 450
      },
      badges: ['optimal-usage']
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
      usageStats: null
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
      usageStats: null
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
      usageStats: null
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
      usageStats: null
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
      usageStats: null
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
      usageStats: null
    },
  ];

  const handleConnect = (integrationId) => {
    if (connectedIntegrations.includes(integrationId)) {
      setConnectedIntegrations(connectedIntegrations.filter(id => id !== integrationId));
    } else {
      setConnectedIntegrations([...connectedIntegrations, integrationId]);
    }
  };

  const isConnected = (id) => connectedIntegrations.includes(id);

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
  
  const totalMonthlyCost = integrations
    .filter(i => isConnected(i.id) && i.usageStats)
    .reduce((sum, i) => sum + i.usageStats.monthlyCost, 0);
    
  const totalPotentialSavings = integrations
    .filter(i => isConnected(i.id) && i.usageStats)
    .reduce((sum, i) => sum + (i.usageStats.potentialSavings || 0), 0);

  const getBadgeInfo = (badge) => {
    switch(badge) {
      case 'most-used': return { label: '🏆 Most Used', color: 'bg-yellow-500/20 text-yellow-400' };
      case 'highest-spend': return { label: '💰 Highest Spend', color: 'bg-purple-500/20 text-purple-400' };
      case 'optimal-usage': return { label: '✅ Optimal', color: 'bg-emerald-500/20 text-emerald-400' };
      case 'underutilized': return { label: '⚠️ Underutilized', color: 'bg-orange-500/20 text-orange-400' };
      default: return null;
    }
  };

  const getUtilizationColor = (percentage) => {
    if (percentage >= 80) return 'from-emerald-500 to-green-500';
    if (percentage >= 50) return 'from-yellow-500 to-orange-500';
    return 'from-red-500 to-orange-500';
  };

  return (
    <div className="space-y-6">
      {/* Stats Header */}
      <div className="bg-gradient-to-r from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="p-4 bg-blue-500/20 rounded-2xl">
            <Plug className="h-8 w-8 text-blue-400" />
          </div>
          <div className="flex-1">
            <h2 className="text-2xl font-black text-white">Integration Marketplace</h2>
            <p className="text-slate-400">Connect your tools to automate SaaS management</p>
          </div>
        </div>
        
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-blue-400">{integrations.length}</div>
            <div className="text-sm text-slate-400 mt-1">Available</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-emerald-400">{connectedCount}</div>
            <div className="text-sm text-slate-400 mt-1">Connected</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-purple-400">${(totalMonthlyCost / 1000).toFixed(1)}k</div>
            <div className="text-sm text-slate-400 mt-1">Monthly Cost</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-emerald-400">${(totalPotentialSavings / 1000).toFixed(1)}k</div>
            <div className="text-sm text-slate-400 mt-1">Savings Found</div>
          </div>
          <div className="bg-slate-900/50 rounded-xl p-4 text-center border border-slate-800">
            <div className="text-3xl font-black text-orange-400">{comingSoonCount}</div>
            <div className="text-sm text-slate-400 mt-1">Coming Soon</div>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
                    const stats = integration.usageStats;
                    const utilization = stats ? (stats.activeUsers / stats.totalLicenses) * 100 : 0;

                    return (
                      <div
                        key={integration.id}
                        className={`relative bg-slate-900 border rounded-2xl p-6 transition-all flex flex-col ${
                          connected 
                            ? 'border-emerald-500/50 bg-emerald-500/5' 
                            : comingSoon
                            ? 'border-slate-700 opacity-70'
                            : 'border-slate-800 hover:border-blue-500/50'
                        }`}
                      >
                        {/* Badges */}
                        <div className="absolute top-4 right-4 flex flex-col gap-2 items-end">
                          {connected && (
                            <span className="px-3 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full flex items-center gap-1">
                              <CheckCircle className="h-3 w-3" />
                              Connected
                            </span>
                          )}
                          {comingSoon && (
                            <span className="px-3 py-1 bg-slate-700 text-slate-400 text-xs font-bold rounded-full">
                              Coming Soon
                            </span>
                          )}
                          {integration.badges && integration.badges.map((badge, idx) => {
                            const badgeInfo = getBadgeInfo(badge);
                            return badgeInfo ? (
                              <span key={idx} className={`px-2 py-1 text-xs font-bold rounded-full ${badgeInfo.color}`}>
                                {badgeInfo.label}
                              </span>
                            ) : null;
                          })}
                        </div>

                        {/* Icon & Title */}
                        <div className="flex items-center gap-4 mb-4">
                          <div className="text-5xl">{integration.icon}</div>
                          <div className="flex-1">
                            <h4 className="text-xl font-bold text-white">{integration.name}</h4>
                            <div className="text-xs text-slate-500 mt-1">⏱️ {integration.setupTime} setup</div>
                          </div>
                        </div>

                        <p className="text-sm text-slate-400 mb-4">{integration.description}</p>

                        {/* Usage Stats (if connected) */}
                        {connected && stats && (
                          <div className="space-y-3 mb-4 p-4 bg-slate-950/50 rounded-xl border border-slate-800">
                            <div>
                              <div className="flex items-center justify-between mb-2">
                                <span className="text-sm text-slate-400">License Usage</span>
                                <span className="text-sm font-bold text-white">{stats.activeUsers}/{stats.totalLicenses}</span>
                              </div>
                              <div className="w-full bg-slate-800 rounded-full h-2">
                                <div 
                                  className={`bg-gradient-to-r ${getUtilizationColor(utilization)} h-2 rounded-full`}
                                  style={{ width: `${utilization}%` }}
                                />
                              </div>
                              <div className="text-xs text-slate-500 mt-1">{utilization.toFixed(0)}% utilized</div>
                            </div>

                            <div className="grid grid-cols-2 gap-3">
                              <div className="text-center">
                                <div className="text-lg font-bold text-blue-400">${(stats.monthlyCost/1000).toFixed(1)}k</div>
                                <div className="text-xs text-slate-500">Monthly</div>
                              </div>
                              <div className="text-center">
                                <div className="text-lg font-bold text-purple-400">${(stats.monthlyCost/stats.activeUsers).toFixed(0)}</div>
                                <div className="text-xs text-slate-500">Per User</div>
                              </div>
                            </div>

                            {stats.potentialSavings > 0 && (
                              <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-lg p-3">
                                <div className="text-sm font-semibold text-emerald-400 mb-1">💡 Optimization</div>
                                <div className="text-xs text-slate-400">Remove {stats.inactiveUsers} inactive licenses</div>
                                <div className="text-sm font-bold text-emerald-400 mt-1">Save ${stats.potentialSavings}/mo</div>
                              </div>
                            )}

                            <div className="text-xs text-slate-500">
                              🔄 Last synced: {stats.lastSync}
                            </div>
                          </div>
                        )}

                        {/* Features */}
                        <div className="space-y-2 mb-4 flex-grow">
                          {integration.features.map((feature, idx) => (
                            <div key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                              <Check className="h-4 w-4 text-blue-400 flex-shrink-0" />
                              {feature}
                            </div>
                          ))}
                        </div>

                        {/* Connect Button */}
                        <button
                          onClick={() => !comingSoon && handleConnect(integration.id)}
                          disabled={comingSoon}
                          className={`w-full py-3 rounded-xl font-bold transition-all ${
                            connected
                              ? 'bg-slate-700 hover:bg-slate-600 text-white'
                              : comingSoon
                              ? 'bg-slate-700 text-slate-500 cursor-not-allowed'
                              : 'bg-blue-600 hover:bg-blue-500 text-white'
                          }`}
                        >
                          {connected ? 'Disconnect' : comingSoon ? 'Coming Soon' : 'Connect'}
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
          <div className="text-5xl mb-4">🔍</div>
          <h3 className="text-xl font-bold text-white mb-2">No integrations found</h3>
          <p className="text-slate-400">Try adjusting your search or filters</p>
        </div>
      )}

      {/* Bottom Sections */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">Need a Different Integration?</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Let us know which tools you'd like us to support.
          </p>
          <button className="w-full px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-semibold">
            Request Integration
          </button>
        </div>

        <div className="bg-gradient-to-br from-blue-500/10 to-purple-500/10 border border-blue-500/20 rounded-2xl p-6">
          <h3 className="text-xl font-bold text-white mb-2">Need Help?</h3>
          <p className="text-slate-400 mb-4 text-sm">
            Our team is here to help you optimize your integrations.
          </p>
          <button className="w-full px-6 py-3 bg-blue-600 hover:bg-blue-500 text-white rounded-xl font-semibold">
            Contact Support
          </button>
        </div>
      </div>
    </div>
  );
}
