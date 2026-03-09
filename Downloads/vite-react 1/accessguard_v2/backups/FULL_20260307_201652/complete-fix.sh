#!/bin/bash
# ============================================================================
# ACCESSGUARD V2 - COMPLETE ONE-SHOT FIX
# ============================================================================
# This script fixes ALL issues and deploys in one command
# Run: ./complete-fix.sh

set -e

echo "🚀 AccessGuard V2 - Complete Auto-Fix & Deploy"
echo "================================================"
echo ""

cd "$(dirname "$0")"

# ============================================================================
# STEP 1: BACKUP
# ============================================================================
echo "📋 Step 1: Creating backup..."
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mkdir -p "backups/$TIMESTAMP"
cp src/App.jsx "backups/$TIMESTAMP/App.jsx.backup" 2>/dev/null || true
cp firebase.json "backups/$TIMESTAMP/firebase.json.backup" 2>/dev/null || true
echo "✅ Backup created: backups/$TIMESTAMP"
echo ""

# ============================================================================
# STEP 2: CREATE FIXED APP.JSX FROM SCRATCH
# ============================================================================
echo "🔧 Step 2: Creating fixed App.jsx..."

# Create the complete fixed App.jsx with imports at the top
cat > src/App.jsx << 'APPJSX_END'
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Link,
  Navigate,
  Outlet,
  useLocation,
  useNavigate,
} from "react-router-dom";
import { onAuthStateChanged } from "firebase/auth";
import { auth, getUserProfile } from "./firebase-config";
import { useTranslation } from './translations';
import { AssignOwnersButton } from './Modals';

function useAuth() {
  const [user, setUser] = React.useState(null);
  const [loading, setLoading] = React.useState(true);
  React.useEffect(() => {
    const unsub = onAuthStateChanged(auth, (u) => {
      setUser(u);
      setLoading(false);
    });
    return () => unsub();
  }, []);
  return { user, loading };
}

function AuthRedirectGate({ children }) {
  const { firebaseUser, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  
  useEffect(() => {
    let cancelled = false;
    async function run() {
      if (loading) return;
      if (firebaseUser) {
        const { user: userData, error } = await getUserProfile(firebaseUser.uid);
        const completed = Boolean(
          userData?.onboardingCompleted || userData?.onboardingComplete
        );
        const p = location.pathname;
        const isPublicEntry =
          p === "/" || p === "/login" || p === "/finish-signup" || p === "/onboarding";
        if (!cancelled && isPublicEntry) {
          navigate(completed ? "/dashboard" : "/onboarding", { replace: true });
        }
        if (!cancelled && isPublicEntry && error) {
          navigate("/dashboard", { replace: true });
        }
      }
    }
    run();
    return () => {
      cancelled = true;
    };
  }, [firebaseUser, loading, location.pathname, navigate]);
  
  return children;
}
APPJSX_END

# Append the rest of the original file (skipping the first 71 lines which we just recreated)
tail -n +72 "backups/$TIMESTAMP/App.jsx.backup" >> src/App.jsx 2>/dev/null || {
  echo "⚠️  Could not find backup, using current structure"
}

echo "✅ Fixed App.jsx created with proper imports"
echo ""

# ============================================================================
# STEP 3: FIX FIREBASE.JSON
# ============================================================================
echo "🔧 Step 3: Fixing firebase.json..."

cat > firebase.json << 'FIREBASEJSON_END'
{
  "hosting": {
    "public": "dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/index.html",
        "headers": [
          { "key": "Cache-Control", "value": "no-cache" }
        ]
      },
      {
        "source": "/assets/**",
        "headers": [
          { "key": "Cache-Control", "value": "public,max-age=31536000,immutable" }
        ]
      }
    ]
  }
}
FIREBASEJSON_END

echo "✅ firebase.json fixed"
echo ""

# ============================================================================
# STEP 4: FIX TRANSLATIONS FILE
# ============================================================================
echo "🔧 Step 4: Fixing translations file..."

if [ -f "src/translations.jsx" ]; then
  mv src/translations.jsx src/translations.js
  echo "✅ Renamed translations.jsx → translations.js"
elif [ -f "src/translations.js" ]; then
  echo "✅ translations.js already correct"
else
  echo "⚠️  No translations file found"
fi
echo ""

# ============================================================================
# STEP 5: CLEAN BUILD
# ============================================================================
echo "🧹 Step 5: Cleaning build cache..."
rm -rf dist
rm -rf node_modules/.vite 2>/dev/null || true
echo "✅ Build cache cleared"
echo ""

# ============================================================================
# STEP 6: BUILD
# ============================================================================
echo "🏗️  Step 6: Building project..."
if npm run build; then
  echo "✅ Build successful!"
else
  echo ""
  echo "❌ BUILD FAILED!"
  echo "Restoring backup..."
  cp "backups/$TIMESTAMP/App.jsx.backup" src/App.jsx
  exit 1
fi
echo ""

# ============================================================================
# STEP 7: DEPLOY
# ============================================================================
echo "🚀 Step 7: Deploying to Firebase..."
if firebase deploy --only hosting; then
  echo ""
  echo "================================================"
  echo "✅ DEPLOYMENT SUCCESSFUL!"
  echo "================================================"
  echo ""
  echo "🌐 Your site is live at:"
  echo "   https://accessguard-v2.web.app"
  echo ""
  echo "🎉 All fixes applied:"
  echo "   ✅ App.jsx imports fixed"
  echo "   ✅ useNavigate added"
  echo "   ✅ firebase.json rewrites added"
  echo "   ✅ translations file renamed"
  echo "   ✅ Project built successfully"
  echo "   ✅ Deployed to production"
  echo ""
  echo "💾 Backup saved: backups/$TIMESTAMP"
  echo ""
  echo "🧪 Test your site:"
  echo "   1. Go to https://accessguard-v2.web.app"
  echo "   2. Change language → should translate"
  echo "   3. Refresh page → should work"
  echo "   4. No console errors → should be clean"
  echo ""
else
  echo ""
  echo "❌ DEPLOYMENT FAILED!"
  echo "But build succeeded, so you can try deploying manually:"
  echo "   firebase deploy --only hosting"
  exit 1
fi

echo "🎊 ALL DONE! Your site is ready!"
