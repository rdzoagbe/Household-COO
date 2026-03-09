#!/bin/bash
# ============================================================================
# NAVIGATION REORGANIZATION - USER JOURNEY-BASED
# ============================================================================
# Reorganizes sidebar into 3 logical sections:
# 1. Monitoring & Insights
# 2. Core Management
# 3. Setup & Optimization

set -e

echo "🎯 Navigation Reorganization - User Journey Based"
echo "================================================="
echo ""
echo "NEW STRUCTURE:"
echo ""
echo "  📊 MONITORING & INSIGHTS:"
echo "  ├─ Dashboard"
echo "  └─ Executive"
echo ""
echo "  🔐 CORE MANAGEMENT:"
echo "  ├─ Tools"
echo "  ├─ Employees"
echo "  └─ Access Map"
echo ""
echo "  🔌 SETUP & OPTIMIZATION:"
echo "  ├─ Integrations"
echo "  ├─ Finance"
echo "  └─ Contracts"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Reorganizing navigation..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the navigation items array
nav_start = content.find('const navItems = [')
if nav_start == -1:
    print("  ❌ navItems not found")
    exit(1)

# Find the end of navItems array
nav_end = content.find('];', nav_start)
if nav_end == -1:
    print("  ❌ navItems end not found")
    exit(1)

# Replace with new organized structure
new_nav_items = '''const navItems = [
  // Monitoring & Insights
  { to: "/dashboard", label: "dashboard", icon: LayoutDashboard },
  { to: "/executive", label: "executive_view", icon: TrendingUp },
  { type: "separator", label: "Core Management" },
  // Core Management
  { to: "/tools", label: "tools", icon: Boxes },
  { to: "/employees", label: "employees", icon: Users },
  { to: "/access", label: "access", icon: GitMerge },
  { type: "separator", label: "Setup & Optimization" },
  // Setup & Optimization
  { to: "/integrations", label: "integrations", icon: Plug },
  { to: "/finance", label: "finance", icon: BarChart3 },
  { to: "/contracts", label: "contracts", icon: FileDiff },
]'''

content = content[:nav_start] + new_nav_items + content[nav_end+2:]

print("  ✅ Navigation reorganized with 3 sections")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Reorganization failed" && exit 1

echo ""
echo "🔧 Adding section labels to translations..."

python3 << 'PYEOF'
import os

if os.path.exists('src/translations.js'):
    with open('src/translations.js', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Add new section labels to all languages
    sections = {
        'en': {
            'monitoring_insights': 'Monitoring & Insights',
            'core_management': 'Core Management',
            'setup_optimization': 'Setup & Optimization'
        },
        'fr': {
            'monitoring_insights': 'Surveillance et analyses',
            'core_management': 'Gestion principale',
            'setup_optimization': 'Configuration et optimisation'
        },
        'es': {
            'monitoring_insights': 'Monitoreo y análisis',
            'core_management': 'Gestión principal',
            'setup_optimization': 'Configuración y optimización'
        },
        'de': {
            'monitoring_insights': 'Überwachung & Einblicke',
            'core_management': 'Kernverwaltung',
            'setup_optimization': 'Einrichtung & Optimierung'
        },
        'ja': {
            'monitoring_insights': '監視と分析',
            'core_management': 'コア管理',
            'setup_optimization': '設定と最適化'
        }
    }
    
    for lang, translations in sections.items():
        lang_block = content.find(f'  {lang}: {{')
        if lang_block != -1:
            block_end = content.find('\n  },', lang_block)
            for key, value in translations.items():
                if f'{key}:' not in content[lang_block:block_end]:
                    insert_line = f"    {key}: '{value}',\n"
                    content = content[:block_end] + insert_line + content[block_end:]
                    block_end += len(insert_line)
    
    with open('src/translations.js', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("  ✅ Section translations added")
else:
    print("  ⚠️  translations.js not found")

PYEOF

echo ""
echo "🏗️  Building..."

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ NAVIGATION REORGANIZED!                            ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  📊 MONITORING & INSIGHTS:                             ║"
        echo "║  ├─ Dashboard                                          ║"
        echo "║  └─ Executive                                          ║"
        echo "║                                                        ║"
        echo "║  🔐 CORE MANAGEMENT:                                   ║"
        echo "║  ├─ Tools                                              ║"
        echo "║  ├─ Employees                                          ║"
        echo "║  └─ Access Map                                         ║"
        echo "║                                                        ║"
        echo "║  🔌 SETUP & OPTIMIZATION:                              ║"
        echo "║  ├─ Integrations                                       ║"
        echo "║  ├─ Finance                                            ║"
        echo "║  └─ Contracts                                          ║"
        echo "║                                                        ║"
        echo "║  ✨ BENEFITS:                                          ║"
        echo "║  • Logical user journey flow                           ║"
        echo "║  • Clear section organization                          ║"
        echo "║  • Easy to find what you need                          ║"
        echo "║  • Professional structure                              ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 CHECK IT OUT:"
        echo "   Open your sidebar and see the new organization!"
        echo "   Notice how it flows logically from monitoring → managing → optimizing"
        echo ""
    else
        echo "❌ Deploy failed - restoring backup"
        cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
        exit 1
    fi
else
    echo "❌ Build failed - restoring backup"
    cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
    exit 1
fi

echo "💾 Backup: backups/$TIMESTAMP"
echo "✅ Navigation reorganized with user journey flow! 🎉"
