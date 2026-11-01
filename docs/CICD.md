# Musamimuk Flutter — CI/CD setup (GitHub Actions)

Repo: [karboghasharif/musamimuk](https://github.com/karboghasharif/musamimuk)

## What you get

| Workflow | When it runs | What it does |
|----------|----------------|--------------|
| **CI** (`.github/workflows/ci.yml`) | Push / PR to `main` | `flutter analyze` (errors only) + `flutter test` |
| **Android Release** (`.github/workflows/android-release.yml`) | Tag `v`* or manual | Signed **AAB** + upload to **Google Play** |

iOS TestFlight / App Store needs a macOS runner + Apple certs (later).

---

## Direct to Play **production** — checklist

Do these once. After that: tag → CI builds AAB → uploads to **production**.

### 1. Play Console app ready for production

1. Open [Google Play Console](https://play.google.com/console)
2. App package must be: `com.musamimuk.app`
3. Finish **all** dashboard items Google marks as required for production (store listing, graphics, content rating, privacy policy, target audience, etc.)
4. If the app was never published, complete the first production release setup in Console (countries, declarations)

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
5. Grant **Admin** or at least **Release to production, exclude devices, and use Play App Signing**
6. Wait a few minutes for access to propagate
7. GitHub secret `PLAY_SERVICE_ACCOUNT_JSON` = **full contents** of that JSON file

You already have the 4 `ANDROID_*` secrets. **Production upload will not work until** `PLAY_SERVICE_ACCOUNT_JSON` **is added.**

### 4. Ship to production

Bump version in `pubspec.yaml` each upload (`+build` must increase):

```yaml
version: 1.0.8+27
```

Commit + push `main`, then:

**A — Tag (goes to production)**

```bash
git tag v1.0.8
git push origin v1.0.8
```

**B — Manual**

Actions → **Android Release** → **Run workflow** → track `production` → Run.

Workflow builds the signed AAB and uploads it to the **production** track. Google may still hold it for review before users see it.

---

## Recommended flow

```text
Feature → PR → CI green → merge main
Bump version in pubspec.yaml
Tag vX.Y.Z → Android Release → Play production
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
