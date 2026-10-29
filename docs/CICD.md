# Musamimuk Flutter — CI/CD setup (GitHub Actions)

Repo: [karboghasharif/musamimuk](https://github.com/karboghasharif/musamimuk)

## What you get

| Workflow | When it runs | What it does |
|----------|----------------|--------------|
| **CI** (`.github/workflows/ci.yml`) | Push / PR to `main` | `flutter analyze` + `flutter test` |
| **Android Release** (`.github/workflows/android-release.yml`) | Tag `v*` or manual | Signed Play Store **AAB** artifact |

iOS TestFlight / App Store needs a macOS runner + Apple certs (phase 2 below).

---

## Step 0 — Push the app to GitHub

Your laptop was authenticated as **ikramakro**, which got **403** on this repo. Fix auth first:

1. On GitHub, open the repo while logged in as **karboghasharif**.
2. On your Mac, either:
   - Sign in to GitHub CLI as that account: `gh auth login`, or  
   - Use a [Personal Access Token](https://github.com/settings/tokens) for `karboghasharif` when Git asks for a password.
3. From the Flutter project:

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"
git remote -v   # should show karboghasharif/musamimuk.git
git push -u origin main
```

After the first successful push, open the repo → **Actions** tab. CI will appear after workflows are on `main`.

---

## Step 1 — Turn on Actions

1. Repo → **Settings** → **Actions** → **General**
2. Allow **Allow all actions and reusable workflows**
3. Workflow permissions: **Read and write** (needed if you later publish releases)

---

## Step 2 — Add Android signing secrets (for release builds)

Never commit `android/key.properties` or `*.jks` (already gitignored).

### 2a. Encode the keystore on your Mac

```bash
cd "/Users/mac/Documents/FLUTTER DEV/musamimuk"
base64 -i android/app/upload-keystore.jks | pbcopy
```

That copies a long base64 string to the clipboard.

### 2b. Create GitHub Secrets

Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret name | Value |
|-------------|--------|
| `ANDROID_KEYSTORE_BASE64` | Paste the base64 keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Same as `storePassword` in local `key.properties` |
| `ANDROID_KEY_PASSWORD` | Same as `keyPassword` |
| `ANDROID_KEY_ALIAS` | Usually `upload` |

---

## Step 3 — Verify CI

1. Push any commit to `main` (or open a PR).
2. Open **Actions** → workflow **CI**.
3. Green check = analyze + tests passed.

---

## Step 4 — Build a release AAB from CI

**Option A — version tag**

```bash
git tag v1.0.7
git push origin v1.0.7
```

**Option B — manual**

Actions → **Android Release** → **Run workflow**.

When finished, download **musamimuk-release-aab** from the run’s Artifacts, then upload to [Google Play Console](https://play.google.com/console).

---

## Recommended flow

```text
Feature branch → PR → CI (analyze/test)
       ↓ merge to main
Tag vX.Y.Z → Android Release → download AAB → Play Console
```

---

## Phase 2 (optional later)

| Goal | Tool |
|------|------|
| Auto-upload to Play internal track | [google-github-actions/upload-google-play](https://github.com/google-github-actions/upload-google-play) + Play service account JSON secret |
| Firebase App Distribution | Firebase token / service account |
| iOS TestFlight | macOS runner + App Store Connect API key secrets |
| Notify Slack/Discord | Add a step on workflow failure |

---

## Local commands (same as CI)

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build appbundle --release   # needs local key.properties + jks
```

---

## Security checklist

- [ ] `key.properties` and `*.jks` are **not** in git  
- [ ] Signing passwords live only in **GitHub Secrets**  
- [ ] Do not paste keystore passwords into Issues, PRs, or chat logs  
- [ ] Rotate Play upload key only via Play Console if ever leaked  
