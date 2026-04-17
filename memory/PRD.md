# Household COO — Product Requirements Document

## Overview
A premium mobile-first Expo React Native app that acts as an AI "Chief of Staff" for parents, handling the mental load of family life. Operates on a three-tier architecture: **Capture → Intelligence → Execution**.

## Tech Stack
- **Frontend**: Expo SDK 54 + expo-router + expo-blur + expo-linear-gradient + expo-image-picker + @expo-google-fonts (Playfair Display Italic + Inter) + lucide-react-native
- **Backend**: FastAPI + Motor/MongoDB
- **Auth**: Emergent-managed Google OAuth (session cookie + Bearer token)
- **AI (text)**: Gemini 3 Flash Preview via `emergentintegrations` (Sunday Brief, voice→card classifier, vision→card extractor)
- **AI (audio)**: OpenAI Whisper-1 via `emergentintegrations` (voice transcription)
- **AI (vision)**: Gemini 3 Flash Preview multimodal (flyer scan → structured card)

## Core Features (shipped)
1. **Smart Feed** — Glass-card timeline with category colors (SIGN_SLIP orange, RSVP indigo, TASK emerald), due dates, assignee, source icons (AI / Voice / Camera / Manual). Toggle complete, delete, pull-to-refresh.
2. **Capture — 3 Modes**:
   - **Manual Entry** — type a card
   - **Voice Capture** — MediaRecorder → Whisper-1 transcript → Gemini classifier → prefilled draft
   - **Camera / Scan Flyer** — image picker (or camera) → Gemini Vision → structured card draft
3. **AI Sunday Brief** — Gemini summarizes the week's items into a warm 180-word strategy report
4. **Conflict Intelligence** — `GET /api/cards/conflicts?due_date=` returns overlapping events within ±2h
5. **Recurring Tasks + Reminders** — daily/weekly/monthly recurrence auto-spawns next instance on DONE; reminder minutes (15m / 1h / 1d before); feed shows "Reminders today" banner for items due in next 24h.
6. **Calendar** — events grouped by day (Today / Tomorrow / weekday)
7. **Vault** — 2-column secure grid (Medical / School / Insurance / Legal), base64 image upload
8. **Kids + Stars + Rewards** — children auto-earn 5★ on TASK DONE (assignee match on Child role). Parents create rewards ("Pizza Night 100★"). Kids redeem → stars deducted. Horizontal child selector with per-child star totals.
9. **Email Invites (Resend)** — Parent taps "Invite co-parent" in Settings → enters email → Resend sends branded invitation email with join link → recipient signs in with Google and is auto-merged into the same family_id (shared feed/calendar/vault/kids).
10. **Settings** — profile, family members, invite co-parent, language (English/Spanish i18n with interpolation), logout
11. **Navigation** — 5 bottom tabs: Feed · Calendar · **Kids** · Vault · Settings. Floating action bar over the tab bar with Mic / Camera / Manual quick-capture.

## Data Models
- `users`: user_id, email, name, picture, family_id, language
- `user_sessions`: user_id, session_token, expires_at (7-day)
- `family_members`: member_id, family_id, name, role, **stars**
- `cards`: card_id, family_id, type, title, description, assignee, due_date, status, source, **recurrence, reminder_minutes**, created_at, completed_at
- `vault`: doc_id, family_id, title, category, image_base64, created_at
- `rewards`: reward_id, family_id, title, cost_stars, icon, created_at
- `reward_redemptions`: redemption_id, family_id, member_id, reward_id, title, cost_stars, redeemed_at

## API Routes (all `/api` prefixed)
Auth: `POST /auth/session`, `GET /auth/me`, `POST /auth/logout`, `PATCH /auth/language`
Family: `GET /family/members`
Cards: `GET /cards`, `POST /cards`, `PATCH /cards/{id}`, `DELETE /cards/{id}`, `GET /cards/conflicts?due_date=&exclude_id=`
Vault: `GET /vault`, `POST /vault`, `DELETE /vault/{id}`
Rewards: `GET /rewards`, `POST /rewards`, `DELETE /rewards/{id}`, `POST /rewards/{id}/redeem`
AI: `POST /brief/weekly`, `POST /voice/transcribe`, `POST /vision/extract`

## Deploy-readiness
- `app.json` ships camera/mic/photo permissions for iOS + Android
- All secrets via `.env` (`MONGO_URL`, `DB_NAME`, `EMERGENT_LLM_KEY`)
- No hardcoded URLs (frontend uses `EXPO_PUBLIC_BACKEND_URL`)
- MongoDB `_id` excluded on every response
- Cookie-based session + Bearer fallback for mobile
- Dark glassmorphism UI, safe areas respected, keyboard avoiding views

## Roadmap (next)
- Push notifications via FCM (requires native build + Firebase project)
- Verify custom domain in Resend for sending to any recipient (currently limited to account owner email until domain verified)
- Firebase Storage for large PDF vault docs
- Kid-PIN lock on Kids tab / true multi-user "Kid Mode"
- "Share the Brief" viral feature — one-tap image share of weekly Sunday Brief
