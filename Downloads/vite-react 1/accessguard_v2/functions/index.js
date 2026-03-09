/**
 * SaasGuard Cloud Functions
 * ─────────────────────────────────────────────────────────────
 * Uses firebase-functions v2 params (not deprecated config).
 * Store key: firebase functions:secrets:set ANTHROPIC_API_KEY
 * (Requires Blaze plan — upgrade is free until you exceed limits)
 *
 * OR for local testing, create functions/.env:
 *   ANTHROPIC_API_KEY=sk-ant-...
 */

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });

admin.initializeApp();

const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');

// ── Verify Firebase ID token ──────────────────────────────────
async function verifyAuth(req, res) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) { res.status(401).json({ error: 'Missing auth token' }); return null; }
  try {
    return await admin.auth().verifyIdToken(token);
  } catch {
    res.status(401).json({ error: 'Invalid auth token' });
    return null;
  }
}

// ── /ai — secure Anthropic proxy ─────────────────────────────
exports.ai = onRequest(
  { secrets: [ANTHROPIC_API_KEY], cors: true, timeoutSeconds: 60 },
  async (req, res) => {
    cors(req, res, async () => {
      if (req.method === 'OPTIONS') return res.status(204).send('');
      if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const { messages, system, max_tokens = 2000 } = req.body;
      if (!messages?.length) return res.status(400).json({ error: 'messages required' });

      try {
        const body = { model: 'claude-sonnet-4-20250514', max_tokens, messages };
        if (system) body.system = system;

        const response = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': ANTHROPIC_API_KEY.value(),
            'anthropic-version': '2023-06-01',
          },
          body: JSON.stringify(body),
        });

        const data = await response.json();
        if (!response.ok) return res.status(500).json({ error: data.error?.message || 'AI error' });
        return res.json(data);
      } catch (err) {
        console.error('AI proxy error:', err);
        return res.status(500).json({ error: 'Internal error' });
      }
    });
  }
);

// ── /syncuser — upsert user profile on sign-in ───────────────
exports.syncuser = onRequest(
  { cors: true },
  async (req, res) => {
    cors(req, res, async () => {
      if (req.method === 'OPTIONS') return res.status(204).send('');
      if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const { email, displayName, photoURL } = req.body;
      const uid = decoded.uid;
      const userRef = admin.firestore().collection('users').doc(uid);
      const snap = await userRef.get();

      if (!snap.exists) {
        await userRef.set({
          uid,
          email: email || decoded.email || '',
          displayName: displayName || decoded.name || '',
          photoURL: photoURL || decoded.picture || '',
          plan: 'free',
          createdAt: Date.now(),
          updatedAt: Date.now(),
        });
        return res.json({ isNew: true });
      } else {
        await userRef.update({ updatedAt: Date.now() });
        return res.json({ isNew: false, plan: snap.data().plan });
      }
    });
  }
);
