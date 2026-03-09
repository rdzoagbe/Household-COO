#!/bin/bash
# ============================================================================
# IMPORT PAGE REDESIGN
# ============================================================================
# 1. Move Format Guidelines into Bulk Import card (collapsible)
# 2. Redesign Current Workspace with beautiful cards

set -e

echo "🎨 Import Page Redesign"
echo "======================="
echo ""
echo "Changes:"
echo "  ✅ Move Format Guidelines into Bulk Import card"
echo "  ✅ Make it collapsible (show/hide)"
echo "  ✅ Redesign Current Workspace with better visuals"
echo ""
read -p "Press Enter to continue..."
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "🔧 Redesigning Import page sections..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ImportPage
import_page = content.find('function ImportPage(')
if import_page == -1:
    print("  ❌ ImportPage not found")
    exit(1)

# Find the useState declarations and add showGuidelines state
const_kind = content.find('const [kind, setKind] = useState("tools");', import_page)
if const_kind != -1:
    # Add after the useState declarations
    insert_pos = content.find('\n', const_kind) + 1
    new_state = '  const [showGuidelines, setShowGuidelines] = useState(false);\n'
    
    # Check if already added
    if 'showGuidelines' not in content[import_page:import_page+2000]:
        content = content[:insert_pos] + new_state + content[insert_pos:]
        print("  ✅ Added showGuidelines state")
    else:
        print("  ℹ️  showGuidelines state already exists")

# Now find Format Guidelines card and replace it with a collapsible section
# Look for the Card with "Format guidelines"
format_card_start = content.find('<Card>', import_page)
while format_card_start != -1 and format_card_start < import_page + 10000:
    # Check if this Card has "Format guidelines"
    next_card = content.find('<Card>', format_card_start + 10)
    section = content[format_card_start:min(next_card if next_card != -1 else len(content), format_card_start + 2000)]
    
    if 'Format guidelines' in section:
        # Found it! Replace with collapsible version inside Bulk Import
        # For now, just add a button to toggle it
        # We'll move it properly in the next step
        print("  ✅ Found Format Guidelines card at position", format_card_start - import_page)
        
        # Find the Bulk Import card (before Format Guidelines)
        bulk_import_card = content.rfind('<CardBody>', import_page, format_card_start)
        if bulk_import_card != -1:
            # Find where to insert the collapsible guidelines (at end of CardBody, before </CardBody>)
            card_body_end = content.find('</CardBody>', bulk_import_card)
            
            # Add collapsible section
            collapsible_guidelines = '''

              {/* Format Guidelines - Collapsible */}
              <div className="mt-4 pt-4 border-t border-slate-800">
                <button
                  onClick={() => setShowGuidelines(!showGuidelines)}
                  className="flex items-center justify-between w-full text-left py-2 hover:text-white transition-colors"
                >
                  <span className="text-sm font-semibold text-slate-300">
                    📋 Format Guidelines & Required Fields
                  </span>
                  <span className="text-slate-400">{showGuidelines ? '▼' : '▶'}</span>
                </button>
                
                {showGuidelines && (
                  <div className="mt-3 p-4 bg-slate-950/50 rounded-xl border border-slate-800">
                    <div className="text-sm space-y-3">
                      <div>
                        <div className="font-semibold text-white mb-1">Tools:</div>
                        <div className="text-slate-400">Required: name*</div>
                        <div className="text-slate-400">Optional: category, owner_email, owner_name, criticality, url, description, status, last_used_date, cost_per_month, risk_score, notes</div>
                      </div>
                      <div>
                        <div className="font-semibold text-white mb-1">Employees:</div>
                        <div className="text-slate-400">Required: full_name*, email*</div>
                        <div className="text-slate-400">Optional: department, role, status, start_date, end_date</div>
                      </div>
                      <div>
                        <div className="font-semibold text-white mb-1">Access:</div>
                        <div className="text-slate-400">Required: tool_name*, employee_email*</div>
                        <div className="text-slate-400">Optional: access_level, granted_date, last_accessed_date, last_reviewed_date, status, risk_flag</div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
'''
            
            content = content[:card_body_end] + collapsible_guidelines + content[card_body_end:]
            print("  ✅ Added collapsible guidelines to Bulk Import card")
            
            # Now remove the old standalone Format Guidelines card
            # Find the entire Card block
            card_end = content.find('</Card>', format_card_start) + 7
            
            # Remove it
            content = content[:format_card_start] + content[card_end:]
            print("  ✅ Removed old Format Guidelines card")
        
        break
    
    format_card_start = next_card

# Now improve Current Workspace section
current_workspace = content.find('title="Current workspace"', import_page)
if current_workspace != -1:
    # Find the CardBody containing the grid
    card_body_start = content.find('<CardBody>', current_workspace)
    card_body_end = content.find('</CardBody>', current_workspace)
    
    # Replace with better design
    new_workspace = '''<CardBody>
              <div className="space-y-4">
                {/* Summary Stats */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-xl p-5">
                    <div className="flex items-center justify-between mb-2">
                      <Boxes className="h-8 w-8 text-blue-400" />
                      <span className="text-xs font-bold text-blue-400">TOOLS</span>
                    </div>
                    <div className="text-4xl font-black text-white">{db?.tools?.length ?? 0}</div>
                    <div className="text-sm text-slate-400 mt-1">In inventory</div>
                  </div>
                  
                  <div className="bg-gradient-to-br from-violet-500/10 to-violet-600/10 border border-violet-500/20 rounded-xl p-5">
                    <div className="flex items-center justify-between mb-2">
                      <Users className="h-8 w-8 text-violet-400" />
                      <span className="text-xs font-bold text-violet-400">EMPLOYEES</span>
                    </div>
                    <div className="text-4xl font-black text-white">{db?.employees?.length ?? 0}</div>
                    <div className="text-sm text-slate-400 mt-1">Team members</div>
                  </div>
                  
                  <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-xl p-5">
                    <div className="flex items-center justify-between mb-2">
                      <GitMerge className="h-8 w-8 text-emerald-400" />
                      <span className="text-xs font-bold text-emerald-400">ACCESS</span>
                    </div>
                    <div className="text-4xl font-black text-white">{db?.access?.length ?? 0}</div>
                    <div className="text-sm text-slate-400 mt-1">Permissions</div>
                  </div>
                </div>
                
                {/* Quick Actions */}
                <div className="flex gap-3 pt-2">
                  <button className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-sm font-semibold transition-colors" onClick={() => window.location.href = '/tools'}>
                    View Tools →
                  </button>
                  <button className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-sm font-semibold transition-colors" onClick={() => window.location.href = '/employees'}>
                    View Employees →
                  </button>
                  <button className="flex-1 px-4 py-3 bg-slate-800 hover:bg-slate-700 text-white rounded-xl text-sm font-semibold transition-colors" onClick={() => window.location.href = '/access'}>
                    View Access →
                  </button>
                </div>
              </div>
            '''
    
    content = content[:card_body_start] + new_workspace + content[card_body_end:]
    print("  ✅ Improved Current Workspace section")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

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
        echo "║  ✅ IMPORT PAGE REDESIGNED!                            ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 IMPROVEMENTS:                                      ║"
        echo "║                                                        ║"
        echo "║  ✅ Format Guidelines moved into Bulk Import card      ║"
        echo "║  ✅ Collapsible (click to show/hide)                   ║"
        echo "║  ✅ Saves screen space                                 ║"
        echo "║                                                        ║"
        echo "║  ✅ Current Workspace redesigned:                      ║"
        echo "║     • Beautiful gradient cards                         ║"
        echo "║     • Bigger numbers, clearer icons                    ║"
        echo "║     • Quick action buttons (View Tools/Employees)      ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 TEST IT:"
        echo "   Go to /import page"
        echo "   Click 'Format Guidelines' to expand/collapse"
        echo "   See new Current Workspace cards with quick actions!"
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
echo "✅ Import page looks amazing! 🎨"
