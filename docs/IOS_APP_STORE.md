# iOS App Store — Bundle ID `com.musamimuk.ios.app`

| Field | Value |
| --- | --- |
| Bundle ID | `com.musamimuk.ios.app` |
| Team | `3FZZ5UHWCA` (4 COMMUNITY INC) |
| ASC app id | `6830824845` |
| Display name | Musamimuk |
| Android (unchanged) | `com.musamimuk.app` |

**Full production runbook:** [`docs/IOS_DISTRIBUTION.md`](IOS_DISTRIBUTION.md)  
**ASC:** https://appstoreconnect.apple.com/apps/6830824845/distribution

## Done in repo (Mac)

- [x] Bundle ID + Team + Firebase iOS app + `GoogleService-Info.plist`
- [x] Usage strings, icons, `ITSAppUsesNonExemptEncryption=false`
- [x] Sign in with Apple + Associated Domains
- [x] Apple **Distribution** identity + **Musamimuk App Store** profile installed
- [x] Release → Manual signing + `RunnerRelease.entitlements` (`aps-environment` = production)
- [x] `ExportOptions.plist` → `app-store-connect`
- [x] `AppLinkConfig.iosAppStoreId = 6830824845`
- [x] `PrivacyInfo.xcprivacy` in Runner resources
- [x] Empty Google/Facebook placeholders (safe for review; email + Apple only)

## Still required (secrets / ASC — you)

1. **Maps** — `GOOGLE_MAPS_API_KEY` in `ios/Runner/SocialAuth.xcconfig` (iOS-restricted key).
2. **RevenueCat** — `RevenueCatConfig.appleApiKey` (`appl_…`) + ASC IAP products if selling coins/Pro.
3. **APNs** → Firebase Cloud Messaging (push optional for v1).
4. **Backend** — `MUSAMMIMUK_IOS_IAP_SHARED_SECRET`; after live: `MUSAMMIMUK_IOS_STORE_URL`.
5. **AASA** on host — `3FZZ5UHWCA.com.musamimuk.ios.app` (`docs/DEEP_LINKS.md`).
6. **ASC product page** — screenshots, privacy, listing copy, review demo account (see `IOS_DISTRIBUTION.md` §B).

Optional later: Google / Facebook OAuth clients + URL schemes.

## Build & upload

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Upload with Transporter or Xcode Organizer → select build on version **1.0** → **Add for Review**.
