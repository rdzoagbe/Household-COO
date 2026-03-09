#!/bin/bash
# Emergency restore - removes upgrade code causing errors

set -e

echo "🚑 Emergency Restore"
echo "===================="
echo ""

cd "$(dirname "$0")"

# Find the most recent pre-upgrade backup
BACKUP=$(ls -t backups/*/App.jsx.backup 2>/dev/null | head -1)

if [ -z "$BACKUP" ]; then
    echo "❌ No backup found!"
    exit 1
fi

echo "📋 Restoring from: $BACKUP"
cp "$BACKUP" src/App.jsx

echo "✅ Restored!"
echo ""
echo "🏗️  Building..."

if npm run build; then
    echo "✅ Build successful!"
    echo ""
    echo "🚀 Deploying..."
    firebase deploy --only hosting
    echo ""
    echo "✅ Emergency restore complete!"
    echo "   Your app should be working now."
else
    echo "❌ Build still failing - may need manual fix"
    exit 1
fi
