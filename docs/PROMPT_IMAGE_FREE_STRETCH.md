# Prompt: Image free stretch (Urdu Designer–style) for Musamimuk

Copy everything below the line into an implementation agent.

---

## Role

You are upgrading **Musamimuk** at:

`/Users/mac/Documents/FLUTTER DEV/musamimuk`

Stack: Flutter + `pro_image_editor` + existing Musami transform overlays. Arabic market — do **not** add Urdu/Nastaleeq work.

Competitor behavior (architecture reference only — do not copy Creaxe/Urdu Designer code or assets): Fabric.js images use independent **`scaleX` / `scaleY`**. Side handles stretch one axis; corners scale more uniformly. Display size = natural size × scales. Pixels **distort** when aspect changes (20×20 → 80×30 or 30×90). Export bakes the stretched look via canvas rasterization.

## Current Musamimuk behavior (read this first)

Today, widget-image resize is **frame + cover-crop**, not free stretch:

- `musamiFrameWidgetLayerCore` / `musamiResizeWidgetLayerCore` / `musamiMutateWidgetLayerGeometry` in `lib/presentation/add_new_screen/add_new_screen.dart`
- Frame stores `width` + `meta[kMusamiFrameAspectMetaKey]`; image intrinsic ratio in `meta[kMusamiImageAspectMetaKey]`
- Content uses `FittedBox(fit: BoxFit.cover)` + `ClipRect` → changing frame ratio **crops**, it does **not** stretch pixels
- Live handles: `MusamiWidgetLayerTransformOverlay` in `lib/presentation/add_new_screen/widgets/musami_text_layer_transform_overlay.dart`
- Live paint via `layer.key.currentState?.setState()` during drag; commit via `onApplyGeometry` / history

**Keep crop-frame mode as the default.** Add a second mode that matches competitor free stretch.

## Goal

On a selected image `WidgetLayer` (gallery / sticker / png / logo / ai-image — not canvas border frames, not clip-mask frames unless clearly supported):

1. User can switch **Fit mode**:
   - **Crop (default)** — current behavior (frame + cover)
   - **Stretch** — free non-uniform scale; image fills the box by distorting (`BoxFit.fill` / equivalent)
2. In Stretch mode:
   - Mid-side handles change **only width** or **only height** (like Fabric `scaleX` / `scaleY`)
   - Corner handles change both (uniform or free — prefer free stretch on all 8 handles when in Stretch mode, or corners uniform + sides free; document choice)
   - Example: start ~square → drag right edge → wide short (80×30 feel); drag top → tall thin (30×90 feel)
3. Live preview during drag (existing overlay pattern)
4. Undo/redo via `ProImageEditorState` history (`addHistory` / `replaceLayer` — same as current geometry commit)
5. Save / redesign / local draft round-trip: mode + geometry survive `design_data`
6. Export PNG shows the stretched pixels (no surprise crop)

## Non-goals

- Do not rip Urdu Designer APK assets or Fabric fork code
- Do not break clipping masks, canvas border frames (`musamiMetaIsCanvasBorderFrame`), or text overlays
- Do not replace ProImageEditor wholesale
- Do not force stretch on shapes that should remain silhouette-tint (`musamiLayerKind == shape`) unless product explicitly wants it — default stretch mode for **photo-like** layers only
- Do not put secrets in the client

## Implementation guidance

### Meta contract (prefer extending meta)

Suggested keys (names can match existing style):

| Key | Values | Meaning |
| --- | --- | --- |
| `musamiImageFitMode` | `crop` \| `stretch` | Default `crop` for backward compat |
| Keep | `kMusamiFrameAspectMetaKey` | Frame H/W |
| Keep | `kMusamiImageAspectMetaKey` | Intrinsic image H/W (unchanged by stretch) |
| Optional | `kMusamiCropAlignX/Y` | Only meaningful in `crop` |

Legacy layers with no key ⇒ `crop`.

### Geometry

- **Crop mode:** keep `musamiFrameWidgetLayerCore` (`BoxFit.cover`).
- **Stretch mode:** wrap content so the bitmap is drawn into the frame with **`BoxFit.fill`** (or `FittedBox(fit: BoxFit.fill)` / direct `Image` sized to frame). Frame width×height still driven by overlay math; image **distorts** to match.

Refactor carefully:

- Branch inside `musamiFrameWidgetLayerCore` or a sibling `musamiStretchWidgetLayerCore` based on meta
- `musamiMutateWidgetLayerGeometry` / `musamiRebuildWidgetLayerVisuals` must re-apply the correct fit after tint/tune/border/shadow
- Canvas border frames: ignore stretch mode (always rebuild path)

### Overlay / toolbar UX

1. Contextual toolbar on image layers (`editor_contextual_toolbars.dart`): toggle **Crop / Stretch** (EN+AR strings).
2. When Stretch selected, update meta + rebuild widget immediately + toast/hint once.
3. `MusamiWidgetLayerTransformOverlay`: same 8 handles; in stretch mode side-drag must be allowed to produce extreme aspects (already allowed for frames — verify fill path updates live).
4. Optional numeric W×H fields later — not required for v1.

### Persistence

- Ensure `ExportEditorConfigs` / `design_state_history.dart` widget loader restores `musamiImageFitMode` and rebuilds with fill vs cover
- Add/adjust unit tests next to existing `musami_document_controller_test.dart` / frame tests

### i18n

Add keys to **both**:

- `lib/localization/en_us/en_us_translations.dart`
- `lib/localization/ar/ar_translations.dart`

Examples: “Fit: Crop”, “Fit: Stretch”, short subtitle “Stretch changes proportions (like free transform)”.

## Files to touch (expected)

- `lib/presentation/add_new_screen/add_new_screen.dart` — frame/stretch core helpers
- `lib/presentation/add_new_screen/widgets/musami_text_layer_transform_overlay.dart` — live resize if needed
- `lib/presentation/add_new_screen/widgets/editor_contextual_toolbars.dart` — mode toggle
- `lib/core/utils/design_state_history.dart` — restore
- `lib/localization/en_us/…` + `lib/localization/ar/…`
- Tests under `test/presentation/add_new_screen/`
- Update `memory.md` §14: Image stretch row — distinguish Crop vs Stretch

Keep `add_new_screen.dart` surgical; extract new helpers to `utils/musami_image_fit.dart` if the file grows further.

## Acceptance criteria

1. New gallery image defaults to **Crop** (unchanged feel).
2. Switch to **Stretch**, drag side handle → image **visibly warps** to new aspect (not only cropped).
3. Switch back to **Crop** → content returns to cover-crop using stored image aspect (sensible reset; document if crop alignment resets).
4. Undo restores previous mode + size.
5. Save → My Designs / redesign → stretch still applied.
6. Export matches on-canvas stretch.
7. Border frames + locked layers unchanged / blocked with clear messaging.
8. `flutter analyze` clean on touched files; EN+AR strings present.

## Out of scope for this prompt

Curved text, perspective warp, AI upscale/inpaint, folders, multi-page — already covered in `docs/FEATURE_UPGRADE_PROMPT.md` / shipped work. This prompt is **only** free image stretch vs crop-frame.
