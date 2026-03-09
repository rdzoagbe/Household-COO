// ============================================================================
// FIREBASE CONFIGURATION — SaasGuard
// ============================================================================
// Data layer:  Firestore (cloud, per-user, cross-device)
// AI layer:    Cloud Functions proxy (API key never in browser)
// Auth:        Google redirect + Magic link
// ============================================================================

import { initializeApp } from 'firebase/app';
import {
  getAuth,
  signInWithRedirect,
  getRedirectResult,
  GoogleAuthProvider,
  signOut,
  onAuthStateChanged,
  sendSignInLinkToEmail,
  isSignInWithEmailLink,
  signInWithEmailLink,
  getIdToken,
} from 'firebase/auth';
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
} from 'firebase/firestore';
import { getAnalytics, isSupported } from 'firebase/analytics';

const firebaseConfig = {
  apiKey:            "AIzaSyCh2aYFWEfwurFOS9X2zyI0jucyk99bzWQ",
  authDomain:        "accessguard-v2.firebaseapp.com",
  projectId:         "accessguard-v2",
  storageBucket:     "accessguard-v2.firebasestorage.app",
  messagingSenderId: "1060400630820",
  appId:             "1:1060400630820:web:e5b4dbd3e87f2cc02c9cb1",
  measurementId:     "G-MDRVRX854L",
};

const app             = initializeApp(firebaseConfig);
const auth            = getAuth(app);
const firestoreDb     = getFirestore(app);
const googleProvider  = new GoogleAuthProvider();
let   analytics       = null;

isSupported().then(ok => { if (ok) analytics = getAnalytics(app); });

googleProvider.addScope('profile');
googleProvider.addScope('email');

// Cloud Functions base URL — deployed region
const FUNCTIONS_BASE = 'https://us-central1-accessguard-v2.cloudfunctions.net';

// ============================================================================
// AUTH HELPERS
// ============================================================================
async function getToken() {
  const user = auth.currentUser;
  if (!user) return null;
  return getIdToken(user, false);
}

// ============================================================================
// AI PROXY — Anthropic calls go through Cloud Function only
// ============================================================================
export async function callAI({ messages, system, max_tokens = 2000 }) {
  const token = await getToken();
  if (!token) throw new Error('Not authenticated');

  const res = await fetch(`${FUNCTIONS_BASE}/ai`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ messages, system, max_tokens }),
  });

  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'AI call failed');
  return data;
}

// ============================================================================
// FIRESTORE DATA LAYER
// /userdata/{uid} → { tools, employees, access, user }
// ============================================================================
export async function loadUserData(uid) {
  try {
    const snap = await getDoc(doc(firestoreDb, 'userdata', uid));
    return snap.exists() ? snap.data() : null;
  } catch (err) {
    console.error('loadUserData:', err);
    return null;
  }
}

export async function saveUserData(uid, db) {
  try {
    await setDoc(
      doc(firestoreDb, 'userdata', uid),
      { ...db, _uid: uid, _updatedAt: Date.now() },
      { merge: false }
    );
  } catch (err) {
    console.error('saveUserData:', err);
    throw err;
  }
}

export async function syncUserProfile(user) {
  try {
    const token = await getIdToken(user);
    const res = await fetch(`${FUNCTIONS_BASE}/syncuser`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({
        email:       user.email,
        displayName: user.displayName,
        photoURL:    user.photoURL,
      }),
    });
    return await res.json();
  } catch (err) {
    console.error('syncUserProfile:', err);
    return { isNew: false };
  }
}

// ============================================================================
// AUTHENTICATION
// ============================================================================
export async function signInWithGoogle() {
  try {
    await signInWithRedirect(auth, googleProvider);
    return { user: null, error: null };
  } catch (error) {
    return { user: null, error: error.message };
  }
}

export async function handleRedirectResult() {
  try {
    const result = await getRedirectResult(auth);
    if (result?.user) return { user: result.user, error: null };
    return { user: null, error: null };
  } catch (error) {
    return { user: null, error: error.message };
  }
}

export async function signOutUser() {
  try {
    await signOut(auth);
    return { error: null };
  } catch (error) {
    return { error: error.message };
  }
}

export function onAuthChange(callback) {
  return onAuthStateChanged(auth, callback);
}

export async function sendMagicLink(email) {
  const actionCodeSettings = {
    url: window.location.origin + '/finishSignUp',
    handleCodeInApp: true,
  };
  try {
    await sendSignInLinkToEmail(auth, email, actionCodeSettings);
    window.localStorage.setItem('emailForSignIn', email);
    return { error: null };
  } catch (error) {
    return { error: error.message };
  }
}

export async function completeMagicLinkSignIn() {
  if (isSignInWithEmailLink(auth, window.location.href)) {
    let email = window.localStorage.getItem('emailForSignIn');
    if (!email) {
      email = window.prompt('Please provide your email for confirmation');
    }
    try {
      const result = await signInWithEmailLink(auth, email, window.location.href);
      window.localStorage.removeItem('emailForSignIn');
      return { user: result.user, error: null };
    } catch (error) {
      return { user: null, error: error.message };
    }
  }
  return { user: null, error: 'Invalid sign-in link' };
}

export { auth, firestoreDb as db, analytics };
