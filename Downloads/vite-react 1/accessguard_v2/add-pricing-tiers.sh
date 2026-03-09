#!/bin/bash
# ============================================================================
# ADD PRICING TIERS TO BILLING PAGE
# ============================================================================
# Creates professional pricing comparison cards

set -e

echo "💰 Adding Pricing Tiers to Billing Page"
echo "========================================"
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Creating PricingTiers component..."

# Create the pricing component
cat > /tmp/pricing_component.txt << 'COMPONENT_EOF'

// ============================================================================
// PRICING TIERS COMPONENT
// ============================================================================
function PricingTiers({ currentPlan = 'free' }) {
  const [billingCycle, setBillingCycle] = useState('monthly');
  
  const plans = [
    {
      id: 'free',
      name: 'Free',
      tagline: 'For small teams getting started',
      price: { monthly: 0, annual: 0 },
      features: [
        'Up to 10 SaaS tools tracked',
        'Basic dashboard',
        '1 team member',
        'Email support',
        'Monthly reports',
      ],
      cta: 'Current Plan',
      popular: false,
    },
    {
      id: 'pro',
      name: 'Professional',
      tagline: 'For growing teams',
      price: { monthly: 49, annual: 470 },
      features: [
        'Unlimited SaaS tools',
        'AI-powered insights',
        'Executive dashboard',
        'Up to 10 team members',
        'Priority support',
        'Advanced analytics',
        'Custom reports',
        'API access',
      ],
      cta: 'Upgrade to Pro',
      popular: true,
    },
    {
      id: 'enterprise',
      name: 'Enterprise',
      tagline: 'For large organizations',
      price: { monthly: 'Custom', annual: 'Custom' },
      features: [
        'Everything in Pro',
        'Unlimited team members',
        'SSO & SAML',
        'Dedicated account manager',
        '24/7 phone support',
        'Custom integrations',
        'SLA guarantee',
        'On-premise option',
        'Training & onboarding',
      ],
      cta: 'Contact Sales',
      popular: false,
    },
  ];

  const getPriceDisplay = (plan) => {
    if (typeof plan.price[billingCycle] === 'number') {
      return billingCycle === 'monthly' 
        ? `$${plan.price[billingCycle]}/mo`
        : `$${plan.price[billingCycle]}/yr`;
    }
    return plan.price[billingCycle];
  };

  const getSavings = (plan) => {
    if (billingCycle === 'annual' && typeof plan.price.annual === 'number' && plan.price.annual > 0) {
      const monthlyCost = plan.price.monthly * 12;
      const savings = monthlyCost - plan.price.annual;
      return savings > 0 ? `Save $${savings}/year` : null;
    }
    return null;
  };

  return (
    <div className="space-y-8">
      {/* Billing Cycle Toggle */}
      <div className="flex items-center justify-center gap-4">
        <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-white' : 'text-slate-400'}`}>
          Monthly
        </span>
        <button
          onClick={() => setBillingCycle(billingCycle === 'monthly' ? 'annual' : 'monthly')}
          className="relative w-14 h-7 bg-slate-700 rounded-full transition-colors hover:bg-slate-600"
        >
          <div className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full transition-transform ${
            billingCycle === 'annual' ? 'translate-x-7' : ''
          }`} />
        </button>
        <span className={`text-sm font-medium ${billingCycle === 'annual' ? 'text-white' : 'text-slate-400'}`}>
          Annual
        </span>
        {billingCycle === 'annual' && (
          <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-semibold rounded-full">
            Save 20%
          </span>
        )}
      </div>

      {/* Pricing Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((plan) => {
          const isCurrentPlan = plan.id === currentPlan;
          const savings = getSavings(plan);
          
          return (
            <div
              key={plan.id}
              className={`relative rounded-2xl p-8 ${
                plan.popular
                  ? 'bg-gradient-to-br from-blue-500/20 to-purple-500/20 border-2 border-blue-500'
                  : 'bg-slate-900 border border-slate-800'
              }`}
            >
              {plan.popular && (
                <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                  <span className="px-4 py-1 bg-blue-600 text-white text-sm font-bold rounded-full">
                    MOST POPULAR
                  </span>
                </div>
              )}

              <div className="text-center mb-6">
                <h3 className="text-2xl font-black text-white mb-2">{plan.name}</h3>
                <p className="text-sm text-slate-400">{plan.tagline}</p>
              </div>

              <div className="text-center mb-6">
                <div className="text-4xl font-black text-white mb-2">
                  {getPriceDisplay(plan)}
                </div>
                {savings && (
                  <div className="text-sm text-emerald-400 font-semibold">{savings}</div>
                )}
              </div>

              <ul className="space-y-3 mb-8">
                {plan.features.map((feature, idx) => (
                  <li key={idx} className="flex items-start gap-2">
                    <CheckCircle className="h-5 w-5 text-emerald-400 flex-shrink-0 mt-0.5" />
                    <span className="text-sm text-slate-300">{feature}</span>
                  </li>
                ))}
              </ul>

              <button
                disabled={isCurrentPlan}
                className={`w-full py-3 rounded-xl font-bold transition-all ${
                  isCurrentPlan
                    ? 'bg-slate-700 text-slate-400 cursor-not-allowed'
                    : plan.popular
                    ? 'bg-blue-600 hover:bg-blue-500 text-white'
                    : 'bg-slate-800 hover:bg-slate-700 text-white'
                }`}
              >
                {isCurrentPlan ? 'Current Plan' : plan.cta}
              </button>
            </div>
          );
        })}
      </div>

      {/* Trust Badges */}
      <div className="mt-12 text-center">
        <p className="text-sm text-slate-400 mb-4">Trusted by 800+ companies worldwide</p>
        <div className="flex items-center justify-center gap-8 text-slate-600">
          <div className="flex items-center gap-2">
            <Shield className="h-5 w-5" />
            <span className="text-sm">SOC 2 Certified</span>
          </div>
          <div className="flex items-center gap-2">
            <Lock className="h-5 w-5" />
            <span className="text-sm">GDPR Compliant</span>
          </div>
          <div className="flex items-center gap-2">
            <Award className="h-5 w-5" />
            <span className="text-sm">99.9% Uptime</span>
          </div>
        </div>
      </div>
    </div>
  );
}
COMPONENT_EOF

echo "  ✅ PricingTiers component created"
echo ""

echo "🔧 Adding to Billing page..."

# Find the BillingPage function and add pricing component
cat > /tmp/add_pricing.py << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Add the component before BillingPage function
billing_page_pos = content.find('function BillingPage()')
if billing_page_pos == -1:
    print("❌ Could not find BillingPage function")
    exit(1)

# Insert component
component = open('/tmp/pricing_component.txt', 'r').read()
content = content[:billing_page_pos] + component + '\n' + content[billing_page_pos:]

# Now add PricingTiers usage inside BillingPage
# Find the return statement and add it after PageHeader
pageheader_end = content.find('</PageHeader>', billing_page_pos)
if pageheader_end != -1:
    # Find the next line after PageHeader closes
    insert_pos = content.find('\n', pageheader_end) + 1
    pricing_usage = """
      {/* Pricing Tiers */}
      <div className="mb-8">
        <PricingTiers currentPlan="free" />
      </div>

"""
    content = content[:insert_pos] + pricing_usage + content[insert_pos:]

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added to BillingPage")
PYEOF

python3 /tmp/add_pricing.py

echo ""
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  
  echo "🚀 Deploying..."
  if firebase deploy --only hosting; then
    echo ""
    echo "=============================================="
    echo "✅ PRICING TIERS ADDED TO BILLING PAGE!"
    echo "=============================================="
    echo ""
    echo "🎉 WHAT'S NEW:"
    echo "  💰 3 pricing tiers (Free, Pro, Enterprise)"
    echo "  🔄 Monthly/Annual toggle with 20% savings"
    echo "  ✅ Feature comparison lists"
    echo "  🏆 Trust badges (SOC 2, GDPR, Uptime)"
    echo "  🎨 'Most Popular' badge on Pro tier"
    echo ""
    echo "🧪 TEST IT:"
    echo "  1. Go to /billing"
    echo "  2. See beautiful pricing cards"
    echo "  3. Toggle monthly/annual"
    echo "  4. See savings calculation!"
    echo ""
  fi
else
  echo "❌ Build failed"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
