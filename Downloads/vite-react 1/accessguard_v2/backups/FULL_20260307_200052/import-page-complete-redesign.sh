#!/bin/bash
# ============================================================================
# IMPORT PAGE - COMPLETE REDESIGN
# ============================================================================
# Creates a beautiful, uniform, full-width layout:
# - Quick templates at top (3 cards)
# - Bulk import section (full-width)
# - Format guidelines (collapsible at bottom)
# - Current workspace stats (at bottom)

set -e

echo "🎨 Import Page - Complete Redesign"
echo "==================================="
echo ""
echo "New layout:"
echo "  1. Quick Templates (3 cards, full-width)"
echo "  2. Bulk Import (main section)"
echo "  3. Format Guidelines + Workspace (bottom, 2 columns)"
echo ""
echo "⏱️  Estimated time: 5 minutes"
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

echo "🔧 Redesigning Import page with clean layout..."

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Find ImportPage
import_start = content.find('function ImportPage(')
if import_start == -1:
    print("  ❌ ImportPage not found")
    exit(1)

# Find where AppShell opens
appshell_start = content.find('<AppShell', import_start)
appshell_end = content.find('>', appshell_start) + 1

# Find where the current content grid starts (the lg:grid-cols-12)
grid_start = content.find('<div className="grid gap-5 lg:grid-cols-12">', import_start)

# Find the closing </AppShell> for ImportPage
next_function = content.find('\nfunction ', import_start + 100)
appshell_close = content.rfind('</AppShell>', import_start, next_function)

if grid_start == -1 or appshell_close == -1:
    print("  ❌ Could not find grid structure")
    exit(1)

# Replace everything between AppShell opening and closing with new layout
new_content = '''
      {/* Quick Import Templates - Full Width */}
      <div className="mb-6">
        <h3 className="text-xl font-bold text-white mb-4">📊 Quick Import Templates</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-blue-500/50 transition-colors cursor-pointer" onClick={() => { setKind('tools'); setText(templates.tools); setImported(null); resetValidation(); }}>
            <div className="flex items-center justify-between mb-3">
              <Boxes className="h-8 w-8 text-blue-400" />
              <span className="px-2 py-1 bg-blue-500/20 text-blue-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Tools</div>
            <div className="text-sm text-slate-400">Click to load CSV template</div>
          </div>
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-emerald-500/50 transition-colors cursor-pointer" onClick={() => { setKind('employees'); setText(templates.employees); setImported(null); resetValidation(); }}>
            <div className="flex items-center justify-between mb-3">
              <Users className="h-8 w-8 text-emerald-400" />
              <span className="px-2 py-1 bg-emerald-500/20 text-emerald-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Employees</div>
            <div className="text-sm text-slate-400">Click to load CSV template</div>
          </div>
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 hover:border-purple-500/50 transition-colors cursor-pointer" onClick={() => { setKind('access'); setText(templates.access); setImported(null); resetValidation(); }}>
            <div className="flex items-center justify-between mb-3">
              <GitMerge className="h-8 w-8 text-purple-400" />
              <span className="px-2 py-1 bg-purple-500/20 text-purple-400 text-xs font-bold rounded-full">CSV</span>
            </div>
            <div className="text-white font-bold text-lg mb-1">Import Access</div>
            <div className="text-sm text-slate-400">Click to load CSV template</div>
          </div>
        </div>
      </div>

      {/* Bulk Import - Full Width */}
      <Card className="mb-6">
        <CardHeader title={t('bulk_import') || "Bulk import"} subtitle="Paste or type CSV data" />
        <CardBody>
          <div className="grid gap-3 md:grid-cols-3 mb-4">
            <div className="md:col-span-1">
              <div className="mb-1 text-xs font-semibold text-slate-400">Entity type</div>
              <Select value={kind} onChange={(e) => { setKind(e.target.value); setText(""); setImported(null); resetValidation(); }}>
                <option value="tools">Tools</option>
                <option value="employees">Employees</option>
                <option value="access">Access Records</option>
              </Select>
            </div>
            <div className="md:col-span-2 flex items-end justify-end gap-2">
              <Button variant="secondary" onClick={() => { setText(templates[kind]); setImported(null); resetValidation(); }}>
                <Download className="h-4 w-4" /> Paste template
              </Button>
              <Button variant="secondary" onClick={() => downloadText(\`\${kind}_template.csv\`, templates[kind])}>
                <Download className="h-4 w-4" /> Download
              </Button>
            </div>
          </div>

          <Textarea
            rows={10}
            className="font-mono text-xs mb-3"
            value={text}
            onChange={(e) => { setText(e.target.value); setImported(null); resetValidation(); }}
            placeholder="Paste CSV here..."
          />

          {liveRows.length > 0 && (
            <div className="mb-3 flex flex-wrap items-center gap-3 text-xs">
              <span className="text-slate-400">{liveRows.length} row(s) detected</span>
              {validCount > 0 && <span className="text-emerald-400 font-semibold">✓ {validCount} valid</span>}
              {invalidCount > 0 && <span className="text-rose-400 font-semibold">✗ {invalidCount} missing required fields</span>}
            </div>
          )}

          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex gap-2">
              <Button variant="secondary" disabled={!text.trim() || liveRows.length === 0} onClick={runValidation}>
                <Check className="h-4 w-4" /> Validate data
              </Button>
              <Button disabled={!text.trim() || validCount === 0 || importing || (validated && validationErrors.length > 0)} onClick={handleImport}>
                {importing ? <><RefreshCw className="h-4 w-4 animate-spin" /> Importing…</> : <><Upload className="h-4 w-4" /> Import {validCount > 0 ? \`\${validCount} record\${validCount > 1 ? "s" : ""}\` : ""}</>}
              </Button>
            </div>
            <div className="text-xs text-slate-500">Validate before importing</div>
          </div>
        </CardBody>
      </Card>

      {/* Format Guidelines + Current Workspace - Bottom Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader title="📋 Format Guidelines" subtitle="Required fields marked *" />
          <CardBody>
            <div className="space-y-3 text-sm">
              <div>
                <div className="font-semibold text-white mb-1">Tools:</div>
                <div className="text-slate-400">Required: <span className="text-blue-400">name*</span></div>
              </div>
              <div>
                <div className="font-semibold text-white mb-1">Employees:</div>
                <div className="text-slate-400">Required: <span className="text-blue-400">full_name*, email*</span></div>
              </div>
              <div>
                <div className="font-semibold text-white mb-1">Access:</div>
                <div className="text-slate-400">Required: <span className="text-blue-400">tool_name*, employee_email*</span></div>
              </div>
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader title="📊 Current Workspace" subtitle="Records in your database" />
          <CardBody>
            <div className="grid grid-cols-3 gap-3">
              <div className="bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-500/20 rounded-xl p-4 text-center">
                <Boxes className="h-6 w-6 mx-auto mb-2 text-blue-400" />
                <div className="text-3xl font-black text-white">{db?.tools?.length ?? 0}</div>
                <div className="text-xs text-slate-400 mt-1">Tools</div>
              </div>
              <div className="bg-gradient-to-br from-violet-500/10 to-violet-600/10 border border-violet-500/20 rounded-xl p-4 text-center">
                <Users className="h-6 w-6 mx-auto mb-2 text-violet-400" />
                <div className="text-3xl font-black text-white">{db?.employees?.length ?? 0}</div>
                <div className="text-xs text-slate-400 mt-1">Employees</div>
              </div>
              <div className="bg-gradient-to-br from-emerald-500/10 to-emerald-600/10 border border-emerald-500/20 rounded-xl p-4 text-center">
                <GitMerge className="h-6 w-6 mx-auto mb-2 text-emerald-400" />
                <div className="text-3xl font-black text-white">{db?.access?.length ?? 0}</div>
                <div className="text-xs text-slate-400 mt-1">Access</div>
              </div>
            </div>
          </CardBody>
        </Card>
      </div>
'''

# Replace the content between AppShell and closing tag
content = content[:appshell_end] + new_content + '\n    ' + content[appshell_close:]

print("  ✅ Created new clean Import page layout")
print("  ✅ Full-width design")
print("  ✅ All sections visible and organized")

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
        echo "║  ✅ IMPORT PAGE COMPLETELY REDESIGNED!                 ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🎨 NEW CLEAN LAYOUT:                                  ║"
        echo "║                                                        ║"
        echo "║  ✅ Quick Templates (top, 3 cards)                     ║"
        echo "║  ✅ Bulk Import (middle, full-width)                   ║"
        echo "║  ✅ Format Guidelines (bottom-left)                    ║"
        echo "║  ✅ Current Workspace (bottom-right)                   ║"
        echo "║                                                        ║"
        echo "║  🎯 EVERYTHING VISIBLE, UNIFORM, FULL-WIDTH!           ║"
        echo "║                                                        ║"
        echo "╚════════════════════════════════════════════════════════╝"
        echo ""
        echo "🧪 CHECK IT OUT:"
        echo "   Go to /import and see the beautiful new layout!"
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
echo "✅ Import page is now beautiful and uniform! 🎨"
