# Musamimuk feature upgrade prompt (Arabic market)

Paste this entire document into an implementation agent. Do **not** implement Urdu-specific typography, Nastaleeq packs, or Urdu phonetic input. Target users are **Arabic**. Existing Arabic fonts / RTL helpers stay as-is unless a task below explicitly touches them.

---

## Role

You are upgrading **Musamimuk**, an existing Flutter design app at:

`/Users/mac/Documents/FLUTTER DEV/musamimuk`

Version ~`1.0.7+26`. Stack: Flutter + `flutter_bloc` + `pro_image_editor` + Dio API (`https://srv1813447.hstgr.cloud/api/v1/`) + Firebase + RevenueCat/wallet.

Competitor reference (architecture ideas only — do **not** copy proprietary assets/APIs): Capacitor/Fabric “Urdu Designer / Creaxe” style **design-tool** features (curved text, path tools, offline packs, folders, multi-page, AI upscale/inpaint). Adapt them to **this** Flutter + ProImageEditor codebase.

## Non-goals

- Do not add Urdu font packs, HarfBuzz-for-Urdu, or Google Input Tools Urdu.
- Do not rewrite the app as Capacitor/WebView or replace ProImageEditor wholesale in v1.
- Do not put vendor AI keys in the Flutter client (backend proxy only — see `docs/editor_ai.md`).
- Do not break existing save/redesign/`design_data` contract (`docs/BACKEND_SAVE_DESIGN_API.md`).
- Do not damage print marketplace, contests, wallet, or auth flows.

## Existing architecture you must preserve

### Editor core

- Main editor: `lib/presentation/add_new_screen/add_new_screen.dart` (large StatefulWidget wrapping `ProImageEditor`).
- Layer helpers:
  - `lib/presentation/add_new_screen/utils/musami_asset_layer.dart`
  - `lib/presentation/add_new_screen/utils/musami_clipping_mask.dart` (shape clip masks via layer `meta`)
  - `lib/presentation/add_new_screen/utils/musami_layer_clipboard.dart`
  - `lib/presentation/add_new_screen/utils/musami_page_background.dart`
  - `lib/core/utils/design_state_history.dart` (`ExportEditorConfigs`, Lottie/SVG layer kinds, history JSON helpers)
- Layer UX: `musami_layer_*`, `editor_contextual_toolbars.dart`, `editor_align_arrange_sheet.dart`
- History mutations: prefer `ProImageEditorState.addHistory(...)` so Undo/Redo keep working (same pattern as Editor AI).

### Persistence

- Cloud: `DesignRepository.saveDesign` / redesign / clone — multipart + `design_data` = ProImageEditor history JSON.
- Local drafts: `LocalDesignStore` (`historyJson`, width/height, thumbnail) — `lib/data/services/local_design_store.dart`
- My Designs UI: `lib/presentation/my_designs_screen/` (tabs: local / public / private; **no folders yet**)

### AI already present

- In-editor: `editor_ai_command_bar.dart` + `lib/data/services/editor_ai/*` (OpenAI via backend; composition → TextLayer / WidgetLayer / PaintLayer).
- AI Studio: `lib/presentation/ai_studio/` — image, design, chat, vision; **video is “coming soon”**.
- Remove BG: `BackgroundRemovalRepository` → `POST remove-background` + MLKit selfie path in UI screens under `remove_background_screen*`.

### Assets / content

- Online assets browser: `widgets/online_assets/`
- Shapes from API: `shapes_bottom_sheet.dart` + `ShapeRepository`
- Local `assets/` is thin (~UI fonts + images/SVGs). Competitor ships huge offline borders/shapes/patterns packs — we need a **Musamimuk-owned** offline pack, not their files.

### Patterns / SOPs

- Follow existing BLoC + sealed result types in repositories.
- Use `AppDs` / existing sheets/toasts (`showAppToast`, `AppDs.*`).
- i18n: add keys to **both** `lib/localization/en_us/en_us_translations.dart` and `lib/localization/ar/ar_translations.dart`.
- Prefer extending `layer.meta` maps (`musamiLayerKind`, clip keys, border keys) over forking `pro_image_editor` unless unavoidable.
- Keep `add_new_screen.dart` changes surgical; extract new features into new files under `widgets/` or `utils/` when possible (file is already ~8k lines).

---

## Product goal

Close the **design-tool gaps** vs a Fabric-style competitor for **Arabic creatives**, while staying on Flutter + ProImageEditor:

1. Curved / path text
2. Path / warp / perspective tools (practical subset)
3. Offline decorative asset packs (borders, patterns, frames, Arabic decorative motifs — **Arabic**, not Urdu)
4. My Designs folders
5. Multi-page designs (v1 can be lightweight)
6. AI: upscale + inpaint (+ optionally wire video later)
7. Stronger vector-ish PaintLayer/path workflows inside existing layer model

Deliver in **phased PRs**; each phase must ship compilable, localized EN+AR, and not break open/save/redesign.

---

## Phase 1 — My Designs folders (lowest risk, high UX)

**Problem:** `Screen18MyDesignsScreen` is a flat playlist (cloud + `LocalDesignStore` drafts). Competitor has folder organize/move.

**Implement:**

1. Data model `DesignFolder` (id, name, createdAt, sortOrder) for:
   - Local: extend `LocalDesignStore` index (or sibling `folders.json`) + optional `folderId` on `LocalDesignDraft`.
   - Cloud: if backend lacks folders, add **client-side folder membership** in secure local prefs keyed by design id first; document required backend endpoints as a follow-up (`GET/POST /design/folders`, move design). Prefer backend if easy to add on Laravel — propose API shape in PR description.
2. UI on My Designs:
   - Folder chips / list (create, rename, delete, max ~20 folders).
   - Move design → folder; Unfiled bucket.
   - Search still works across folders.
3. Match existing BLoC style in `screen_18_my_designs_bloc.dart`.
4. EN+AR strings for all folder UX (mirror competitor semantics: name length 2–30, safe charset).

**Acceptance:** User can create folders, file local drafts into them, reopen app and membership persists. Cloud designs at least support local tagging if API not ready.

---

## Phase 2 — Offline decorative asset pack (Arabic market)

**Problem:** Competitor feels rich offline; Musamimuk leans on network APIs.

**Implement:**

1. Add asset tree, e.g. `assets/design_pack/{borders,patterns,frames,motifs}/` + `manifest.json` (id, category, path, tags, rtlFriendly).
2. Register in `pubspec.yaml`.
3. Browser UI reusing patterns from `online_assets/` / `shapes_bottom_sheet.dart` — new sheet `design_pack_browser_sheet.dart`.
4. Insert via existing helpers (`musami_asset_layer.dart` / WidgetLayer + `meta.musamiLayerKind = 'design_pack_*'`).
5. Silhouette borders should play with existing clip/tint rules in `add_new_screen.dart` / clipping mask utils.
6. Provide a **starter pack** of original or properly licensed SVG/PNG (do not rip competitor APK assets). If art is unavailable, scaffold manifest + 5–10 placeholders and document art drop-in path.

**Acceptance:** Offline, user can add border/pattern/frame to canvas; saved `design_data` restores them on redesign.

---

## Phase 3 — Curved / arc text (Arabic-capable)

**Problem:** Competitor has `curvedTextService`; Musamimuk text is straight `TextLayer` only.

**Implement inside ProImageEditor constraints:**

1. New tool/sheet from text contextual toolbar: **Curve text** (arc amount, direction, baseline radius).
2. Approach options (pick best that keeps undo + export working):
   - **Preferred:** Custom `WidgetLayer` that paints Arabic-aware curved text (use Flutter paragraph/shaper; respect RTL). Store params in `meta` (`musamiCurvedText`, radius, sweep, sourceString, style).
   - Or rasterize preview to WidgetLayer but keep editable source string in meta + “Edit curve” sheet.
3. Must round-trip through `design_data` / `ExportStateHistory` like other widget layers (`design_state_history.dart` rebuild rules).
4. Wire from `editor_contextual_toolbars.dart` / text style sheets without breaking normal text layers.

**Acceptance:** Arabic sample string curves correctly (joining not broken), undo works, save/reopen restores curve params.

---

## Phase 4 — Perspective / warp / path toolkit (MVP)

**Problem:** Competitor has warp/perspective/path edit; Musamimuk has crop/tune/clip mask but not mesh warp.

**Implement MVP (choose depth that fits PIE):**

1. **Perspective quad warp** for a selected `WidgetLayer` image: 4-handle overlay → output new image bytes → `addHistory` replacing layer (keep original URL in meta for “reset”).
2. Optional: simple **path/pen** tool creating `PaintLayer` or SVG path WidgetLayer for decorative strokes.
3. Entry points in `editor_contextual_toolbars.dart` for image layers; disable for locked layers (existing lock meta).
4. Keep performance acceptable on mid Android devices (downsample while dragging; full-res on commit).

**Acceptance:** User warps a photo, undoes, saves, reopens; no crash on lock/clip-mask layers (define clear unsupported messaging).

---

## Phase 5 — Multi-page designs (lightweight v1)

**Problem:** Competitor `pagesPanelService`; Musamimuk is single canvas size.

**Implement v1:**

1. Document model wrapper around current editor state: `MusamiDocument { pages: [{ id, width, height, historyJson, thumbnail }] }`.
2. Persist:
   - Local: extend draft format in `LocalDesignStore` (versioned JSON).
   - Cloud: if `design_data` must remain single history blob, store pages as versioned envelope JSON inside `design_data` **or** attach sidecar field — document choice; ensure old single-page designs still open.
3. UI: page strip in editor (add/duplicate/delete/reorder/switch). Switching pages swaps editor history via import/export helpers in `design_state_history.dart`.
4. Export: optional “export all pages as PDF” using existing `pdf` package.

**Acceptance:** 2+ pages survive local save/reopen; legacy drafts still load; EN+AR labels.

---

## Phase 6 — AI upscale + inpaint (and video stub cleanup)

**Problem:** Competitor AI suite includes upscale/inpaint/fill/video; Musamimuk has chat/image/design/vision + remove-bg; video is stub.

**Implement:**

1. Backend-proxied endpoints (mirror `editor_ai` security model):
   - `POST ai/editor/upscale` (image bytes → upscaled bytes / URL)
   - `POST ai/editor/inpaint` (image + mask + prompt)
2. Flutter:
   - Repository methods beside `editor_ai_api_service.dart` / new `editor_ai_image_tools_service.dart`
   - Editor entry: contextual toolbar on WidgetLayer + AI Studio tiles
   - Inpaint UI: brush mask on selected image (reuse paint patterns if possible)
   - Coin/wallet gating via existing `WalletRepository` / RevenueCat patterns if other AI tools are gated — match existing UX
3. Apply results through `addHistory` / background replace helpers already used by Editor AI.
4. Keep video tile honest (coming soon) or implement only if backend ready — do not fake it.

**Acceptance:** Upscale and inpaint work on a selected layer with undo; failures show toast; no API keys in app.

---

## Cross-cutting requirements

- **Tests:** unit tests for folder store, curved-text meta encode/decode, multipage envelope migration, AI DTO parsing (follow `test/data/services/editor_ai/`).
- **Docs:** update `docs/editor_ai.md` and add short `docs/DESIGN_TOOL_UPGRADES.md` describing meta keys and `design_data` versioning.
- **i18n:** every user-visible string EN+AR.
- **Code style:** match repo (sealed results, AppDs, no drive-by refactors of unrelated print/contest code).
- **Performance:** avoid decoding full-res images on every pointer move.
- **Accessibility:** large tap targets consistent with existing sheets.

---

## Implementation order (mandatory)

1. Phase 1 folders
2. Phase 2 offline pack scaffolding
3. Phase 3 curved text
4. Phase 4 perspective warp MVP
5. Phase 5 multipage
6. Phase 6 AI upscale/inpaint

After each phase: `flutter analyze` on touched files + manual checklist (open editor → use feature → undo → save local → reopen → cloud save if applicable).

---

## First response expected from the agent

Before coding, output:

1. Confirmed file touch list per Phase 1
2. Proposed `LocalDesignDraft` / folder JSON schema
3. Any backend blockers

Then implement Phase 1 unless told to start at a different phase.
