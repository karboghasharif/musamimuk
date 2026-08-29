# Deep links & App Links (Play Store fallback)

Shared Musamimuk links should open the **app** when installed, and the **Play Store** when not.

## Supported link shapes

| Link | Opens in app |
|---|---|
| `https://HOST/contest/{id}` | Contest detail |
| `https://HOST/contest/{id}/submission/{sid}` | Contest feed (focused submission) |
| `https://HOST/contest/feed` | Contest feed |
| `https://HOST/share/{submissionId}` | Contest feed |
| `https://HOST/s/{submissionId}` | Contest feed |
| `https://HOST/open/online-designs` | Online designs |
| `https://HOST/open/my-designs` | My designs (login if needed) |
| `https://HOST/open/design/{id}` | Open saved design in editor (login if needed) |
| `https://HOST/design/{id}` | Same as `/open/design/{id}` |
| `https://HOST/open/new-design` | New design |
| `https://HOST/open/remove-background` | Remove background |
| `https://HOST/open/qr` | QR generator |
| `https://HOST/open/about` | Help & support |
| `musamimuk://contest/12` | Same as HTTPS contest detail |

`HOST` is currently `srv1813447.hstgr.cloud` (and optionally `musamimuk.app`).

## App side (already wired)

- Android App Links intent-filters in `android/app/src/main/AndroidManifest.xml`
- Custom scheme `musamimuk://` (Android + iOS)
- Flutter handler: `lib/core/deeplink/`

## Backend / website (required for “no app → Play Store”)

1. **Host Digital Asset Links** so Android trusts HTTPS opens into the app:

   Serve at:
   `https://HOST/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.musamimuk.app",
    "sha256_cert_fingerprints": [
      "UPLOAD_OR_APP_SIGNING_SHA256_FINGERPRINT"
    ]
  }
}]
```

Get the fingerprint:

```bash
keytool -list -v -keystore android/app/upload-keystore.jks -alias upload
```

If you use Play App Signing, also add the **App signing** SHA-256 from Play Console → App integrity.

2. **Landing pages** for `/open/*`, `/contest/*`, `/share/*`:

   Copy `docs/deep_link_landing.html` to those routes (or rewrite all of them to it).  
   Behaviour:
   - Tries `musamimuk://…` (opens installed app)
   - Tries Android `intent://…` with Play Store fallback
   - Finally redirects to Play Store

3. **Share URLs from API** (`share_url`) should use one of the supported paths above, e.g.:

   `https://srv1813447.hstgr.cloud/share/123`  
   or  
   `https://srv1813447.hstgr.cloud/contest/45/submission/123`

## Verify on device

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "https://srv1813447.hstgr.cloud/contest/1"
```

```bash
adb shell am start -a android.intent.action.VIEW \
  -d "musamimuk://share/1"
```
