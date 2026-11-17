# Musamimuk Flutter App — TODO.md

> **Updated:** 2026-11-16 (post three-repo audit P0/P1 code slice)  
> **Repo:** `/Users/mac/Documents/FLUTTER DEV/musamimuk`  
> **Companions:** Laravel `Musamimuk 3`, React `editor 2` · See `/Users/mac/Documents/THREE_REPOS_AUDIT.md`

---

## 1. Project Overview

| Item | Detail |
|------|--------|
| **Purpose** | Arabic/English mobile design app: canvas editor, AI tools, contests, coin wallet, print marketplace (customer / shop / rider) |
| **Version** | `1.0.9+28` (`pubspec.yaml`) |
| **Stack** | Flutter ^3.10.4, `flutter_bloc`, Dio, ProImageEditor, Firebase, EN/AR |
| **Backend** | Laravel `/api/v1` |

---

## 2. Current Implementation Status

### Auth & account
- [x] Login / register / forgot password / guest upgrade / complete profile
- [x] Guest vs signed-in gating
- [x] Profile / change password
- [~] Social auth code present — **iOS SocialAuth.xcconfig still needs real Google/Facebook values** (ops / Apple Developer)

### Home & navigation
- [x] Home hub, bottom nav, FAB, drawer, featured designs, ads, force update

### Design editor
- [x] ProImageEditor + layers, align, undo/redo, design pack, online assets
- [x] Curved text, perspective warp, multipage, local drafts, folders
- [x] Layer Comment / Component / Timings — **disabled + Coming soon toast** (honest stubs; not marketed as live)
- [~] Further split of `add_new_screen.dart` (~8.7k LOC) — maintainability P2

### AI
- [x] Editor AI FAB + AI Studio (image, design, chat, vision, upscale, inpaint)
- [x] Remove background
- [x] AI Videos tile — **Coming soon badge** + toast (no API)
- [~] Gemini/Grok chat/vision only — by design

### Contest / wallet / print
- [x] Contests, online designs, QR, coin store, RevenueCat hooks
- [x] Print customer / shop / rider + mode switch (incl. exit to designer)
- [x] Print **change requests** create/cancel/pay + shop accept/reject UI
- [x] Repository CR contract tests in `test/data/repositories/print_repository_test.dart`
- [~] Live Stripe / FCM / Reverb against production — **Not Verified** (ops smoke)

### Platform / docs
- [x] Deep links docs + tests
- [x] Maps key — dart-define only (no hardcoded default)
- [x] Firebase Admin SDK JSON purged locally
- [x] Empty `lib/features` / `lib/editor_v2` scaffolds removed
- [x] `memory.md` version aligned to `1.0.9+28`
- [x] `docs/PUSH_AND_FCM.md` — FCM optional / in-app+Reverb fallback documented
- [x] iOS signing: Distribution cert + App Store profile + Release production entitlements + ASC id `6830824845`
- [x] `docs/IOS_DISTRIBUTION.md` + privacy manifest — ASC screenshots/privacy/listing still ops
- [~] Maps key / RevenueCat `appl_` / APNs / AASA / Social OAuth — **ops secrets**

---

## 3. Pending (product / ops — not code-blocked)

| Item | Owner |
|------|--------|
| Fill Maps + RevenueCat Apple + APNs + AASA; ASC screenshots/privacy/listing | Ops / Apple |
| Staging Stripe CR pay-delta smoke | Ops + API script |
| Device QA checklists in `DESIGN_TOOL_UPGRADES.md` | QA on device |
| Cloud design folders | Needs Laravel API first |
| AI video end-to-end | Future product |
| Path/pen tools, brushes pack registration | Future product |
| Split editor megafile / consolidate remove-bg screens | P2 engineering |

---

## 4. Security

- [x] AI vendor keys via API proxy
- [x] Stripe secrets from backend checkout payload
- [x] Admin SDK JSON purged; `*firebase-adminsdk*.json` gitignored
- [x] Maps `defaultValue` removed
- [x] `.env` / `pinterest_secrets.dart` / `ai_debug_secrets.dart` gitignored
- [~] iOS Maps / RevenueCat Apple / APNs — fill before store IAP + push

---

## 5. Testing

- [x] Existing unit/widget suite (~32+) including print repository
- [x] Print change-request repository path tests (create/accept/reject/cancel/pay)
- [ ] Widget tests for CR chat cards (optional P2)
- [ ] E2E patrol flows (optional P2)
- [x] CI: `.github/workflows/ci.yml` analyze + test

---

## 6. Production readiness

| Surface | Status |
|---------|--------|
| Android | Near-ready after API/print smoke |
| iOS | Code/signing ready; ASC metadata + Maps/RC/APNs still open — `docs/IOS_DISTRIBUTION.md` |
| Push | Optional FCM — see `docs/PUSH_AND_FCM.md` |

**Estimated completeness:** ~88% feature code; store/ops still limited by iOS secrets.

---

*Update checkboxes when ops credentials land or new features ship.*
