# Household COO — Auth Testing Playbook

## Overview
This app uses Emergent-managed Google OAuth. For automated testing, we seed a session token directly in MongoDB and set it as a cookie (or Authorization header).

## Test credentials
See `/app/memory/test_credentials.md` for the session token, user_id, family_id.

## Backend API testing
```bash
TOKEN="test_session_1776435744337"
BASE="https://ai-household.preview.emergentagent.com/api"
curl -H "Authorization: Bearer $TOKEN" $BASE/auth/me
curl -H "Authorization: Bearer $TOKEN" $BASE/cards
curl -H "Authorization: Bearer $TOKEN" $BASE/family/members
curl -H "Authorization: Bearer $TOKEN" $BASE/vault
curl -X POST -H "Authorization: Bearer $TOKEN" $BASE/brief/weekly
```

## Browser (Playwright) testing
Set the session cookie BEFORE navigating, then go directly to `/(tabs)/feed`:

```python
await page.context.add_cookies([{
    "name": "session_token",
    "value": "test_session_1776435744337",
    "domain": "ai-household.preview.emergentagent.com",
    "path": "/",
    "httpOnly": True,
    "secure": True,
    "sameSite": "None"
}])
await page.goto("https://ai-household.preview.emergentagent.com/(tabs)/feed")
```

The app's `/app/_layout.tsx` AuthGate calls `/api/auth/me` which reads the cookie or Authorization header and returns the user.

## Seed data
On first OAuth login, the backend seeds 3 family members (Emma, Liam, user) and 5 sample cards. The test session seeded above already has this data.

## Quick clean
```
mongosh --eval "use('test_database'); db.users.deleteMany({email: /test\\.user\\./}); db.user_sessions.deleteMany({session_token: /test_session_/});"
```
