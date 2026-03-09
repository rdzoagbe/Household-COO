#!/bin/bash
set -e
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
echo -e "\n${BLUE}Fix: Labels + Renewals reviewed column${NC}\n"
[ ! -f "package.json" ] && echo -e "${RED}Run from project root${NC}" && exit 1
TS=$(date +%Y%m%d_%H%M%S)
mkdir -p "backups/$TS"
cp src/App.jsx "backups/$TS/App.jsx"
[ -f src/translations.js ] && cp src/translations.js "backups/$TS/translations.js"
echo -e "${GREEN}Backup done${NC}\n"

python3 << 'PYEOF'
import re, sys

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    app = f.read()

ok = []

# ══════════════════════════════════════════════════════════════
# 1. FIX ALL RAW UNDERSCORE KEYS — replace t('key') with
#    hardcoded proper English strings where translation missing
# ══════════════════════════════════════════════════════════════
label_fixes = {
    "t('need_review_soon')":    '"Need review soon"',
    "t('review_all_critical')": '"Review All Critical"',
    "t('set_reminders')":       '"Set Reminders"',
    "t('reset_demo_data')":     '"Reset Demo Data"',
    "t('export_audit')":        '"Export Audit"',
    "t('live')":                '"Live"',
    "t('updated')":             '"Updated"',
    "t('all_clear')":           '"All Clear"',
    "t('top_alerts')":          '"Top Alerts"',
    "t('risk_counters')":       '"Risk Counters"',
    "t('by_severity')":         '"By Severity"',
    "t('coverage_and_spend')":  '"Coverage & Spend"',
    "t('fast_remediation')":    '"Fast Remediation"',
    "t('assign_tool_owners')":  '"Assign Tool Owners"',
    "t('no_active_alerts')":    '"No Active Alerts"',
    "t('no_employees')":        '"No Employees"',
    "t('no_tools')":            '"No Tools"',
    "t('no_owner')":            '"No Owner"',
    "t('top_alerts_desc')":     '"Top alerts by severity"',
    "t('track_departments')":   '"Track Departments"',
    "t('employee_directory')":  '"Employee Directory"',
    "t('search_employees')":    '"Search employees..."',
    "t('search_tools_owners')": '"Search tools & owners..."',
    "t('delete_employee')":     '"Delete Employee"',
    "t('delete_tool')":         '"Delete Tool"',
    "t('edit_employee')":       '"Edit Employee"',
    "t('edit_tool')":           '"Edit Tool"',
    "t('add_employee')":        '"Add Employee"',
    "t('add_tool')":            '"Add Tool"',
    "t('bulk_import')":         '"Bulk Import"',
    "t('access_count')":        '"Access Count"',
    "t('actions')":             '"Actions"',
    "t('owner')":               '"Owner"',
    "t('tool')":                '"Tool"',
    "t('cost')":                '"Cost"',
    "t('last_used')":           '"Last Used"',
    "t('dashboard')":           '"Dashboard"',
    "t('tools')":               '"Tools"',
    "t('employees')":           '"Employees"',
    "t('access')":              '"Access Map"',
    "t('integrations')":        '"Integrations"',
    "t('import')":              '"Import Data"',
    "t('offboarding')":         '"Offboarding"',
    "t('audit')":               '"Audit Export"',
    "t('billing')":             '"Billing"',
    "t('finance')":             '"Finance"',
    "t('executive_view')":      '"Executive View"',
    "t('licenses')":            '"Licenses"',
    "t('renewals')":            '"Renewals"',
    "t('invoices')":            '"Invoices"',
    "t('security')":            '"Security"',
    "t('cost_management')":     '"Cost Management"',
    "t('analytics')":           '"Analytics"',
    "t('settings')":            '"Settings"',
    "t('contracts')":           '"Contracts"',
}

fixed_count = 0
for raw, proper in label_fixes.items():
    count = app.count(raw)
    if count > 0:
        app = app.replace(raw, proper)
        fixed_count += count

ok.append("Fixed " + str(fixed_count) + " raw underscore t() key renders")

# ══════════════════════════════════════════════════════════════
# 2. RENEWALS — Add reviewedApps state + move to reviewed column
#    When "Mark as Reviewed" clicked:
#      - Add renewal to reviewedApps set
#      - Remove from active table
#      - Show in a "Reviewed" section below
# ══════════════════════════════════════════════════════════════

# Add reviewedApps state after existing state declarations
OLD_STATE = '  const [reminderDays, setReminderDays] = useState(30);\n'
NEW_STATE = (
    '  const [reminderDays, setReminderDays] = useState(30);\n'
    '  const [reviewedApps, setReviewedApps] = useState([]);\n'
)
if OLD_STATE in app:
    app = app.replace(OLD_STATE, NEW_STATE, 1)
    ok.append("Renewals: added reviewedApps state")

# Fix the "Mark as Reviewed" button — mark + remove from active list
OLD_MARK = (
    '                onClick={() => setShowReviewModal(false)}\n'
    '                className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-500 rounded-xl font-semibold transition-colors"\n'
    '              >\n'
    '                Mark as Reviewed\n'
    '              </button>'
)
NEW_MARK = (
    '                onClick={() => {\n'
    '                  setReviewedApps(prev => [...prev, selectedRenewal.app]);\n'
    '                  setShowReviewModal(false);\n'
    '                }}\n'
    '                className="w-full px-4 py-3 bg-emerald-600 hover:bg-emerald-500 rounded-xl font-semibold transition-colors flex items-center justify-center gap-2"\n'
    '              >\n'
    '                ✓ Mark as Reviewed\n'
    '              </button>'
)
if OLD_MARK in app:
    app = app.replace(OLD_MARK, NEW_MARK, 1)
    ok.append("Renewals: Mark as Reviewed — moves to reviewed section")

# Filter active table to exclude reviewed apps
OLD_TABLE_SORT = '{renewals.sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => ('
NEW_TABLE_SORT = '{renewals.filter(r => !reviewedApps.includes(r.app)).sort((a, b) => a.daysUntil - b.daysUntil).map((renewal, idx) => ('
if OLD_TABLE_SORT in app:
    app = app.replace(OLD_TABLE_SORT, NEW_TABLE_SORT, 1)
    ok.append("Renewals: active table filters out reviewed apps")

# Add reviewed section after the main renewals table Card closing tag
# Find the end of the renewals table card
OLD_AFTER_TABLE = '        {/* Review Modal */}'
NEW_AFTER_TABLE = (
    '        {/* Reviewed Apps Section */}\n'
    '        {reviewedApps.length > 0 && (\n'
    '          <Card className="p-6 mt-6 border-emerald-500/20 bg-emerald-500/5">\n'
    '            <div className="flex items-center gap-3 mb-4">\n'
    '              <div className="h-8 w-8 rounded-full bg-emerald-500/20 flex items-center justify-center">\n'
    '                <BadgeCheck className="h-4 w-4 text-emerald-400" />\n'
    '              </div>\n'
    '              <h3 className="text-lg font-bold text-white">Reviewed Apps</h3>\n'
    '              <span className="text-xs bg-emerald-500/20 text-emerald-400 px-2 py-0.5 rounded-full font-semibold">{reviewedApps.length} reviewed</span>\n'
    '            </div>\n'
    '            <div className="overflow-x-auto">\n'
    '              <table className="w-full">\n'
    '                <thead>\n'
    '                  <tr className="border-b border-emerald-500/20">\n'
    '                    <th className="text-left py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">Application</th>\n'
    '                    <th className="text-left py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">Renewal Date</th>\n'
    '                    <th className="text-right py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">Cost</th>\n'
    '                    <th className="text-left py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">Owner</th>\n'
    '                    <th className="text-right py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide">Status</th>\n'
    '                    <th className="text-right py-3 px-4 text-xs font-semibold text-emerald-400/70 uppercase tracking-wide"></th>\n'
    '                  </tr>\n'
    '                </thead>\n'
    '                <tbody>\n'
    '                  {renewals.filter(r => reviewedApps.includes(r.app)).map((renewal, idx) => (\n'
    '                    <tr key={idx} className="border-b border-emerald-500/10 hover:bg-emerald-500/5">\n'
    '                      <td className="py-3 px-4">\n'
    '                        <div className="font-semibold text-white">{renewal.app}</div>\n'
    '                        <div className="text-xs text-slate-500">{renewal.term} contract</div>\n'
    '                      </td>\n'
    '                      <td className="py-3 px-4 text-slate-300">{renewal.renewalDate}</td>\n'
    '                      <td className="py-3 px-4 text-right font-mono text-white">${renewal.cost.toLocaleString()}</td>\n'
    '                      <td className="py-3 px-4 text-slate-300">{renewal.owner}</td>\n'
    '                      <td className="py-3 px-4 text-right">\n'
    '                        <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-400 bg-emerald-500/10 px-2.5 py-1 rounded-full">\n'
    '                          ✓ Reviewed\n'
    '                        </span>\n'
    '                      </td>\n'
    '                      <td className="py-3 px-4 text-right">\n'
    '                        <button\n'
    '                          onClick={() => setReviewedApps(prev => prev.filter(a => a !== renewal.app))}\n'
    '                          className="text-xs text-slate-500 hover:text-slate-300 transition-colors"\n'
    '                        >\n'
    '                          Undo\n'
    '                        </button>\n'
    '                      </td>\n'
    '                    </tr>\n'
    '                  ))}\n'
    '                </tbody>\n'
    '              </table>\n'
    '            </div>\n'
    '          </Card>\n'
    '        )}\n\n'
    '        {/* Review Modal */}'
)
if OLD_AFTER_TABLE in app:
    app = app.replace(OLD_AFTER_TABLE, NEW_AFTER_TABLE, 1)
    ok.append("Renewals: Reviewed Apps section added below active table")

# ══════════════════════════════════════════════════════════════
# 3. Also fix "pending_approval" pill showing in Invoices
# ══════════════════════════════════════════════════════════════
app = app.replace(
    "{invoice.status.replace('_', ' ')}",
    "{invoice.status.replace(/_/g, ' ').replace(/\\b\\w/g, c => c.toUpperCase())}"
)
ok.append("Invoices: status labels now title-cased (pending_approval → Pending Approval)")

# ══════════════════════════════════════════════════════════════
# 4. Fix bill.status raw render in Finance
# ══════════════════════════════════════════════════════════════
app = app.replace(
    '{bill.status}',
    "{bill.status.replace(/_/g, ' ').replace(/\\b\\w/g, c => c.toUpperCase())}"
)
ok.append("Finance: bill status now title-cased")

# ══════════════════════════════════════════════════════════════
print()
for s in ok:
    print("  OK: " + s)
print("\n  Lines: " + str(app.count('\n')))

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved")
PYEOF

[ $? -ne 0 ] && cp "backups/$TS/App.jsx" src/App.jsx && exit 1

# Fix translations.js too
python3 << 'PYEOF'
import re, os, sys

tp = 'src/translations.js'
if not os.path.exists(tp):
    sys.exit(0)

with open(tp, 'r') as f:
    t = f.read()

en_start = t.find('  en: {')
en_end   = t.find('\n  },', en_start)
en_block = t[en_start:en_end]

new_keys = [
    ("need_review_soon",    "Need review soon"),
    ("review_all_critical", "Review All Critical"),
    ("set_reminders",       "Set Reminders"),
    ("cost_management",     "Cost Management"),
    ("analytics",           "Analytics"),
    ("settings",            "Settings"),
    ("contracts",           "Contracts"),
    ("security",            "Security"),
    ("access",              "Access Map"),
]
added = []
for key, val in new_keys:
    if (key + ':') not in en_block:
        insert = "\n    " + key + ": '" + val + "',"
        t = t[:en_end] + insert + t[en_end:]
        en_end += len(insert)
        added.append(key)

with open(tp, 'w') as f:
    f.write(t)
if added:
    print("  translations.js: added " + ", ".join(added))
else:
    print("  translations.js: all keys present")
PYEOF

echo ""
echo -e "${BLUE}Building...${NC}"
rm -rf dist node_modules/.vite
npm run build || { cp "backups/$TS/App.jsx" src/App.jsx; exit 1; }
echo -e "${BLUE}Deploying...${NC}"
firebase deploy --only hosting

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗"
echo -e "║  Labels + Renewals fixed and deployed!                  ║"
echo -e "╠══════════════════════════════════════════════════════════╣"
echo -e "║  Labels: all underscore keys replaced with proper text  ║"
echo -e "║  Invoices: pending_approval → Pending Approval          ║"
echo -e "║  Finance: bill status labels now title-cased            ║"
echo -e "║  Renewals: Mark as Reviewed moves app to reviewed table ║"
echo -e "║  Renewals: Active table hides reviewed items            ║"
echo -e "║  Renewals: Reviewed section shows with Undo option      ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}\n"
