# Household COO — Product Requirements Document

## Overview
A premium mobile-first Expo React Native app that acts as an AI "Chief of Staff" for parents, handling the mental load of family life: school flyers, RSVPs, permission slips, and grocery/task lists.

## Tech Stack
- **Frontend**: Expo SDK 54 + React Native + expo-router (file-based routing), expo-blur, expo-linear-gradient, lucide-react-native, @expo-google-fonts (Playfair Display Italic + Inter)
- **Backend**: FastAPI + Motor (MongoDB)
- **Auth**: Emergent-managed Google OAuth (session cookie + Bearer token)
- **AI**: Gemini 3 Flash (via `emergentintegrations` + Emergent Universal LLM key)
- **Data storage**: MongoDB (users, user_sessions, family_members, cards, vault)

## Design
Dark glassmorphism aesthetic (#080910 void with radial indigo/orange/emerald glows), Playfair Display italic headings paired with Inter body. Every tap scales to 0.96. Card type colors: SIGN_SLIP orange (#F97316), RSVP indigo (#6366F1), TASK emerald (#10B981).

## Core Features (MVP)
1. **Landing + Google Sign-In** — Emergent OAuth, session exchange
2. **Smart Feed** — Scrollable glass-cards with type badges, due dates, assignee, source (AI/VOICE/CAMERA/MANUAL). Toggle complete, delete, pull-to-refresh.
3. **AI Sunday Brief** — Full-screen modal with Gemini 3 Flash-generated weekly summary based on open/completed items.
4. **Calendar** — Event list grouped by day showing upcoming due cards.
5. **Vault** — Secure document grid (Medical/School/Insurance/Legal) with base64 image storage; add/preview/delete.
6. **Settings** — Profile, family members (seeded Emma/Liam/user), language (English/Spanish), logout.
7. **Floating Action Bar** — Mic/Camera/Manual quick-entry buttons that open the add-card sheet with the correct source.
8. **i18n** — English + Spanish with interpolation support, persisted to user profile.

## Data Models
- `users`: user_id, email, name, picture, family_id, language
- `user_sessions`: user_id, session_token, expires_at (7-day cookie)
- `family_members`: member_id, family_id, name, role
- `cards`: card_id, family_id, type, title, description, assignee, due_date, status, source, created_at, completed_at
- `vault`: doc_id, family_id, title, category, image_base64, created_at

## API Routes (all `/api` prefixed)
Auth: `POST /auth/session`, `GET /auth/me`, `POST /auth/logout`, `PATCH /auth/language`
Family: `GET /family/members`
Cards: `GET /cards`, `POST /cards`, `PATCH /cards/{id}`, `DELETE /cards/{id}`
Vault: `GET /vault`, `POST /vault`, `DELETE /vault/{id}`
Brief: `POST /brief/weekly` (Gemini 3 Flash)

## Enhancement idea (smart business)
Add **"Share with co-parent"**: generate a one-tap summary of the week's open items as a polished share card (image or text) → drives viral growth as more household members discover the app through the shared brief.

## Known limitations
- Voice capture is routed to the manual-entry sheet (voice transcription not yet wired to STT).
- Camera "scan flyer" opens the manual sheet with source=CAMERA; OCR/AI extraction is not wired (future enhancement).
