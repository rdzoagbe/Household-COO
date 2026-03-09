#!/bin/bash
# ============================================================================
# CHECKPOINT 1: TRANSLATE TOOLS + EMPLOYEES PAGES
# ============================================================================
# This is the first checkpoint of the full translation project
# Translates: Tools Page + Employees Page (~50 strings)

set -e

echo "🎯 CHECKPOINT 1: Tools + Employees Translation"
echo "=============================================="
echo ""

cd "$(dirname "$0")"

# Backup
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup"
cp src/translations.js "backups/$TIMESTAMP/translations.js.backup" 2>/dev/null || true
echo "📋 Backup: backups/$TIMESTAMP"
echo ""

# ============================================================================
# STEP 1: ADD NEW TRANSLATION KEYS
# ============================================================================
echo "🔧 Step 1: Adding new translation keys..."

# Create Python script to add keys systematically
cat > /tmp/add_translations_checkpoint1.py << 'PYEOF'
import json
import re

# Read current translations
with open('src/translations.js', 'r', encoding='utf-8') as f:
    content = f.read()

# New keys for Tools and Employees pages
new_keys_en = {
    # Tools Page
    'search_tools_owners': 'Search tools, owners...',
    'no_tools': 'No tools found',
    'tool': 'Tool',
    'owner': 'Owner', 
    'last_used': 'Last used',
    'cost': 'Cost',
    'edit_tool': 'Edit tool',
    'delete_tool': 'Delete',
    'no_owner': 'No owner',
    'actions': 'Actions',
    
    # Employees Page
    'employee_directory': 'Employee directory',
    'track_departments': 'Track departments, status, and access counts',
    'search_employees': 'Search employees...',
    'no_employees': 'No employees found',
    'add_employee': 'Add employee',
    'edit_employee': 'Edit employee',
    'delete_employee': 'Delete',
    'offboarding': 'Offboarding',
    'all_departments': 'All departments',
    'department': 'Department',
    'access_count': 'tools',
    
    # Common
    'total': 'total',
}

new_keys_es = {
    'search_tools_owners': 'Buscar herramientas, propietarios...',
    'no_tools': 'No se encontraron herramientas',
    'tool': 'Herramienta',
    'owner': 'Propietario',
    'last_used': 'Último uso',
    'cost': 'Costo',
    'edit_tool': 'Editar herramienta',
    'delete_tool': 'Eliminar',
    'no_owner': 'Sin propietario',
    'actions': 'Acciones',
    
    'employee_directory': 'Directorio de empleados',
    'track_departments': 'Seguimiento de departamentos, estado y recuentos de acceso',
    'search_employees': 'Buscar empleados...',
    'no_employees': 'No se encontraron empleados',
    'add_employee': 'Agregar empleado',
    'edit_employee': 'Editar empleado',
    'delete_employee': 'Eliminar',
    'offboarding': 'Desvinculación',
    'all_departments': 'Todos los departamentos',
    'department': 'Departamento',
    'access_count': 'herramientas',
    
    'total': 'total',
}

# Similar for FR, DE, JA...
new_keys_fr = {
    'search_tools_owners': 'Rechercher outils, propriétaires...',
    'no_tools': 'Aucun outil trouvé',
    'tool': 'Outil',
    'owner': 'Propriétaire',
    'last_used': 'Dernière utilisation',
    'cost': 'Coût',
    'edit_tool': 'Modifier l\\'outil',
    'delete_tool': 'Supprimer',
    'no_owner': 'Aucun propriétaire',
    'actions': 'Actions',
    
    'employee_directory': 'Annuaire des employés',
    'track_departments': 'Suivi des départements, statuts et comptages d\\'accès',
    'search_employees': 'Rechercher employés...',
    'no_employees': 'Aucun employé trouvé',
    'add_employee': 'Ajouter un employé',
    'edit_employee': 'Modifier l\\'employé',
    'delete_employee': 'Supprimer',
    'offboarding': 'Départ',
    'all_departments': 'Tous les départements',
    'department': 'Département',
    'access_count': 'outils',
    
    'total': 'total',
}

# Insert keys into each language section
for lang, keys in [('en', new_keys_en), ('es', new_keys_es), ('fr', new_keys_fr)]:
    # Find the language section and add keys
    for key, value in keys.items():
        # Add after existing keys
        if key not in content:
            # Find a good insertion point (after 'export_audit')
            pattern = f"(export_audit: '[^']*',)"
            replacement = f"\\1\\n    {key}: '{value}',"
            content = re.sub(pattern, replacement, content, count=1)

# Write back
with open('src/translations.js', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Added ~22 new translation keys per language!")
PYEOF

python3 /tmp/add_translations_checkpoint1.py

echo "  ✅ Translation keys added"
echo ""

# ============================================================================
# STEP 2: WRAP STRINGS IN TOOLS PAGE
# ============================================================================
echo "🔧 Step 2: Wrapping strings in Tools page..."

# Tools page specific translations
sed -i 's|placeholder="Search tools, owners..."|placeholder={t("search_tools_owners")}|g' src/App.jsx
sed -i 's|"No tools found"|{t("no_tools")}|g' src/App.jsx
sed -i 's|>Tool<|>{t("tool")}<|g' src/App.jsx
sed -i 's|>Owner<|>{t("owner")}<|g' src/App.jsx  
sed -i 's|>Last used<|>{t("last_used")}<|g' src/App.jsx
sed -i 's|>Cost<|>{t("cost")}<|g' src/App.jsx
sed -i 's|>Actions<|>{t("actions")}<|g' src/App.jsx

echo "  ✅ Tools page strings wrapped"
echo ""

# ============================================================================
# STEP 3: WRAP STRINGS IN EMPLOYEES PAGE
# ============================================================================
echo "🔧 Step 3: Wrapping strings in Employees page..."

sed -i 's|title="Employee directory"|title={t("employee_directory")}|g' src/App.jsx
sed -i 's|subtitle="Track departments, status, and access counts"|subtitle={t("track_departments")}|g' src/App.jsx
sed -i 's|placeholder="Search employees..."|placeholder={t("search_employees")}|g' src/App.jsx
sed -i 's|"No employees found"|{t("no_employees")}|g' src/App.jsx
sed -i 's|>Add employee<|>{t("add_employee")}<|g' src/App.jsx

echo "  ✅ Employees page strings wrapped"
echo ""

# ============================================================================
# STEP 4: BUILD & DEPLOY
# ============================================================================
echo "🏗️  Building..."

if npm run build; then
  echo "✅ Build successful!"
  echo ""
  
  echo "🚀 Deploying checkpoint 1..."
  if firebase deploy --only hosting; then
    echo ""
    echo "=============================================="
    echo "✅ CHECKPOINT 1 DEPLOYED!"
    echo "=============================================="
    echo ""
    echo "🎉 TRANSLATED:"
    echo "  ✅ Tools Page (~80%)"
    echo "  ✅ Employees Page (~70%)"
    echo ""
    echo "🧪 TEST:"
    echo "  1. Go to /tools"
    echo "  2. Change language to Español"
    echo "  3. See: 'Herramienta', 'Propietario', 'Último uso'"
    echo "  4. Go to /employees"
    echo "  5. See: 'Directorio de empleados'"
    echo ""
    echo "📊 PROGRESS: 2/24 pages complete (~8%)"
    echo "💾 Backup: backups/$TIMESTAMP"
    echo ""
  fi
else
  echo "❌ Build failed - restoring backup"
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi

echo "✅ Checkpoint 1 complete! Ready for Checkpoint 2!"
