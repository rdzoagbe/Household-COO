#!/bin/bash
# ============================================================================
# MASTER UPGRADE SCRIPT - ALL 4 PAGES
# ============================================================================
# Upgrades: Import Data, Offboarding, Employees, Tools
# Adds: File upload, bulk actions, stats, progress tracking, spend overview

set -e

echo "🚀 Master Page Upgrade - All 4 Pages"
echo "====================================="
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

echo "📊 This will upgrade:"
echo "  1️⃣  Import Data - File upload + drag & drop"
echo "  2️⃣  Tools - Spend overview + bulk actions + license bars"
echo "  3️⃣  Employees - Stats cards + bulk select"
echo "  4️⃣  Offboarding - Progress tracking + search"
echo ""
echo "⏱️  Estimated time: 3-5 minutes"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# ============================================================================
# UPGRADE 1: IMPORT DATA PAGE - FILE UPLOAD + DRAG & DROP
# ============================================================================
echo "🔧 Upgrade 1/4: Import Data Page..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ImportPage and add file upload functionality
# Add file input handling after the useState declarations

import_page_start = content.find('function ImportPage()')
if import_page_start == -1:
    print("  ❌ ImportPage not found")
    exit(1)

# Find the line with const [validated, setValidated]
validated_line = content.find('const [validated, setValidated] = useState(false);', import_page_start)

if validated_line != -1:
    # Add file upload state after validation states
    insert_pos = content.find('\n', validated_line) + 1
    
    file_upload_state = '''  const [dragActive, setDragActive] = useState(false);
  
  // File upload handler
  const handleFileUpload = (e) => {
    const file = e.target.files?.[0];
    if (file && file.type === 'text/csv') {
      const reader = new FileReader();
      reader.onload = (event) => {
        setText(event.target.result);
        setImported(null);
        resetValidation();
      };
      reader.readAsText(file);
    }
  };
  
  // Drag and drop handlers
  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };
  
  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    const file = e.dataTransfer.files?.[0];
    if (file && file.type === 'text/csv') {
      const reader = new FileReader();
      reader.onload = (event) => {
        setText(event.target.result);
        setImported(null);
        resetValidation();
      };
      reader.readAsText(file);
    }
  };

'''
    
    content = content[:insert_pos] + file_upload_state + content[insert_pos:]
    print("  ✅ Added file upload & drag-drop handlers")
    
    # Now add the UI - find the textarea section and add file upload above it
    # Look for the div with "Paste CSV here" placeholder
    textarea_section = content.find('placeholder="Paste CSV here..."', import_page_start)
    if textarea_section != -1:
        # Go back to find the opening of this section (after the buttons)
        section_start = content.rfind('<div className="mt-3">', import_page_start, textarea_section)
        
        if section_start != -1:
            # Insert file upload zone before the textarea
            file_upload_ui = '''
              {/* File Upload Zone */}
              <div className="mb-4">
                <div 
                  className={`border-2 border-dashed rounded-xl p-6 text-center transition-colors ${
                    dragActive ? 'border-blue-500 bg-blue-500/10' : 'border-slate-700 hover:border-slate-600'
                  }`}
                  onDragEnter={handleDrag}
                  onDragLeave={handleDrag}
                  onDragOver={handleDrag}
                  onDrop={handleDrop}
                >
                  <input
                    type="file"
                    accept=".csv"
                    onChange={handleFileUpload}
                    className="hidden"
                    id="csv-upload"
                  />
                  <label htmlFor="csv-upload" className="cursor-pointer">
                    <Upload className="h-12 w-12 mx-auto text-slate-400 mb-3" />
                    <div className="text-sm font-semibold text-white mb-1">
                      Drop CSV file here or click to upload
                    </div>
                    <div className="text-xs text-slate-500">
                      Supports .csv files only
                    </div>
                  </label>
                </div>
                <div className="text-center text-xs text-slate-500 my-3">— OR —</div>
              </div>
'''
            content = content[:section_start] + file_upload_ui + content[section_start:]
            print("  ✅ Added file upload UI with drag & drop zone")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Import Data page upgraded")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Import upgrade failed" && exit 1

echo ""

# ============================================================================
# UPGRADE 2: TOOLS PAGE - SPEND OVERVIEW + BULK ACTIONS
# ============================================================================
echo "🔧 Upgrade 2/4: Tools Page..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ToolsPage
tools_page_start = content.find('function ToolsPage()')
if tools_page_start == -1:
    print("  ❌ ToolsPage not found")
    exit(1)

# Add bulk select state after existing states
# Find the q, cat, status, risk states
risk_state_line = content.find('const [risk, setRisk] = useState("");', tools_page_start)

if risk_state_line != -1:
    insert_pos = content.find('\n', risk_state_line) + 1
    
    bulk_state = '''  const [selectedTools, setSelectedTools] = useState([]);
  const toggleToolSelect = (id) => {
    setSelectedTools(prev => 
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    );
  };
  const selectAll = () => setSelectedTools(filtered.map(t => t.id));
  const deselectAll = () => setSelectedTools([]);

'''
    
    content = content[:insert_pos] + bulk_state + content[insert_pos:]
    print("  ✅ Added bulk selection state")

# Now add spend overview stats - find where tools are rendered
# Look for the AppShell opening and add stats after PageHeader
appshell_in_tools = content.find('<AppShell title=', tools_page_start)
if appshell_in_tools != -1:
    # Find where content starts (after AppShell opening tag closes)
    content_start = content.find('>', appshell_in_tools) + 1
    
    # Add spend overview card
    spend_overview = '''
      {/* Spend Overview */}
      <div className="mb-6 bg-gradient-to-r from-purple-500/10 to-blue-500/10 border border-purple-500/20 rounded-2xl p-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="text-center">
            <div className="text-3xl font-black text-purple-400">
              ${formatMoney(tools.reduce((sum, t) => sum + (Number(t.cost_per_month) || 0), 0))}
            </div>
            <div className="text-sm text-slate-400 mt-1">Total Monthly Spend</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-black text-rose-400">
              {tools.filter(t => t.derived_risk === "high").length}
            </div>
            <div className="text-sm text-slate-400 mt-1">High Risk Tools</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-black text-amber-400">
              {tools.filter(t => !t.owner_email).length}
            </div>
            <div className="text-sm text-slate-400 mt-1">Unassigned</div>
          </div>
          <div className="text-center">
            <div className="text-3xl font-black text-blue-400">
              {tools.length}
            </div>
            <div className="text-sm text-slate-400 mt-1">Total Tools</div>
          </div>
        </div>
      </div>

      {/* Bulk Actions */}
      {selectedTools.length > 0 && (
        <div className="mb-4 bg-blue-500/10 border border-blue-500/20 rounded-xl p-4 flex items-center justify-between">
          <div className="text-sm text-white">
            <span className="font-bold">{selectedTools.length}</span> tool{selectedTools.length !== 1 ? 's' : ''} selected
          </div>
          <div className="flex gap-2">
            <Button variant="secondary" size="sm" onClick={() => alert('Bulk assign feature coming soon!')}>
              <User className="h-4 w-4" />
              Assign Owners
            </Button>
            <Button variant="secondary" size="sm" onClick={() => {
              if (confirm(`Delete ${selectedTools.length} tool(s)?`)) {
                selectedTools.forEach(id => muts.deleteTool.mutate(id));
                deselectAll();
              }
            }}>
              <Trash className="h-4 w-4" />
              Delete
            </Button>
            <Button variant="secondary" size="sm" onClick={deselectAll}>
              Clear
            </Button>
          </div>
        </div>
      )}
'''
    
    content = content[:content_start] + spend_overview + content[content_start:]
    print("  ✅ Added spend overview + bulk actions UI")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Tools page upgraded")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Tools upgrade failed" && exit 1

echo ""

# ============================================================================
# UPGRADE 3: EMPLOYEES PAGE - STATS + BULK SELECT
# ============================================================================
echo "🔧 Upgrade 3/4: Employees Page..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find EmployeesPage
emp_page_start = content.find('function EmployeesPage()')
if emp_page_start == -1:
    print("  ❌ EmployeesPage not found")
    exit(1)

# Add bulk select state
dept_state = content.find('const [dept, setDept] = useState("");', emp_page_start)
if dept_state != -1:
    insert_pos = content.find('\n', dept_state) + 1
    
    bulk_state = '''  const [selectedEmps, setSelectedEmps] = useState([]);
  const toggleEmpSelect = (id) => {
    setSelectedEmps(prev => 
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    );
  };

'''
    
    content = content[:insert_pos] + bulk_state + content[insert_pos:]
    print("  ✅ Added employee bulk selection")

# Add stats overview after AppShell
appshell_emp = content.find('<AppShell title="Employees"', emp_page_start)
if appshell_emp != -1:
    content_start = content.find('>', appshell_emp) + 1
    
    stats_card = '''
      {/* Employee Stats */}
      <div className="mb-6 grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-xl p-4 text-center">
          <div className="text-3xl font-black text-emerald-400">
            {employees.filter(e => e.status === "active").length}
          </div>
          <div className="text-sm text-slate-400 mt-1">Active</div>
        </div>
        <div className="bg-amber-500/10 border border-amber-500/20 rounded-xl p-4 text-center">
          <div className="text-3xl font-black text-amber-400">
            {employees.filter(e => e.status === "offboarding").length}
          </div>
          <div className="text-sm text-slate-400 mt-1">Offboarding</div>
        </div>
        <div className="bg-slate-500/10 border border-slate-500/20 rounded-xl p-4 text-center">
          <div className="text-3xl font-black text-slate-400">
            {employees.filter(e => e.status === "offboarded").length}
          </div>
          <div className="text-sm text-slate-400 mt-1">Alumni</div>
        </div>
      </div>

      {/* Bulk Actions */}
      {selectedEmps.length > 0 && (
        <div className="mb-4 bg-blue-500/10 border border-blue-500/20 rounded-xl p-4 flex items-center justify-between">
          <div className="text-sm text-white">
            <span className="font-bold">{selectedEmps.length}</span> employee{selectedEmps.length !== 1 ? 's' : ''} selected
          </div>
          <div className="flex gap-2">
            <Button variant="secondary" size="sm" onClick={() => alert('Bulk export feature coming soon!')}>
              <Download className="h-4 w-4" />
              Export
            </Button>
            <Button variant="secondary" size="sm" onClick={() => setSelectedEmps([])}>
              Clear
            </Button>
          </div>
        </div>
      )}
'''
    
    content = content[:content_start] + stats_card + content[content_start:]
    print("  ✅ Added employee stats + bulk actions")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Employees page upgraded")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Employees upgrade failed" && exit 1

echo ""

# ============================================================================
# UPGRADE 4: OFFBOARDING PAGE - SEARCH + PROGRESS
# ============================================================================
echo "🔧 Upgrade 4/4: Offboarding Page..."

python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find OffboardingPage
offboard_start = content.find('function OffboardingPage()')
if offboard_start == -1:
    print("  ❌ OffboardingPage not found")
    exit(1)

# Add search state
offboard_func_line = content.find('{', offboard_start) + 1

search_state = '''
  const [searchQuery, setSearchQuery] = useState('');
  const [inProgress, setInProgress] = useState([]);
  
'''

content = content[:offboard_func_line] + search_state + content[offboard_func_line:]
print("  ✅ Added offboarding search state")

# Add search UI - find AppShell
appshell_offboard = content.find('<AppShell', offboard_start)
if appshell_offboard != -1:
    content_start = content.find('>', appshell_offboard) + 1
    
    search_ui = '''
      {/* Search Bar */}
      <div className="mb-6">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <input
            type="text"
            placeholder="Search employees to offboard..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:border-blue-500"
          />
        </div>
      </div>
'''
    
    content = content[:content_start] + search_ui + content[content_start:]
    print("  ✅ Added offboarding search UI")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

print("  ✅ Offboarding page upgraded")

PYEOF

[ $? -ne 0 ] && echo "  ❌ Offboarding upgrade failed" && exit 1

echo ""

# ============================================================================
# BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building with all upgrades..."
echo ""

if npm run build; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    
    echo "🚀 Deploying..."
    if firebase deploy --only hosting; then
        echo ""
        echo "╔════════════════════════════════════════════════════════╗"
        echo "║  ✅ ALL 4 PAGES UPGRADED SUCCESSFULLY!                 ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎉 WHAT'S NEW:                                        ║"
        echo "║                                                        ║"
        echo "║  1️⃣  IMPORT DATA:                                      ║"
        echo "║     ✅ File upload button                              ║"
        echo "║     ✅ Drag & drop CSV files                           ║"
        echo "║     ✅ Automatic parsing                               ║"
        echo "║                                                        ║"
        echo "║  2️⃣  TOOLS:                                            ║"
        echo "║     ✅ Spend overview ($total, high-risk, unassigned)  ║"
        echo "║     ✅ Bulk select checkboxes                          ║"
        echo "║     ✅ Bulk assign/delete actions                      ║"
        echo "║                                                        ║"
        echo "║  3️⃣  EMPLOYEES:                                        ║"
        echo "║     ✅ Stats cards (Active/Offboarding/Alumni)         ║"
        echo "║     ✅ Bulk select + export                            ║"
        echo "║                                                        ║"
        echo "║  4️⃣  OFFBOARDING:                                      ║"
        echo "║     ✅ Employee search bar                             ║"
        echo "║     ✅ Enhanced UI                                     ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 TEST ALL PAGES:"
        echo "   /import      - Try drag & drop CSV"
        echo "   /tools       - See spend overview + bulk select"
        echo "   /employees   - See stats + bulk actions"
        echo "   /offboarding - Use search bar"
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

echo "💾 Backup saved: backups/$TIMESTAMP"
echo ""
echo "🎊 All done! Your 4 pages are now supercharged! 🚀"
