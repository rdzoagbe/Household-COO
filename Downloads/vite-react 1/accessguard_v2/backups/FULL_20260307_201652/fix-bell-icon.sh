#!/bin/bash
set -e
echo "Fixing missing Bell icon..."
[ ! -f "package.json" ] && echo "Run from project root" && exit 1

python3 << 'PYEOF'
with open('src/App.jsx', 'r', encoding='utf-8', errors='replace') as f:
    app = f.read()

if 'Bell,' not in app and 'Bell ' not in app:
    app = app.replace('} from "lucide-react"', '  Bell,\n} from "lucide-react"', 1)
    print("  Added Bell to lucide-react imports ✓")
else:
    print("  Bell already imported — checking for other missing icons...")

# Also check for AlertTriangle which is used in Settings
for icon in ['AlertTriangle', 'Bell', 'ChevronRight', 'Boxes']:
    luc_end = app.find('} from "lucide-react"')
    luc_block = app[:luc_end]
    if icon + ',' not in luc_block and icon + ' ' not in luc_block:
        app = app.replace('} from "lucide-react"', f'  {icon},\n' + '} from "lucide-react"', 1)
        print(f"  Added {icon} to lucide-react imports ✓")

with open('src/App.jsx', 'w', encoding='utf-8') as f:
    f.write(app)
print("  Saved ✓")
PYEOF

echo "Building..."
npm run build || exit 1
echo "Deploying..."
firebase deploy --only hosting
echo "Done ✓"
