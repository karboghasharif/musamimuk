# Musamimuk Flutter — CI/CD setup (GitHub Actions)

Repo: [karboghasharif/musamimuk](https://github.com/karboghasharif/musamimuk)

## What you get

| Workflow | When it runs | What it does |
|----------|----------------|--------------|
| **CI** (`.github/workflows/ci.yml`) | Push / PR to `main` | `flutter analyze` (errors only) + `flutter test` |
| **Android Release** (`.github/workflows/android-release.yml`) | Tag `v*` or manual | Signed **AAB** + upload to **Google Play** |

iOS TestFlight / App Store needs a macOS runner + Apple certs (later).

---

## Direct to Play Store — checklist

Do these once, then every release is a tag (or “Run workflow”).

### 1. App must already exist in Play Console

1. Open [Google Play Console](https://play.google.com/console)
2. Create app **Musamimuk** if needed  
3. Package name must match: `com.musamimuk.app`  
4. Complete the first-time listing / privacy / content questionnaire enough that **Internal testing** accepts uploads  
5. Create an **Internal testing** track (or use the default)

### 2. Signing secrets (GitHub)

Never commit `android/key.properties` or `*.jks`.

On your Mac:

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"
base64 -i android/app/upload-keystore.jks | pbcopy
```

Repo → **Settings** → **Secrets and variables** → **Actions** → add:

| Secret | Value |
|--------|--------|
| `ANDROID_KEYSTORE_BASE64` | Paste base64 keystore |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` from local `key.properties` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |
| `ANDROID_KEY_ALIAS` | `upload` (yours is already `upload`) |

### 3. Play API service account (required for auto-upload)

1. [Google Cloud Console](https://console.cloud.google.com/) → create or pick a project  
2. Enable **Google Play Android Developer API**  
3. **IAM** → create a **Service account** → create a JSON key → download the `.json`  
4. Play Console → **Users and permissions** → **Invite user** → paste the service account email  
5. Grant **Release to production, exclude devices, and use Play App Signing** (or at least release to testing tracks)  
6. Accept the invite / wait a few minutes for access to propagate  
7. GitHub secret `PLAY_SERVICE_ACCOUNT_JSON` = **full contents** of that JSON file (one line or multi-line both work)

### 4. Ship a build

Bump version in `pubspec.yaml` when needed (`1.0.7+26` → higher `+build` each upload):

```yaml
version: 1.0.8+27
```

Commit + push `main`, then either:

**A — Tag (auto)**

```bash
git tag v1.0.8
git push origin v1.0.8
```

**B — Manual**

Actions → **Android Release** → **Run workflow** → pick track (`internal` recommended first).

The workflow will:

1. Build a signed `app-release.aab`
2. Save it as an Actions artifact  
3. Upload it to Play on the chosen track (`internal` by default)

Then open Play Console → **Testing** → **Internal testing** → review / promote to closed/open/production when ready.

---

## Recommended flow

```text
Feature → PR → CI green → merge main
Bump version in pubspec.yaml
Tag vX.Y.Z → Android Release → Play internal track
Promote in Play Console when ready
```

---

## Local build (same signing)

```bash
flutter pub get
flutter build appbundle --release   # needs local key.properties + jks
```

---

## Security checklist

- [ ] `key.properties` and `*.jks` are **not** in git  
- [ ] Signing passwords + Play JSON live only in **GitHub Secrets**  
- [ ] Do not paste keystore / service-account JSON into Issues, PRs, or chat  
- [ ] Rotate Play upload key only via Play Console if ever leaked  
