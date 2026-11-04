# Design tool upgrades — offline Design Pack

## Pack root

Bundled offline pack lives at:

```text
assets/assets/
  borders/          # files/*.svg + thumbs/*.png + borders-manifest.json
  patterns/         # *.jpg|png + patterns.json
  shapes/           # subcategory folders of SVGs
  specialtext/      # Arabic/Islamic motifs by subcategory
  emoji/
  svg-manifest.json # shapes / emoji / specialtext / patterns indexes
  brushes/ blends/  # deferred (not registered in pubspec for v1)
```

Do **not** create `assets/design_pack/` or placeholder art. Do not copy/move this tree.

## pubspec

Registered folders (APK size–conscious; brushes/blends omitted):

- `assets/assets/svg-manifest.json`
- `assets/assets/borders/borders-manifest.json`
- `assets/assets/patterns/patterns.json`
- `assets/assets/borders/files/`
- `assets/assets/borders/thumbs/`
- `assets/assets/patterns/`
- `assets/assets/emoji/`
- Each `shapes/<sub>/` and `specialtext/<sub>/` folder (Flutter does **not** recurse; parent-only entries skip subcategory files)

## Borders JSON index

Flutter cannot list asset directories at runtime. Borders are indexed by:

`assets/assets/borders/borders-manifest.json`

Regenerate after adding/removing border SVGs:

```bash
dart run tool/generate_borders_manifest.dart
```

Shape / emoji / specialtext / patterns lists stay in `svg-manifest.json` (and `patterns/patterns.json`).

## Layer meta (save / redesign)

Inserted pack layers use `WidgetLayer` with:

| Key | Meaning |
| --- | --- |
| `musamiLayerKind` | `design_pack_border` \| `design_pack_pattern` \| `design_pack_shape` \| `design_pack_specialtext` \| `design_pack_emoji` |
| `designPackId` | Stable catalog id |
| `assetPath` | Full pubspec key, e.g. `assets/assets/borders/files/border-1.svg` |
| `category` | Enum name (`borders`, `patterns`, …) |
| `subcategory` | Optional (shapes / specialtext) |

Export id prefix: `musami-design-pack:` (not `assetPath` on `WidgetLayerExportConfigs`, so PIE does not restore SVGs as `Image.asset`).

Restore path: `musamiDesignWidgetLoader` in `design_state_history.dart` rebuilds from `assetPath` via `SvgPicture.asset` / `Image.asset`.

### Borders = canvas frame (not a sticker)

Tapping a Borders pack item places a **full-canvas frame**:
- Matching **corner** motifs on all four corners (flip/mirror)
- Matching **edge** motifs tiled on all four sides
- Pairs `border-*` ↔ `corner-*` when both assets exist; otherwise reuses the selected asset
- One `WidgetLayer` (`musamiBorderMode: canvas_frame`) so undo/delete removes the whole frame

Code: `utils/musami_design_pack_border_frame.dart` + branch in `musami_design_pack_apply.dart`.

## Code map

| Piece | Path |
| --- | --- |
| Models | `lib/data/models/design_pack_models.dart` |
| Catalog | `lib/data/services/design_pack_catalog.dart` |
| Widget / apply | `lib/presentation/add_new_screen/utils/musami_design_pack_*.dart` |
| Browser sheet | `lib/presentation/add_new_screen/widgets/design_pack/` |
| Bookmark entry | `add_new_bookmark_panel.dart` → “Design Pack” |

## Adding files

1. Drop assets under the correct folder under `assets/assets/`.
2. **No spaces in filenames** (use `Asset_110.svg`, not `Asset 110.svg`) — spaces break reliable Flutter asset bundling/loading on Android.
3. Update the matching JSON index (`svg-manifest.json`, `patterns.json`, or regenerate borders-manifest).
4. Ensure the folder is listed in `pubspec.yaml` assets (each subcategory under `shapes/` / `specialtext/`).
5. Full restart / rebuild so the asset bundle picks up new files (hot reload is not enough).

## Tests

`test/data/services/design_pack_catalog_test.dart` — path resolve, manifest parse, missing section handling, bundled load smoke test.

---

## Curved / arc text (Phase 3)

### Approach

Custom `WidgetLayer` (not a permanent raster sticker). Straight text is shaped with `TextPainter` (RTL/Arabic joining), then strip-warped along a circular arc so glyph joining stays intact.

### Meta schema

| Key | Type | Notes |
| --- | --- | --- |
| `musamiLayerKind` | `curved_text` | |
| `musamiCurvedText` | `true` | |
| `sourceString` | string | Editable text |
| `arcAmount` | double **−1…1** | Magnitude → sweep (≈0.18π…1.72π). **+** = arch (upper half), **−** = smile (lower half) |
| `clockwise` | bool | Reverse travel along the arc |
| `rtl` | bool | Auto-detected from Arabic code points on convert; toggleable |
| `textAlign` | `left`/`center`/`right`/`justify` | |
| `fontFamily`, `fontSize`, `fontWeight`, `fontStyle`, `color`, `letterSpacing` | style | |

Export id prefix: `musami-curved-text:`.

### Convert / history

1. Text toolbar → **Curve text** → sheet → Apply: replace `TextLayer` with curved `WidgetLayer` via `addHistory(layers:)`.
2. Curved layer selected → **Edit curve** / **Text** → update params via `addHistory`.
3. **Remove curve** → straight `TextLayer` via `addHistory`.
4. Restore: `musamiDesignWidgetLoader` + import path skips image frame/tint shells for curved text.

### Code map

| Piece | Path |
| --- | --- |
| Meta / params | `utils/musami_curved_text_meta.dart` |
| Painter | `utils/musami_curved_text_painter.dart` |
| Widget | `widgets/musami_curved_text_layer.dart` |
| Convert/update | `utils/musami_curved_text_apply.dart` |
| Sheet | `widgets/musami_curved_text_sheet.dart` |

### Manual checklist

- [ ] Arabic sample (e.g. بسم الله / مرحبا بكم) curves without obvious broken joining
- [ ] Undo after convert and after arc Apply
- [ ] Save local → reopen restores text + arc
- [ ] Normal TextLayer + Design Pack still work

`test/presentation/add_new_screen/musami_curved_text_meta_test.dart` — encode/decode + loader widget for Arabic sample.

---

## Perspective quad warp (Phase 4)

### Eligibility

- Raster `WidgetLayer` (MemoryImage / network / asset PNG-JPG).
- **Blocked:** locked layers, active clipping mask (release first), `curved_text`, design-pack SVG kinds (borders/shapes/emoji/specialtext). Patterns OK if raster.

### Meta

| Key | Notes |
| --- | --- |
| `musamiWarpSource` | `original` \| `warped` |
| `musamiWarpOriginalNetworkUrl` | Reset source when present |
| `musamiWarpOriginalAssetPath` | Reset source when present |
| `musamiWarpQuad` | 8 doubles tl…bl in **0–1** of source |

Gallery-only memory images: originals are kept in an **in-session** cache for **Reset original**. After app kill / reopen, Reset may toast unavailable (Undo still works via history). Network/asset layers can always Reset from URL/path.

### Caps

- Preview longest edge: **768**
- Apply longest edge: **2048**

### Code

| Piece | Path |
| --- | --- |
| Math | `utils/musami_perspective_warp.dart` |
| Meta | `utils/musami_perspective_warp_meta.dart` |
| Resolve / push | `utils/musami_perspective_warp_apply.dart` |
| UI | `widgets/musami_perspective_warp_page.dart` |

Toolbar: Image → **Perspective**. Path/pen deferred.

### Manual checklist

- [ ] Warp photo → Apply → Undo
- [ ] Network/asset Reset original
- [ ] Locked + clip-mask toasts, no crash
- [ ] Save local → reopen shows warp
- [ ] Folders / design pack / curved text still OK

`test/presentation/add_new_screen/musami_perspective_warp_test.dart`

---

## Multipage documents (Phase 5)

### Persistence (no Laravel migration)

`historyJson` / cloud `design_data` may be either:

1. **Legacy** — raw Pro Image Editor `ExportStateHistory` JSON (unchanged single-page drafts).
2. **Envelope** — versioned Musami document:

```json
{
  "musamiDocumentVersion": 1,
  "activePageId": "page_…",
  "pages": [
    {
      "id": "page_…",
      "name": "Page 1",
      "width": 1080,
      "height": 1920,
      "historyJson": "{ … PIE ExportStateHistory … }",
      "thumbnailBase64": null
    }
  ]
}
```

**Detection:** `musamiDocumentVersion` present + non-empty `pages` → envelope; else treat as classic PIE history.

**Save policy (v1):**

- Untouched single-page sessions keep writing **plain PIE** history (max compatibility).
- Once the user adds a second page **or** opens an existing envelope, savers write the **full envelope** (latch).
- Draft `width`/`height` = **active page** size.

**Loaders:** `musamiTryParseDesignImportHistory` / redesign / My Designs local open extract the **active page** PIE JSON into the editor; the in-memory `MusamiDocumentController` keeps all pages.

### Page switch

Export current via `musamiExportDesignStateHistory` → store in that page slot → `importStateHistory` (replace) for the target page so layers do not leak across pages.

Caps: **max 10 pages**. Last page cannot be deleted.

### PDF

**Deferred** for a follow-up — multipage edit + local/cloud save shipped first. Single-page PDF export unchanged.

### Code map

| Piece | Path |
| --- | --- |
| Model | `lib/data/models/musami_document.dart` |
| Controller | `lib/presentation/add_new_screen/utils/musami_document_controller.dart` |
| Strip UI | `lib/presentation/add_new_screen/widgets/musami_page_strip.dart` |
| Import unwrap | `musamiExtractPieHistoryJson` in `design_state_history.dart` |

### Manual checklist

- [ ] Add / duplicate / delete / reorder / switch pages
- [ ] 2+ pages survive local save → kill app → reopen
- [ ] Legacy single-page drafts open unchanged
- [ ] Cloud save/reopen with envelope
- [ ] Cannot delete last page (toast)
- [ ] EN + AR strip labels
- [ ] Folders / design pack / curve / warp still OK

`test/data/models/musami_document_test.dart`  
`test/presentation/add_new_screen/musami_document_controller_test.dart`

## Phase 6 — AI upscale / inpaint (layer replace)

Upscale and inpaint replace the selected image layer’s **widget bytes** while preserving transform (offset / scale / rotation) via `musamiReplaceWidgetLayerRaster` + `editor.replaceLayer` (one undo step). Meta keys such as `musamiAspect` / `musamiImageAspect` are refreshed from the result size; design-pack / curved-text / warp / multipage loaders are unchanged. Canvas border frames and curved text are not eligible.

See `docs/editor_ai.md` for endpoints, mask convention (white = edit), and coin keys `ai.openai.upscale` / `ai.openai.inpaint`.
