#!/usr/bin/env bash
set -euo pipefail

[[ -f "package.json" ]] || { echo "❌ Run from project root (package.json not found)."; exit 1; }
[[ -f "firebase.json" ]] || { echo "❌ firebase.json not found."; exit 1; }

echo "🔧 Installing dependencies..."
npm ci || npm install

echo ""
echo "🏗️  Building production bundle..."
npm run build

echo ""
echo "🚀 Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Done."
