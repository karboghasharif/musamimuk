# Image transformation metadata contract

Living reference for photo-like `WidgetLayer` transform persistence in Musamimuk
(Pro Image Editor 13.3.1 + Musami overlays).

**Do not silently migrate legacy documents.** Missing keys keep established defaults.

## Geometry (PIE layer fields)

| Field | Purpose | Persistence |
| --- | --- | --- |
| `width` | Frame width in layer units | PIE history JSON |
| `scale` | Uniform layer scale | PIE history JSON |
| `offset` | Centre position (body-centred) | PIE history JSON |
| `rotation` | Radians | PIE history JSON |
| `flipX` / `flipY` | Mirrors | PIE history JSON |
| `boxConstraints` | Min/max layout bounds | PIE history JSON (sanitized finite max) |

Painted frame size ≈ `width × scale` by `width × aspect × scale`.

## `Layer.meta` keys

| Key | Purpose | Default if missing | Who writes it |
| --- | --- | --- | --- |
| `musamiLayerKind` | Layer taxonomy (`gallery`, `sticker`, `logo`, `png`, `ai-image`, …) | (empty → photo-like allowed) | All insert paths |
| `musamiAspect` | **Frame** height/width | `1.0` when read via helpers | Insert, resize, replace |
| `musamiImageAspect` | **Image** height/width (intrinsic) | Falls back to frame aspect | Insert, replace, crop |
| `musamiImageFitMode` | `crop` \| `stretch` fill | **`crop`** (legacy) | New photo inserts → `stretch`; Fit toolbar |
| `musamiMaintainAspectRatio` | Proportional resize lock | **`false`** (free) | New inserts `false`; Aspect toolbar |
| `musamiCropAlignX` / `Y` | Cover crop alignment (−1…1) | `0` (centre) | Crop pan UI (not stripped by `musamiIsCropMetaKey`) |
| `musamiLayerLocked` | App lock (blocks transform) | unlocked | Floating lock / menu |
| `musamiLayerHidden` | Hide without delete | visible | Layers sheet |
| `musamiOpacity` | 0…1 | `1` | Opacity sheet |
| `musamiClippingMask` + clip URL/kind/aspect keys | Shape clip over content | inactive | Clipping mask tools |
| Tint / border / shadow / tune keys | Visual chrome | none | Contextual tools |

Selection UI accent: brand yellow (`kMusamiImageSelectionColor` / `ColorScheme.primary`). OverlayPortal chrome is clipped under the editor app bar and above bottom scaffold bars so handles never cover chrome.

Fit mode and aspect lock are **independent**. Unlocking aspect must not rewrite fit mode.

## Layer types that support Crop/Stretch + aspect lock

Supported (photo-like): `gallery`, `sticker`, `logo`, `png`, `ai-image`, most other non-listed kinds.

**Not supported** (`musamiLayerSupportsImageFitMode` → false):

- Curved text
- Canvas border frames
- `shape`, `ai-shape`, `ai-icon`
- `lottie`, `online_asset_lottie`
- `online_asset_svg`
- `design_pack_shape`, `design_pack_border`

Text / paint layers use PIE / text overlays, not this fit system.

## Insertion pathways

| Path | Helper / site | Fit defaults |
| --- | --- | --- |
| Gallery pick | `musamiPhotoInsertMeta(layerKind: 'gallery')` | stretch + free |
| Sticker sheet | `musamiPhotoInsertMeta(layerKind: 'sticker')` | stretch + free |
| API logo/png | `musami_asset_layer.dart` (photo-like only) | stretch + free |
| AI image | OpenAI provider / composition builder | stretch + free |
| Design pack shapes/borders | design pack apply | no fit keys (excluded) |
| Online Lottie/SVG | online_asset_apply | no stretch defaults (excluded) |
| Legacy import | no fit key | **crop** |

## Serialization

1. Live edits update **`Layer.meta`**.
2. `musamiRebuildWidgetLayerVisuals` also copies meta into **`exportConfigs.meta`** so `widgetLoader` and redesign stay aligned.
3. Save uses `musamiExportDesignStateHistory` → PIE JSON (or multipage envelope via `MusamiDocumentController.serializeForSave`).
4. Open uses `musamiTryParseDesignImportHistory` → `importStateHistory`.
5. `_restoreImportedWidgetLayerVisuals` re-applies frame + `musamiImageFitBoxFit(meta)` from restored meta.

## Restore rules

- Missing `musamiImageFitMode` → crop (`BoxFit.cover`).
- Missing `musamiMaintainAspectRatio` → free resize (`false`).
- Present stretch/crop/lock values → restored as saved (no auto-migration).
- Multipage: each page stores its own PIE history; switch captures active page then imports target.

## Duplicate / Replace

- **Duplicate**: `musamiCloneLayer` deep-copies `meta` and `exportConfigs.meta` onto a new layer id; transforms (offset/rotation/scale/flip/width) are copied by value.
- **Replace**: `musamiBuildReplaceImageMeta` keeps existing fit/lock/clip/lock/opacity/chrome; updates image aspect + kind from pick; keeps frame aspect/geometry.

## Ephemeral keys (not part of the live transform contract)

Keys matching `musamiCrop*` **except** `musamiCropAlignX` / `musamiCropAlignY` (e.g. `musamiCropRevision`) are treated as ephemeral by `musamiIsCropMetaKey` and are stripped on destructive pixel replace / crop-bytes apply.
