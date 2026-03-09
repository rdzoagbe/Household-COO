import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import './index.css'
import { handleRedirectResult } from './firebase-config.js'

// Handle Google redirect result BEFORE React mounts.
// This prevents RequireAuth from bouncing the user while getRedirectResult is pending.
handleRedirectResult().then(({ user }) => {
  if (user) {
    // Store the returning user in sessionStorage so App.jsx picks it up instantly
    sessionStorage.setItem('sg_redirect_user', JSON.stringify({
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    }));
  }
}).catch(() => {}).finally(() => {
  // Always mount React after redirect check completes
  ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>,
  );
});
