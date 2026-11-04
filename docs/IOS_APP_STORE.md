# iOS App Store — Bundle ID `com.musamimuk.ios.app`

Apple did not allow reusing `com.musamimuk.app` for this team. iOS ships as:

| Field | Value |
| --- | --- |
| Bundle ID | `com.musamimuk.ios.app` |
| Team | `3FZZ5UHWCA` (4 COMMUNITY INC) |
| Display name | Musamimuk |
| Android (unchanged) | `com.musamimuk.app` |

## Checklist

### Done in repo
- [x] Bundle ID `com.musamimuk.ios.app` + Team `3FZZ5UHWCA`
- [x] Firebase iOS app `1:774036147464:ios:a048720539daee71cdb0bd` + plist + `firebase_options.dart` + `firebase.json`
- [x] Entitlements: Push (`aps-environment`), Sign in with Apple, Associated Domains
- [x] App icons present; usage strings in `Info.plist`; `ITSAppUsesNonExemptEncryption=false`

### Still required (external / secrets)
1. Apple Developer: App ID registered with Push + Sign in with Apple + Associated Domains.
2. App Store Connect: create Musamimuk app with this Bundle ID; Paid Apps agreement active.
3. **Distribution certificate + App Store profile** for team `3FZZ5UHWCA` (Mac currently only has a Development identity).
4. Fill real values in `ios/Runner/SocialAuth.xcconfig` (still `REPLACE_WITH_…`):
   - Google iOS OAuth client for `com.musamimuk.ios.app`
   - Facebook App ID / client token (iOS bundle allowlist)
5. Firebase Console → Cloud Messaging → upload **APNs** key/cert for this iOS app (push).
6. RevenueCat: set `RevenueCatConfig.appleApiKey` (`appl_…`); add iOS products (StoreKit IDs — not Play `product:basePlan` form) + App Store Connect IAP.
7. Backend: `MUSAMMIMUK_IOS_IAP_SHARED_SECRET` + set `MUSAMMIMUK_IOS_STORE_URL` after listing live.
8. Host AASA: `appID` `3FZZ5UHWCA.com.musamimuk.ios.app` (see `docs/DEEP_LINKS.md`).
9. After listing: set `AppLinkConfig.iosAppStoreId`.
10. For App Store release builds, Xcode/profile should use **production** push (`aps-environment` production) — Release provisioning usually injects this.

## Build

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"
flutter build ipa --release
```

Upload via Transporter or Xcode Organizer.
