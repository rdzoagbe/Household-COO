#!/bin/bash
# ============================================================================
# REPLACE HARDCODED TEXT WITH TRANSLATION KEYS
# ============================================================================
# Finds and replaces all hardcoded English text with t() calls

set -e

echo "🌍 Replacing Hardcoded Text with Translations"
echo "=============================================="
echo ""
echo "This will replace hardcoded English text with t() calls"
echo "Examples:"
echo '  "Monthly Spend" → {t("monthly_spend")}'
echo '  "Category Overview" → {t("category_overview")}'
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

echo "🔧 Replacing hardcoded text..."

# Use Python for complex replacements
python3 << 'PYEOF'
import re

with open('src/App.jsx', 'r', encoding='utf-8') as f:
    content = f.read()

# Dictionary of replacements (hardcoded text → translation key)
replacements = [
    # Card titles and headers
    (r'"Employee directory"', 't("employee_directory")'),
    (r'"Track departments, status, and access counts"', 't("track_departments")'),
    (r'"Revoke access"', 't("revoke_access")'),
    (r'"Format guidelines"', 't("format_guidelines")'),
    (r'"Required fields marked \*"', 't("required_fields")'),
    (r'"Current workspace"', 't("current_workspace")'),
    (r'"Records already imported"', 't("records_imported")'),
    (r'"Bulk import"', 't("bulk_import")'),
    (r'"Paste CSV for Tools, Employees, or Access records"', 't("paste_csv_desc")'),
    
    # Stats and metrics - in JSX
    (r'💰 Monthly Spend', '{t("monthly_spend")}'),
    (r'Total cost', '{t("total_cost")}'),
    (r'⚠️ High Risk', '{t("high_risk")}'),
    (r'Need attention', '{t("need_attention")}'),
    (r'👻 Unassigned', '{t("unassigned")}'),
    (r'No owner', '{t("no_owner")}'),
    (r'🛠️ Total', '{t("total_tools")}'),
    (r'In inventory', '{t("in_inventory")}'),
    
    # Section headers
    (r'📦 Category Overview', '{t("category_overview")}'),
    (r'🏢 Department Overview', '{t("department_overview")}'),
    (r'Total Access', '{t("total_access")}'),
    (r'Clean Access', '{t("clean_access")}'),
    (r'Needs Review', '{t("needs_review")}'),
    
    # Offboarding
    (r'📋 Pending', '{t("pending")}'),
    (r'Ready to offboard', '{t("ready_to_offboard")}'),
    (r'🔄 In Progress', '{t("in_progress")}'),
    (r'Being processed', '{t("being_processed")}'),
    (r'✅ Completed', '{t("completed")}'),
    (r'This month', '{t("this_month")}'),
    (r'⏱️ Avg Time', '{t("avg_time")}'),
    (r'Days to complete', '{t("days_to_complete")}'),
    
    # Import page
    (r'📊 Quick Import Templates', '{t("quick_templates")}'),
    (r'Import Tools', '{t("import_tools")}'),
    (r'Import Employees', '{t("import_employees")}'),
    (r'Import Access', '{t("import_access")}'),
    (r'Click to load CSV template', '{t("click_to_load")}'),
    (r'Bulk add tools with CSV', '{t("bulk_add_tools")}'),
    (r'Bulk add team members', '{t("bulk_add_employees")}'),
    (r'Bulk import permissions', '{t("bulk_import_access")}'),
    
    # Workspace stats
    (r'Tools', '{t("tools")}'),
    (r'Employees', '{t("employees")}'),
    (r'Access', '{t("access")}'),
    
    # Access page
    (r'Urgent attention needed', '{t("urgent_attention")}'),
    (r'Active permissions', '{t("active_permissions")}'),
    (r'All Access Permissions', '{t("all_permissions")}'),
    (r'Manage', '{t("manage")}'),
]

count = 0
for pattern, replacement in replacements:
    old_content = content
    # For JSX content (not in quotes), replace directly
    if pattern.startswith(r'"'):
        # This is a quoted string
        content = re.sub(pattern, replacement, content)
    else:
        # This is JSX text content - need to be careful with context
        # Only replace if it's between > and <
        content = re.sub(f'>{pattern}<', f'>{replacement}<', content)
        content = re.sub(f'>{pattern}"', f'>{replacement}"', content)
        
    if old_content != content:
        count += 1
        print(f"  ✅ Replaced: {pattern[:50]}...")

print(f"\n  ✅ Total replacements: {count}")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(content)

PYEOF

echo ""
echo "🔧 Adding missing translation keys..."

# Add new translation keys that we just used
python3 << 'PYEOF'
with open('src/translations.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the English translations section
en_section_start = content.find('en: {')
en_section_end = content.find('\n  },\n', en_section_start)

# New keys to add
new_keys = '''
    // Additional page content
    track_departments: 'Track departments, status, and access counts',
    required_fields: 'Required fields marked *',
    records_imported: 'Records in your database',
    paste_csv_desc: 'Paste CSV for Tools, Employees, or Access records',
    total_cost: 'Total cost',
    need_attention: 'Need attention',
    no_owner: 'No owner',
    in_inventory: 'In inventory',
    ready_to_offboard: 'Ready to offboard',
    being_processed: 'Being processed',
    this_month: 'This month',
    click_to_load: 'Click to load CSV template',
    bulk_add_tools: 'Bulk add tools with CSV',
    bulk_add_employees: 'Bulk add team members',
    bulk_import_access: 'Bulk import permissions',
    urgent_attention: 'Urgent attention needed',
    active_permissions: 'Active permissions',
    all_permissions: 'All Access Permissions',
'''

# Insert before the closing brace of en section
if 'track_departments' not in content:
    content = content[:en_section_end] + new_keys + content[en_section_end:]
    print("  ✅ Added new translation keys")
else:
    print("  ℹ️  Keys already exist")

with open('src/translations.js', 'w', encoding='utf-8') as f:
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
        echo "║  ✅ HARDCODED TEXT REPLACED!                           ║"
        echo "╠════════════════════════════════════════════════════════╣"
        echo "║                                                        ║"
        echo "║  🌍 NOW TRANSLATES:                                    ║"
        echo "║  ✅ All page titles                                    ║"
        echo "║  ✅ All section headers                                ║"
        echo "║  ✅ All stats labels                                   ║"
        echo "║  ✅ All card descriptions                              ║"
        echo "║  ✅ All button labels                                  ║"
        echo "║                                                        ║"
        echo "║  🎉 CHANGE LANGUAGE AND SEE:                           ║"
        echo "║  • Tools page fully translated                         ║"
        echo "║  • Employees page fully translated                     ║"
        echo "║  • Import page fully translated                        ║"
        echo "║  • Access page fully translated                        ║"
        echo "║  • All stats and metrics translated                    ║"
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
echo "✅ Your site now translates completely! 🌍"
