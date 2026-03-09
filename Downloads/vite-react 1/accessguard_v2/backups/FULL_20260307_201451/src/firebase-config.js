// ============================================================================
// FIREBASE CONFIGURATION
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
} from 'firebase/auth';
import {
  getFirestore,
  collection,
  doc,
  getDoc,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  getDocs,
} from 'firebase/firestore';
import { getAnalytics, isSupported } from 'firebase/analytics';

// Your Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyCh2aYFWEfwurFOS9X2zyI0jucyk99bzWQ",
  authDomain: "accessguard-v2.firebaseapp.com",
  projectId: "accessguard-v2",
  storageBucket: "accessguard-v2.firebasestorage.app",
  messagingSenderId: "1060400630820",
  appId: "1:1060400630820:web:e5b4dbd3e87f2cc02c9cb1",
  measurementId: "G-MDRVRX854L"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
let analytics = null;
isSupported().then((ok) => { if (ok) analytics = getAnalytics(app); });
const googleProvider = new GoogleAuthProvider();

// Add Google Workspace Admin API scopes
googleProvider.addScope('https://www.googleapis.com/auth/admin.directory.user.readonly');
googleProvider.addScope('https://www.googleapis.com/auth/gmail.readonly');
googleProvider.addScope('profile');
googleProvider.addScope('email');

// Add Google Workspace Admin API scopes

// ============================================================================
// AUTHENTICATION FUNCTIONS
// ============================================================================

/**
 * Sign in with Google popup
 */
export async function signInWithGoogle() {
  try {
    await signInWithRedirect(auth, googleProvider);
    // User will be redirected away, then back
    // Result is handled by getRedirectResult in useAuth
    return { user: null, error: null };
  } catch (error) {
    console.error('Google sign-in error:', error);
    return { user: null, error: error.message };
  }
}

/**
 * Handle redirect result after Google sign-in
 * Call this when app loads
 */
export async function handleRedirectResult() {
  try {
    const result = await getRedirectResult(auth);
    if (result) {
      return { user: result.user, error: null };
    }
    return { user: null, error: null };
  } catch (error) {
    console.error('Redirect result error:', error);
    return { user: null, error: error.message };
  }
}

/**
 * Sign out current user
 */
export async function signOutUser() {
  try {
    await signOut(auth);
    return { error: null };
  } catch (error) {
    console.error('Sign-out error:', error);
    return { error: error.message };
  }
}

/**
 * Listen to auth state changes
 */
export function onAuthChange(callback) {
  return onAuthStateChanged(auth, callback);
}

/**
 * Send magic link email
 */
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
    console.error('Magic link error:', error);
    return { error: error.message };
  }
}

/**
 * Complete magic link sign-in
 */
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
      console.error('Magic link completion error:', error);
      return { user: null, error: error.message };
    }
  }
  return { user: null, error: 'Invalid sign-in link' };
}

// ============================================================================
// USER PROFILE FUNCTIONS
// ============================================================================

/**
 * Get user profile from Firestore
 */
export async function getUserProfile(uid) {
  try {
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (userDoc.exists()) {
      return { user: userDoc.data(), error: null };
    }
    return { user: null, error: 'User not found' };
  } catch (error) {
    console.error('Error getting user profile:', error);
    return { user: null, error: error.message };
  }
}

/**
 * Complete user onboarding
 */
export async function completeOnboarding(uid, profileData) {
  try {
    await setDoc(doc(db, 'users', uid), {
      ...profileData,
      onboardingCompleted: true,
      createdAt: new Date().toISOString(),
    }, { merge: true });
    return { success: true, error: null };
  } catch (error) {
    console.error('Error completing onboarding:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Update user profile
 */
export async function updateUserProfile(uid, updates) {
  try {
    await updateDoc(doc(db, 'users', uid), {
      ...updates,
      updatedAt: new Date().toISOString(),
    });
    return { success: true, error: null };
  } catch (error) {
    console.error('Error updating user profile:', error);
    return { success: false, error: error.message };
  }
}

// ============================================================================
// FIRESTORE HELPER FUNCTIONS
// ============================================================================

/**
 * Add a document to a collection
 */
export async function addDocument(collectionName, data) {
  try {
    const docRef = await addDoc(collection(db, collectionName), {
      ...data,
      createdAt: new Date().toISOString(),
    });
    return { id: docRef.id, error: null };
  } catch (error) {
    console.error('Error adding document:', error);
    return { id: null, error: error.message };
  }
}

/**
 * Get a document by ID
 */
export async function getDocument(collectionName, docId) {
  try {
    const docSnap = await getDoc(doc(db, collectionName, docId));
    if (docSnap.exists()) {
      return { data: docSnap.data(), error: null };
    }
    return { data: null, error: 'Document not found' };
  } catch (error) {
    console.error('Error getting document:', error);
    return { data: null, error: error.message };
  }
}

/**
 * Update a document
 */
export async function updateDocument(collectionName, docId, updates) {
  try {
    await updateDoc(doc(db, collectionName, docId), {
      ...updates,
      updatedAt: new Date().toISOString(),
    });
    return { success: true, error: null };
  } catch (error) {
    console.error('Error updating document:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Delete a document
 */
export async function deleteDocument(collectionName, docId) {
  try {
    await deleteDoc(doc(db, collectionName, docId));
    return { success: true, error: null };
  } catch (error) {
    console.error('Error deleting document:', error);
    return { success: false, error: error.message };
  }
}

/**
 * Query documents with a condition
 */
export async function queryDocuments(collectionName, field, operator, value) {
  try {
    const q = query(collection(db, collectionName), where(field, operator, value));
    const querySnapshot = await getDocs(q);
    const documents = [];
    querySnapshot.forEach((doc) => {
      documents.push({ id: doc.id, ...doc.data() });
    });
    return { documents, error: null };
  } catch (error) {
    console.error('Error querying documents:', error);
    return { documents: [], error: error.message };
  }
}

// ============================================================================
// EXPORTS
// ============================================================================

export { auth, db, analytics };
