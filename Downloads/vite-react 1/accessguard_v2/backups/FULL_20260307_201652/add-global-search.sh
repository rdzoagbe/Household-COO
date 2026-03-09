#!/bin/bash
# ============================================================================
# ADD GLOBAL SEARCH - CMD/CTRL+K
# ============================================================================
# Adds a global search modal that can search across:
# - Tools
# - Employees  
# - Access records
# Keyboard shortcut: Cmd+K (Mac) or Ctrl+K (Windows)

set -e

echo "🔍 Adding Global Search Feature"
echo "================================"
echo ""
echo "This will add:"
echo "  ✅ Global search modal (Cmd/Ctrl+K)"
echo "  ✅ Search across Tools, Employees, Access"
echo "  ✅ Keyboard shortcuts"
echo "  ✅ Quick navigation to results"
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

echo "🔧 Adding GlobalSearch component..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find a good place to insert GlobalSearch component (after Modal component)
modal_component = content.find('function Modal(')
if modal_component == -1:
    print("  ❌ Modal component not found")
    exit(1)

# Find the end of Modal component
next_function = content.find('\nfunction ', modal_component + 10)

# Insert GlobalSearch component
global_search_component = '''
function GlobalSearch({ isOpen, onClose }) {
  const { data: db } = useDbQuery();
  const [query, setQuery] = useState('');
  const navigate = useNavigate();
  const inputRef = useRef(null);

  const results = useMemo(() => {
    if (!db || !query.trim()) return { tools: [], employees: [], access: [] };
    
    const q = query.toLowerCase();
    
    return {
      tools: db.tools.filter(t => 
        t.name.toLowerCase().includes(q) || 
        t.owner_name?.toLowerCase().includes(q) ||
        t.category?.toLowerCase().includes(q)
      ).slice(0, 5),
      employees: db.employees.filter(e => 
        e.full_name.toLowerCase().includes(q) || 
        e.email.toLowerCase().includes(q) ||
        e.department?.toLowerCase().includes(q)
      ).slice(0, 5),
      access: db.access.filter(a => 
        a.tool_name?.toLowerCase().includes(q) || 
        a.employee_email?.toLowerCase().includes(q)
      ).slice(0, 5)
    };
  }, [db, query]);

  const totalResults = results.tools.length + results.employees.length + results.access.length;

  useEffect(() => {
    if (isOpen && inputRef.current) {
      inputRef.current.focus();
    }
  }, [isOpen]);

  const handleResultClick = (type, item) => {
    onClose();
    setQuery('');
    
    if (type === 'tool') {
      navigate('/tools');
    } else if (type === 'employee') {
      navigate('/employees');
    } else if (type === 'access') {
      navigate('/access');
    }
  };

  if (!isOpen) return null;

  return (
    <div 
      className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-start justify-center pt-[20vh]"
      onClick={onClose}
    >
      <div 
        className="w-full max-w-2xl bg-slate-900 rounded-2xl shadow-2xl border border-slate-700"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search Input */}
        <div className="p-4 border-b border-slate-700">
          <div className="relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
            <input
              ref={inputRef}
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search tools, employees, access..."
              className="w-full pl-12 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white placeholder-slate-400 focus:outline-none focus:border-blue-500"
            />
          </div>
          <div className="flex items-center gap-2 mt-2 text-xs text-slate-400">
            <kbd className="px-2 py-1 bg-slate-800 rounded border border-slate-600">Esc</kbd>
            <span>to close</span>
            <kbd className="px-2 py-1 bg-slate-800 rounded border border-slate-600 ml-auto">⌘K</kbd>
            <span>to open</span>
          </div>
        </div>

        {/* Results */}
        <div className="max-h-96 overflow-y-auto p-2">
          {!query.trim() ? (
            <div className="text-center py-12 text-slate-400">
              <Search className="h-12 w-12 mx-auto mb-3 opacity-50" />
              <p>Start typing to search...</p>
            </div>
          ) : totalResults === 0 ? (
            <div className="text-center py-12 text-slate-400">
              <p>No results found for "{query}"</p>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Tools Results */}
              {results.tools.length > 0 && (
                <div>
                  <div className="px-3 py-2 text-xs font-semibold text-slate-400 uppercase">
                    Tools ({results.tools.length})
                  </div>
                  {results.tools.map(tool => (
                    <button
                      key={tool.id}
                      onClick={() => handleResultClick('tool', tool)}
                      className="w-full px-3 py-2 rounded-lg hover:bg-slate-800 text-left transition-colors flex items-center gap-3"
                    >
                      <Boxes className="h-5 w-5 text-blue-400 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <div className="text-white font-medium truncate">{tool.name}</div>
                        <div className="text-xs text-slate-400 truncate">{tool.category} • {tool.owner_name || 'No owner'}</div>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {/* Employees Results */}
              {results.employees.length > 0 && (
                <div>
                  <div className="px-3 py-2 text-xs font-semibold text-slate-400 uppercase">
                    Employees ({results.employees.length})
                  </div>
                  {results.employees.map(emp => (
                    <button
                      key={emp.id}
                      onClick={() => handleResultClick('employee', emp)}
                      className="w-full px-3 py-2 rounded-lg hover:bg-slate-800 text-left transition-colors flex items-center gap-3"
                    >
                      <Users className="h-5 w-5 text-emerald-400 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <div className="text-white font-medium truncate">{emp.full_name}</div>
                        <div className="text-xs text-slate-400 truncate">{emp.email} • {emp.department}</div>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {/* Access Results */}
              {results.access.length > 0 && (
                <div>
                  <div className="px-3 py-2 text-xs font-semibold text-slate-400 uppercase">
                    Access Records ({results.access.length})
                  </div>
                  {results.access.map((acc, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleResultClick('access', acc)}
                      className="w-full px-3 py-2 rounded-lg hover:bg-slate-800 text-left transition-colors flex items-center gap-3"
                    >
                      <GitMerge className="h-5 w-5 text-purple-400 flex-shrink-0" />
                      <div className="flex-1 min-w-0">
                        <div className="text-white font-medium truncate">{acc.tool_name}</div>
                        <div className="text-xs text-slate-400 truncate">{acc.employee_email} • {acc.access_level}</div>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

'''

content = content[:next_function] + global_search_component + content[next_function:]

print("  ✅ GlobalSearch component added")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 1 failed" && exit 1

echo ""
echo "🔧 Adding global search to App component..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the App function
app_func = content.find('function App()')
if app_func == -1:
    print("  ❌ App function not found")
    exit(1)

# Add search state after existing states
func_start = content.find('{', app_func) + 1

# Add state
search_state = '''
  const [searchOpen, setSearchOpen] = useState(false);

  // Global search keyboard shortcut
  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setSearchOpen(true);
      }
      if (e.key === 'Escape') {
        setSearchOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

'''

content = content[:func_start] + search_state + content[func_start:]

print("  ✅ Added search state and keyboard shortcut")

# Now add GlobalSearch component to the render (before closing App div)
# Find the return statement in App
app_return = content.find('return (', app_func)
routes_end = content.find('</Routes>', app_return)
router_div_end = content.find('</div>', routes_end)

# Add GlobalSearch before the closing div
global_search_usage = '''
      
      {/* Global Search */}
      <GlobalSearch isOpen={searchOpen} onClose={() => setSearchOpen(false)} />
'''

content = content[:router_div_end] + global_search_usage + content[router_div_end:]

print("  ✅ Added GlobalSearch to App render")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

[ $? -ne 0 ] && echo "  ❌ Step 2 failed" && exit 1

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
        echo "║  ✅ GLOBAL SEARCH ADDED!                               ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🔍 FEATURES:                                          ║"
        echo "║  • Press Cmd+K (Mac) or Ctrl+K (Windows)              ║"
        echo "║  • Search across Tools, Employees, Access             ║"
        echo "║  • See results instantly                               ║"
        echo "║  • Click to navigate                                   ║"
        echo "║  • Press Esc to close                                  ║"
        echo "║                                                        ║"
        echo "║  💡 TRY IT:                                            ║"
        echo "║  1. Press Cmd/Ctrl+K anywhere in the app             ║"
        echo "║  2. Type 'slack' or 'john' or anything               ║"
        echo "║  3. See instant results!                               ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
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
echo "✅ Global Search is live! Try pressing Cmd/Ctrl+K! 🚀"
