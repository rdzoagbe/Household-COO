# Household COO build notes

## What was prepared
- Added `eas.json` with development, preview, and production build profiles.
- Switched the frontend API base URL to `EXPO_PUBLIC_BACKEND_URL` with a fallback.
- Removed the incomplete native Google Sign-In config placeholder from `app.json`.
- Added a native auth-session sign-in flow using `expo-web-browser` and deep linking.

## Before your first EAS build
1. Create `.env` from `.env.example` and set the real backend URL.
2. Confirm the backend you want to use actually exposes the `/api/*` routes expected by `src/api.ts`.
3. Run `npx expo install` if dependencies are out of sync.
4. Log in to Expo: `eas login`
5. Configure the project: `eas build:configure`

## Suggested commands
```bash
npm install
cp .env.example .env
npx expo start --tunnel
eas build --profile development --platform android
eas build --profile preview --platform android
eas build --profile production --platform android
```

## Known blockers still outside this patch
- `backend/server.py` in this repo does not implement the `/api/*` routes used by the frontend.
- `src/api.ts` references invite-related methods that are not implemented in the exported `api` object yet (`getInvite`, `invite`).
- The repo documentation points to an Emergent preview backend, which is different from the Railway backend described separately.
