# iOS distribution — go to production

**App Store Connect:** [Musamimuk](https://appstoreconnect.apple.com/apps/6830824845/distribution)  
**Bundle ID:** `com.musamimuk.ios.app` · **Team:** `3FZZ5UHWCA` · **ASC app id:** `6830824845`

Your ASC version **1.0** is *Prepare for Submission*. Complete **A → B → C** below in order.

---

## A. Repo / Mac (code & signing) — do first

### Already in place
- [x] Bundle ID + team + Firebase iOS app
- [x] App icons, usage strings, `ITSAppUsesNonExemptEncryption=false`
- [x] Sign in with Apple + Associated Domains entitlements
- [x] Apple **Distribution** cert on this Mac (`4 COMMUNITY INC`)
- [x] App Store provisioning profile `Musamimuk App Store`
- [x] `ExportOptions.plist` → `app-store-connect` + manual profile
- [x] Release uses `RunnerRelease.entitlements` (`aps-environment` = **production**)
- [x] `AppLinkConfig.iosAppStoreId = 6830824845`
- [x] App Privacy Manifest `ios/Runner/PrivacyInfo.xcprivacy`

### You must fill (secrets — cannot invent)

| # | Item | Where | Notes |
|---|------|--------|------|
| 1 | **Google Maps iOS key** | `ios/Runner/SocialAuth.xcconfig` → `GOOGLE_MAPS_API_KEY=` | Restrict key to iOS + bundle `com.musamimuk.ios.app`. Empty = Maps/Places KYC broken. |
| 2 | **Google Sign-In** (optional for v1) | Same file + add reversed client URL scheme in `Info.plist` | Leave empty to ship with email + Apple only. |
| 3 | **Facebook** (optional for v1) | Same file | Leave empty if not shipping Facebook login in 1.0. |
| 4 | **RevenueCat Apple key** | `lib/core/config/revenue_cat_config.dart` → `appleApiKey = 'appl_…'` | Without this, **release** IAP/Pro on iOS is off. Create iOS products in ASC + RC. |
| 5 | **APNs key → Firebase** | Firebase Console → Project settings → Cloud Messaging | Needed for push; app works without push. |
| 6 | **Backend IAP secret** | API `.env` `MUSAMMIMUK_IOS_IAP_SHARED_SECRET` | App Store Connect → Users and Access → Shared Secret |
| 7 | **AASA on host** | `https://HOST/.well-known/apple-app-site-association` | `appID`: `3FZZ5UHWCA.com.musamimuk.ios.app` — see `docs/DEEP_LINKS.md` |

**Recommended v1 scope:** ship **email + Sign in with Apple**; defer Google/Facebook OAuth until clients exist. Still set Maps + RevenueCat if you sell coins/Pro.

### Build & upload IPA

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"

# Optional: Maps for this build only
# export maps via SocialAuth.xcconfig before archive

flutter pub get
flutter build ipa --release \
  --export-options-plist=ios/ExportOptions.plist
```

Upload:
- **Transporter** app, or  
- Xcode → Organizer → Distribute App → App Store Connect  

Then in ASC → version 1.0 → **Build** → select the uploaded build.

---

## B. App Store Connect product page (your current screen)

You are on **Product Page Information → Header and Search Results** (empty). For first submission prioritize the classic screenshots tab.

### 1. App Previews and Screenshots (required)
Open tab **App Previews and Screenshots** (next to Header and Search Results).

Upload for at least (app is **universal** — `TARGETED_DEVICE_FAMILY = 1,2`):
- **iPhone 6.7"** (or size ASC marks required) — **3–10** screenshots  
- **iPhone 6.5"** if ASC still asks  
- **iPad 13"** (required for iPhone+iPad binaries)

Suggested shots: Home / AI Studio, Editor canvas, My Designs, Print shops, Wallet/coins.

**Header / Search Results** assets (new ASC marketing) can wait for a later update if not blocking “Add for Review”.

### 2. App Information (sidebar → General)
- [ ] Name: Musamimuk  
- [ ] Subtitle (30 chars)  
- [ ] Category: Graphics & Design (primary); Photo & Video optional  
- [ ] Privacy Policy URL (HTTPS, live)  
- [ ] Copyright  

### 3. App Privacy (sidebar → App Store)
Complete nutrition labels to match `PrivacyInfo.xcprivacy` + real behavior:
- Account (email, name) — App Functionality  
- Photos — App Functionality (designs)  
- Precise Location — App Functionality (print shop/rider)  
- Device ID / Purchases if FCM / IAP enabled  
- **No tracking** unless you add ATT + ad SDKs  

### 4. Age rating / Content rights
Complete questionnaire (typically 4+ / 12+ depending on UGC). Declare user-generated designs if needed.

### 5. Version 1.0 listing copy
- [ ] Promotional text (optional)  
- [ ] Description  
- [ ] Keywords  
- [ ] Support URL  
- [ ] Marketing URL (optional)  
- [ ] What’s New  

### 6. App Review Information
- [ ] Demo account (email/password) that can open editor + one print flow  
- [ ] Contact phone/email  
- [ ] Notes: “Sign in with Apple available; Google/Facebook may be disabled in 1.0”

### 7. Pricing & Availability
- [ ] Price: Free (+ IAP if RevenueCat products attached)  
- [ ] Territories  

### 8. Agreements
- [ ] Paid Apps Agreement + banking/tax if you sell IAP  

---

## C. Submit

1. Build selected on version 1.0  
2. All required metadata green  
3. **Add for Review** → Submit  

---

## Quick status (this Mac)

| Check | Status |
|-------|--------|
| Distribution certificate | Present |
| App Store profile | Present (`Musamimuk App Store`) |
| ASC app created | Yes (`6830824845`) |
| Screenshots | **Missing** (your screenshot) |
| Privacy / listing copy | Confirm in ASC |
| SocialAuth Google/Facebook | Empty (OK if deferred) |
| Maps key in xcconfig | **Empty — set before archive if print KYC maps needed** |
| RevenueCat `appl_` key | **Empty — set before IAP** |
| APNs in Firebase | Confirm |
| IPA built locally | **Ready:** `build/ios/ipa/musamimuk.ipa` (1.0.9+28) — upload via Transporter |
| IPA selected on ASC 1.0 | After upload + processing |

---

## After approval

1. Set API `MUSAMMIMUK_IOS_STORE_URL=https://apps.apple.com/app/id6830824845`  
2. Confirm AASA live  
3. Optional: enable FCM with APNs (`docs/PUSH_AND_FCM.md`)  
