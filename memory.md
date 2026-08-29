# Musamimuk — Project Memory

Living reference for agents and developers. Prefer this file for orientation; deep-dive docs live under `docs/`.

**Last updated:** 2026-08-15  
**App version:** `1.0.5+22` (`pubspec.yaml`)  
**Package ID:** `com.musamimuk.app`  
**API root:** `https://srv1813447.hstgr.cloud/api/v1/`

### Sister projects (same product)

| Repo | Role |
|------|------|
| `FLUTTER DEV/musamimuk` | This mobile app |
| `NODE JS/Musamimuk 3` | Laravel API (`/api/v1`) |
| `NODE JS/editor 2` | React admin portal |

Keep API contracts aligned across all three (fonts, contests/`prize_currency`, assets, wallet).

---

## 1. What this app is

**Musamimuk** is a Flutter mobile design studio:

- Create designs on a canvas (ProImageEditor)
- Browse / redesign online (public) templates
- Save personal designs as **public** or **private**
- Remove image backgrounds (on-device ML + cloud options)
- Generate QR codes
- Enter design contests (prizes with currency)
- AI Studio on Home (ChatGPT via backend): images, editable designs, chat, vision
- AI-assisted editor commands (via backend OpenAI proxy — no vendor keys in the app)
- Custom font library from admin uploads (Arabic + English)
- Wallet / Musamimuk Coins + IAP
- Online Assets picker (Unsplash + Pexels + Pixabay + Iconify, Artic, Met, Colormind, COLOURlovers, DummyImage, EmojiHub, Icon Horse, Icons8, curated Lottie, Lordicon, PHP Noise)
- Auth: email, Google, Apple, Facebook; guest accounts with upgrade prompts

Primary platforms: **Android** (Play Store) and **iOS**. Also has linux/macos/web/windows stubs.

---

## 2. Tech stack

| Area | Choice |
|------|--------|
| Framework | Flutter (SDK `^3.10.4`) |
| State | `flutter_bloc` + `equatable` |
| Networking | `dio` via singleton `ApiClient` |
| Editor | `pro_image_editor` `^13.2.0` |
| Fonts | Admin library via `FontLoader` + `arabic_font` + `google_fonts` fallbacks |
| Images | `cached_network_image`, `image_picker`, `image`, `gal`, `share_plus` |
| Auth social | `google_sign_in`, `sign_in_with_apple`, `flutter_facebook_auth` |
| Secure prefs | `flutter_secure_storage` + `shared_preferences` (`PrefUtils`) |
| Deep links | `app_links` |
| IAP | `in_app_purchase` → `POST /wallet/iap/verify` |
| BG removal | `google_mlkit_selfie_segmentation` + API repos |
| Localization | EN + AR (`lib/localization/`) |
| Design system | `lib/core/design_system/` (`AppDs`, `AppCard`, `AppAsyncBody`, …) |

---

## 3. Repository layout

```
musamimuk/
├── android/ ios/ …          # Platform projects
├── assets/                  # images/, fonts/ (Inter, Poppins, VisbyRoundCF)
├── docs/                    # Feature/API docs (see §12)
├── memory.md                # This file
├── lib/
│   ├── main.dart            # Bootstrap, session, fonts warm, MaterialApp
│   ├── routes/app_routes.dart
│   ├── localization/        # en_us + ar translations
│   ├── theme/               # ThemeHelper, ThemeBloc
│   ├── widgets/             # Shared UI (drawer, image view, sheets…)
│   ├── background_removal/  # BG-removal feature modules
│   ├── core/
│   │   ├── app_export.dart  # Barrel imports used across app
│   │   ├── network/         # ApiClient, errors, auth images
│   │   ├── session/         # SessionManager, loading, secure tokens
│   │   ├── deeplink/        # App Links + musamimuk://
│   │   ├── design_system/   # AppDs tokens + components
│   │   ├── config/          # editor_ai_config, pinterest_config (+ secrets.example)
│   │   └── utils/           # Prefs, navigator, sizes, toasts…
│   ├── data/
│   │   ├── models/          # Incl. custom_font_models, contest_*, wallet_*
│   │   ├── repositories/    # Auth, designs, media, contest, fonts, wallet…
│   │   └── services/
│   │       ├── custom_font_library.dart
│   │       ├── local_design_store.dart
│   │       ├── design_redesign_service.dart
│   │       ├── editor_ai/   # Providers, composition, text writing
│   │       └── iap/
│   ├── presentation/        # Screens (BLoC per screen; legacy naming)
│   ├── features/            # Newer feature folders (shell, editor, …)
│   └── editor_v2/           # Experimental / alternate editor bits
├── test/
└── pubspec.yaml
```

**Convention:** Most shipping UI lives under `lib/presentation/<screen>/` with `bloc/`, `models/`, `widgets/`. Prefer existing patterns over inventing new folders unless work clearly belongs in `features/`.

---

## 4. App bootstrap (`lib/main.dart`)

1. Init logger, deep links, portrait + edge-to-edge system UI  
2. `PrefUtils().init()` — load token/session **before** any API call  
3. If “remember session”: refresh profile for non-guest logged-in users  
4. If logged in: warm `CustomFontLibrary.instance.ensureLoaded()` (background)  
5. Wire `SessionManager`:
   - `guestForbiddenHandler` → guest upgrade prompt  
   - `insufficientCoinsHandler` → insufficient-coins sheet  
   - `authClearedHandler` → `syncWalletAfterAuth(forceReset: true)`  
6. `MyApp`: `Sizer` → `MultiBlocProvider` (`AddNewBloc`, `WalletBloc` + bootstrap, `ThemeBloc`) → localized `MaterialApp`  
7. Routes: `AppRoutes.initialRoute` + `AppRoutes.routes`  
8. Global loading overlay via `GlobalLoadingController`

---

## 5. Networking & auth

- **Client:** `lib/core/network/api_client.dart` — `baseUrl` ends with `/api/v1/`  
- **Bearer token** from prefs; guest 403s routed to upgrade UX  
- Authenticated network images: `musamiAuthenticatedNetworkImage` / related helpers under `core/network/`  
- Repositories (non-exhaustive):

  | Repo | Role |
  |------|------|
  | `AuthRepository` | Login, register, session refresh, social |
  | `DesignRepository` | Save / update / redesign / clone designs |
  | `AdminDesignRepository` | Public catalog (`GET designs`, visibility filter) |
  | `MediaRepository` | Typed lists (design / sticker / shape / …) |
  | `AssetRepository` / `ShapeRepository` / `CategoryRepository` | Asset library |
  | `PublicRepository` | Featured / public home content |
  | `ContestRepository` | Contests & submissions |
  | `CustomFontRepository` | `GET /fonts` + download / `FontLoader` |
  | `BackgroundRemovalRepository` | Cloud BG removal |
  | `DesignInteractionRepository` | Views / favorites / downloads |
  | `EditorAiApiService` | AI commands (backend proxy) |
  | `WalletRepository` | Coin balance, costs, packages, IAP verify |
  | `OnlineAssetRepository` | Online Assets multi-provider picker (no Pinterest) |
  | `AdvertisementRepository` | In-app ads placements |
  | `NotificationRepository` | Push / in-app notifications |

### Wallet / Musamimuk Coins

- **Server is source of truth** — never credit/debit coins locally after purchase or spend.
- Guests cannot buy/spend; store CTA upgrades via `POST /user/upgrade`.
- App-wide `WalletBloc` (`lib/presentation/wallet/`) + `CoinStoreScreen` / transactions.
- IAP via `in_app_purchase` → `POST /wallet/iap/verify` before store complete.
- HTTP 402 / `insufficient_coins` → insufficient-coins sheet → coin store.
- Costly features: AI editor/images/gemini (auth + coins). Background removal is **free** (0 coins; still requires a non-guest account).

---

## 6. Navigation & major screens

Defined in `lib/routes/app_routes.dart`. Important destinations:

| Route constant | Purpose |
|----------------|---------|
| `screen0LoginScreen` / `Register` / `ForgotPassword` | Auth |
| `guestUpgradeScreen` | Guest → full account |
| `screen1HomeScreen` | Home hub |
| `screen2NewDesignScreen` / size select | Start new canvas |
| `screen3AddNewScreen` | **Main editor** (`AddNewScreen` + ProImageEditor) |
| `screen16OnlineDesignsScreen` | Public online catalog |
| `screen18MyDesignsScreen` | User library (Public / Private tabs) |
| `screen19…` / enhanced remove BG | Background removal |
| `enhancedQrGeneratorScreen` | QR tool |
| Contest screens | Gallery, feed, winners, my submissions |
| Wallet / coin store | Balance, packages, IAP |
| `screen1SubcriptionScreen` | Premium |
| `profileScreen` / `aboutUsScreen` | Profile & help |

**Home UX (current):**

- Quick actions: New Design, Online Designs, My Designs  
- Tutorials / QR / Contest  
- **AI Studio** section  
- Bottom nav + center **+** FAB for new design  
- Premium / Settings / Help in **drawer** (`app_navigation_drawer.dart`)

---

## 7. Design editor (critical)

**Entry:** `lib/presentation/add_new_screen/add_new_screen.dart`  
**Engine:** ProImageEditor (`ProImageEditor.memory` on transparent canvas bytes)  
**State:** `AddNewBloc` (also provided at app root)

### Layer kinds (`meta['musamiLayerKind']`)

| Kind | Source | Notes |
|------|--------|--------|
| `shape` | API shapes sheet | Silhouette PNGs; tint with **`BlendMode.srcIn`** |
| `sticker` / `png` / `logo` | Asset sheets | Photos/stickers; tint often **`BlendMode.modulate`** |
| `gallery` | Device picker | Same image toolbar |
| `ai-shape` / `ai-icon` / `ai-image` / `ai-text` | Editor AI | Composition / stickers |

Helpers:

- `musamiBuildAssetWidgetLayer` — `utils/musami_asset_layer.dart`  
- `musamiMutateWidgetLayerGeometry` / `musamiResizeWidgetLayerCore` — live stretch  
- `musamiComposeImageLayerVisualCore` / `_musamiApplyImageLayerFilters` — tint, tune, border, shadow  
- Transform overlay — `widgets/musami_text_layer_transform_overlay.dart`  
  - Text + Widget layer side/corner handles  
  - Live paint: **`layer.key.currentState?.setState()`** during drag (not editor setState alone)

### Custom fonts (text style)

Admin-uploaded fonts (TTF/OTF; WOFF2 skipped on mobile) via backend:

| Piece | Path |
|-------|------|
| Models | `lib/data/models/custom_font_models.dart` |
| API + disk cache + `FontLoader` | `lib/data/repositories/custom_font_repository.dart` |
| App-wide catalog | `lib/data/services/custom_font_library.dart` |
| Picker UI | `lib/presentation/add_new_screen/widgets/musami_text_editor_arabic_fonts.dart` |

**Contracts:**

- Mobile reads **`GET /fonts`** (auth) — never `/admin/fonts/*`  
- Use `family` as Flutter `fontFamily`; download absolute `file_url`; invalidate cache on `checksum_sha256` change  
- Query: optional `language`, `updated_since`, `is_premium`, `page`/`per_page`  
- Catalog warm on login (`main.dart`); 10‑minute in-memory TTL  

**Picker UX:**

- `MusamiCustomFontSections` — **Arabic fonts** + **English fonts** (`language` `arabic`/`english`/`both`; `both` appears in both)  
- Text editor Fonts sheet: `MusamiArabicFontPickerStrip` → apply via `applyMusamiTextEditorFont` / `editor.setTextStyle`  
- Canvas text layer Fonts action: `_showGoogleFontsPicker` → same custom sections, then Google Fonts grid; apply via `applyTextLayerChanges`  
- Loc keys: `lbl_text_editor_fonts_arabic`, `lbl_text_editor_fonts_english`, `lbl_text_editor_fonts_custom`, …  
- Bundled `arabic_font` + curated Google Arabic remain as fallbacks under custom sections when RTL-preferred

### Visibility / save

- Save dialog: name + **public | private** (`design_save_form_dialog.dart`)  
- API: `visibility` on `POST design/add` / update — see `docs/BACKEND_SAVE_DESIGN_API.md`  
- **Online Designs** = public only (`AdminDesignRepository.list(visibility: 'public')` + client filter `!isPrivateDesign`)  
- **My Designs** = Public / Private segmented tabs (`Screen18MyDesignsBloc`)

### Canvas chrome / clipping

- Workspace surround: `AppDs.surfaceBase` (`0xFF252A30`)  
- Layers in package use `Clip.none`; overflow is hidden by ProImageEditor’s **crop overlay**:  
  `MainEditorStyle(background: AppDs.surfaceBase, outsideCaptureAreaLayerOpacity: 1.0)`  
  Requires `imageGeneration.cropToImageBounds: true` (package default).

### Shape color

- Image toolbar Color → `musamiImageTintArgb` meta  
- Shapes / AI silhouettes: **srcIn** + allow white tint  
- Photos: modulate; opaque white = no-op filter

### Export / redesign

- History JSON as `design_data`  
- Redesign: `GET design/redesign/{id}` → import history  
- Public clone: `POST design/clone/{id}` then edit clone (never mutate source)  
- **Import restores widget layers as bare images** (package rebuilds from
  `exportConfigs.networkUrl` / raster records) — `onImportHistoryEnd` must call
  `_restoreImportedWidgetLayerVisuals` to re-apply tint/tune/border/shadow/opacity
  from `Layer.meta` (regression: reopened designs lost shape colours)  
- Round-trip guard: `test/core/utils/design_state_history_roundtrip_test.dart`

### Editor AI

- Docs: `docs/editor_ai.md`  
- Floating AI command bar; **ChatGPT / OpenAI only** via backend proxy  
- Home **AI Studio**: images, editable designs, chat, vision (ChatGPT)  
- Config: `lib/core/config/editor_ai_config.dart`  
- No OpenAI/Gemini keys in the client (`OPENAI_API_KEY` on Laravel only)

### Online Assets

- Entry: Add panel → **Online Assets** → category bottomsheet → provider browser  
- UI: `widgets/online_assets/` (`online_assets_category_sheet`, `online_asset_browser_sheet`, `online_asset_apply`)  
- Data: `OnlineAssetRepository` + `online_asset_models.dart`  
- **Unsplash:** Flutter → `GET /online-assets/unsplash/search` (Laravel proxy; `UNSPLASH_ACCESS_KEY` in backend `.env` only). On place: `POST .../download` with `download_location`.  
- **Pexels:** Flutter → `GET /online-assets/pexels/search` (`PEXELS_API_KEY` in backend `.env` only). Empty query uses curated feed.  
- **Pixabay:** Flutter → `GET /online-assets/pixabay/search` (`PIXABAY_API_KEY` in backend `.env` only). Photos/illustrations/vectors.  
- **Iconify:** Direct public API (`https://api.iconify.design`) — **no API key**. Search + SVG on canvas via `flutter_svg`. Docs: https://iconify.design/docs/api/  
- **Curated Lottie:** Flutter → `GET /assets?type=lottie&status=published&is_active=1`; admins upload validated `.json` animations through the generic Assets UI (single or bulk). The backend `lottie` system asset type supports author/license/source metadata.  
- Other providers: Art Institute (+ `AIC-User-Agent`), Met, Colormind (HTTP cleartext allowed), COLOURlovers (CF may block → Colormind paletteImg fallback), DummyImage, EmojiHub, Icon Horse, Icons8, Lordicon (Lottie CDN + curated ids), PHP Noise  
- Apply: images → `online_pic` WidgetLayer; emojis → TextLayer; curated Lottie/Lordicon → Lottie WidgetLayer  

---

## 8. Contests & prize currency

Backend list/detail/public payloads expose **top-level** `prize_amount` + `prize_currency` (+ optional `prize_breakdown`). Winners include contest-level `prize_currency`.

| Piece | Notes |
|-------|--------|
| `ContestItem._parsePrize` | Nested `prize` map **or** flat `prize_amount`/`prize_currency` |
| `prizeDisplay` | e.g. `SAR 1000` |
| `toJson` | Persists `prize_amount` / `prize_currency` for navigation args |
| `ContestDetail` | Same flat-field fallback |
| `ContestWinner` | Maps `prize_currency` for winners UI |

Admin sets currency via portal meta allowlist (`MUSAMMIMUK_CONTEST_PRIZE_CURRENCIES`). Do not invent a nested `prize` object if the API sends flat fields.

---

## 9. Design system

- Tokens: `lib/core/design_system/app_design_tokens.dart` (`AppDs`)  
- Components: `app_components.dart` — `AppCard`, `AppSearchField`, `AppAsyncBody`, headers, buttons, skeletons  
- **`AppCard`:** when height is bounded (e.g. inside `Expanded`), body is wrapped in `Expanded` so scroll children don’t overflow  
- Accent yellow / dark surfaces — match existing screens; don’t invent a new palette for one screen  
- Localization keys in `lib/localization/en_us/` and `ar/` — add both when shipping copy

---

## 10. Deep links

Docs: `docs/DEEP_LINKS.md`

- HTTPS host(s): `srv1813447.hstgr.cloud` (+ optional `musamimuk.app`)  
- Scheme: `musamimuk://`  
- Paths: contests, share, `/open/online-designs`, `/open/my-designs`, `/open/new-design`, remove-bg, QR, about  
- Android App Links + Digital Asset Links (backend must host `assetlinks.json`)  
- Code: `lib/core/deeplink/`

---

## 11. Play Store / release notes

- Version: bump `version:` in `pubspec.yaml` (name+code) — current **`1.0.5+22`**  
- Signed AAB: `build/app/outputs/bundle/release/app-release.aab`  
- **AD_ID:** removed from manifest (`tools:node="remove"`); Play Console advertising ID declaration should be **No**  
- Listing copy: `docs/play_store_listing.md`  
- Privacy: `docs/privacy_policy.html`  
- Support (About Us): phone `+966576359762`, email `Fahadgallery26@gmail.com`

### Force update after each store release

1. Bump `pubspec.yaml` version, e.g. `1.0.6+23` (`23` = Android `versionCode`).  
2. Upload AAB to Play Store.  
3. In admin portal **Settings → App version**, set **Android minimum build** to `23` (and iOS when shipping App Store).  
4. Save — old installs call `GET /public/app-version` on splash and are blocked until they update.

| Piece | Path |
|-------|------|
| API (public) | `GET /public/app-version` |
| API (admin) | `GET/PUT /admin/settings/app-version` |
| Client check | `AppVersionRepository.evaluateGate` in splash (`ScreenTwentythreeBloc`) |
| Blocking UI | `lib/presentation/force_update/force_update_screen.dart` |
| Package info | `package_info_plus` (`buildNumber`) |

Offline / API failure: gate allows the app (does not lock users out when the server is unreachable).

---

## 12. Architecture patterns (SOPs)

1. **Screens:** `SomethingScreen.builder` creates `BlocProvider` + initial event  
2. **Imports:** prefer `core/app_export.dart` where the screen already does  
3. **API results:** typed Success/Failure sealed-style classes per repository  
4. **MediaItem:** `visibility` → `isPrivateDesign` when `visibility == 'private'`  
5. **Do not** put vendor AI keys or secrets in the Flutter app  
6. **Editor mutations:** prefer in-place layer mutate during drag; replaceLayer for committed edits / history  
7. **Verify usages** before renaming shared helpers (editor is highly interdependent)  
8. **Read whole files** before large edits in `add_new_screen.dart` (very large)  
9. **Fonts:** apply custom fonts only after `CustomFontLibrary.loadStyle` / repository `ensureLoaded` succeeds  
10. Tests under `test/` — run targeted `dart analyze` / `flutter test` when touching critical paths

---

## 13. Docs index

| File | Topic |
|------|--------|
| `docs/BACKEND_SAVE_DESIGN_API.md` | Design add/update/redesign/clone |
| `docs/DEEP_LINKS.md` | App Links + landing |
| `docs/deep_link_landing.html` | Hosted fallback page template |
| `docs/editor_ai.md` | In-editor AI commands |
| `docs/REMOVE_BACKGROUND_GUIDE.md` | BG removal |
| `docs/play_store_listing.md` | Store listing text |
| `docs/privacy_policy.html` | Privacy policy |
| `README.md` | UI/UX design guidelines (not build instructions) |
| **`memory.md` (this file)** | Project-wide memory for agents |
| Backend | `Musamimuk 3/docs/MOBILE-APP-GUIDE.md` § Custom fonts / contests |
| Admin | `editor 2/docs/FONT-LIBRARY-FRONTEND-GUIDE.md` |

---

## 14. Recent product behavior (keep in sync)

Update this section when fixing related bugs:

| Topic | Expected behavior |
|-------|-------------------|
| Public vs private | Private never in Online Designs; My Designs has Public/Private tabs |
| Shape color | Shape silhouettes recolor live via srcIn tint |
| Image stretch | Side/corner stretch updates UI live via layer GlobalKey setState |
| Canvas overflow | Content outside white paper masked with solid `surfaceBase` |
| Online Designs layout | Catalog card scrolls inside Expanded `AppCard` without bottom overflow |
| Reopened design colours | Saved tint/tune/border/shadow/opacity re-applied to widget layers after history import |
| Clipping mask | Shape frame keeps its own ratio/position; image below is cover-fitted and clipped via `ShaderMask` (never a canvas-level `dstIn`, which erases background + sibling layers) |
| My Designs delete | Overflow menu / long-press → confirm → `DELETE design/delete/{id}` |
| Text size toolbar | Size slider updates `fontScale` (package ignores `TextStyle.fontSize`) |
| Custom fonts picker | Arabic + English sections from `GET /fonts`; tap downloads + applies to text |
| Font formats | TTF/OTF loadable; WOFF2 not supported via `FontLoader` yet |
| Contest prize | Show `{prize_currency} {prize_amount}` from top-level API fields |
| Contest winners | Include / display `prize_currency` with amount |
| Wallet | Server balance only; 402 → coins sheet; guests cannot purchase |
| Force update | Splash blocks when `buildNumber < min_build` from `GET /public/app-version` |
| Canvas zoom lock | Lock disables pinch/pan/double-tap zoom; unlock restores gestures; current zoom level preserved (InteractiveViewer stays mounted) |
| Canvas Select Size | Scaffold does not resize for keyboard; panel pads above keyboard; Apply re-decodes editor image so paper size updates; max size is device×8 (≤8192), not screen size |
| AI Studio | ChatGPT via backend; Images/Designs/Chat/Vision are live; Videos coming soon; editor AI has no Gemini toggle |

---

## 15. Common commands

```bash
flutter pub get
flutter run -d <android-device-id>
dart analyze lib/
flutter test
flutter build appbundle --release   # Play AAB
```

---

## 16. Contact / support constants

- Play: `https://play.google.com/store/apps/details?id=com.musamimuk.app`  
- Help phone: `+966576359762`  
- Help email: `Fahadgallery26@gmail.com`

---

*When you change architecture, API contracts, editor invariants, or Play release constraints, update this file in the same PR/commit.*
