# Save Design API – Backend Specification

This document describes how the Flutter app saves a design from **pro_image_editor** and what the backend should provide so the app can upload and store designs.

---

## 1. What the app can send

The editor can provide two kinds of data:

### 1.1 Final image (always)

- **Format:** Raster image bytes (e.g. **JPEG** or **PNG**).
- **Content:** The fully rendered design (background + all layers: text, stickers, shapes, drawings, filters, crop, etc.) at the current canvas size.
- **How the app gets it:** When the user taps “Save” (or “Done”), the editor runs its export and calls `onImageEditingComplete(Uint8List bytes)`. By default the package gives **JPEG** bytes; PNG can be used if needed.
- **Typical size:** Depends on canvas size and quality (e.g. 200×200 to 1000×1000+ pixels). The app will send this as a file in a multipart request.

### 1.2 Optional: state history (for re-editing)

- **Format:** **JSON** (string or file).
- **Content:** Full editable state: layers (text, paint, stickers, emojis), transforms (crop/rotate/flip), filters, blur, tune adjustments, image size, history position, etc. This is the same structure used by pro_image_editor’s **export/import**.
- **How the app gets it:** Before or after saving the image, the app can call `editor.exportStateHistory(configs).then((exporter) => exporter.toMap())` (or `toJson()`). The result is a single JSON object (see structure below).
- **Use case:** If the backend stores this JSON, the app can later **reload the design** and open it again in the editor for editing (import state history). If you only need the final image (e.g. for thumbnails, sharing, print), you can ignore state history.

---

## 2. Recommended API: Save design

### 2.1 Endpoint

- **Method:** `POST`
- **Path:** e.g. `/api/designs` or `/api/user/designs/save` (or your existing route).
- **Auth:** Required (e.g. `Authorization: Bearer <token>`).
- **Content-Type:** `multipart/form-data`.

### 2.2 Request body (multipart fields)

| Part name   | Type   | Required | Description |
|------------|--------|----------|-------------|
| `image`    | File   | **Yes**  | The final design image (JPEG or PNG). |
| `title`    | String | No       | User-defined title for the design. |
| `width`    | Number | No       | Canvas width in pixels (integer). |
| `height`   | Number | No       | Canvas height in pixels (integer). |
| `state`    | File or String | No | Optional: exported state history JSON (for re-editing). |

- **image:** Binary file; filename can be e.g. `design.jpg` or `design.png`.
- **state:** If sent as file, e.g. `design_state.json`; if your backend accepts it, the app can send the same JSON as a string field instead of a file.

Example (pseudo):

```
POST /api/designs
Authorization: Bearer <token>
Content-Type: multipart/form-data; boundary=----...

------...
Content-Disposition: form-data; name="image"; filename="design.jpg"
Content-Type: image/jpeg

<binary image bytes>
------...
Content-Disposition: form-data; name="title"

My Design
------...
Content-Disposition: form-data; name="width"

400
------...
Content-Disposition: form-data; name="height"

400
------...
Content-Disposition: form-data; name="state"; filename="design_state.json"
Content-Type: application/json

{"version": "6.0.0", "history": [...], "imgSize": {"width": 400, "height": 400}, ...}
------...
```

---

## 3. Exported state history JSON (high-level)

When the app exports state via `exportStateHistory().toMap()` / `toJson()`, the structure looks like this (conceptually; keys may be minified in practice):

- **version:** String (e.g. `"6.0.0"`).
- **history:** Array of history entries. Each entry can contain:
  - **layers:** Array of layer objects (text, paint, widget/sticker, emoji).
  - **filters:** Color filter matrices (array of number arrays).
  - **tune:** Tune adjustments (brightness, contrast, etc.).
  - **blur:** Blur strength (number).
  - **transform:** Crop/rotate/flip (object with crop/rotation/flip data).
- **position:** Integer (current history index).
- **imgSize:** `{ "width": number, "height": number }` (original image size).
- **lastRenderedImgSize:** Rendered size.
- **widgetRecords:** Optional array of binary blobs (e.g. sticker images) if not inlined.
- **references:** Optional shared references for layers (minified export).

Layer types include:

- **Text:** text content, style, position, scale, rotation.
- **Paint:** strokes (path/points, color, width).
- **Widget/Sticker:** image bytes or reference, position, scale, rotation.
- **Emoji:** emoji character, position, scale.

The backend does **not** need to interpret this JSON for a simple “save image” flow. It only needs to:

- Store the image file (and optionally the JSON blob) and associate them with the user.
- Return a design ID and, if useful, a URL to the saved image (and optionally state).

---

## 4. Response format

Suggested JSON response:

```json
{
  "success": true,
  "data": {
    "id": "design_uuid_or_int_id",
    "imageUrl": "https://yourserver.com/uploads/designs/xxx.jpg",
    "thumbnailUrl": "https://yourserver.com/uploads/designs/xxx_thumb.jpg",
    "width": 400,
    "height": 400,
    "title": "My Design",
    "createdAt": "2025-03-15T12:00:00Z"
  }
}
```

- **id:** Unique design ID (for later “load my designs” or “re-open for edit”).
- **imageUrl:** Public or signed URL of the saved image.
- **thumbnailUrl:** Optional; can be generated server-side from `image`.
- **width / height:** Echo or from request (or from image metadata).
- **title:** Echo or from request.
- **createdAt:** Server timestamp.

If you support re-editing:

- Add e.g. **stateUrl** or **state** in `data` (URL to the stored state JSON or the JSON itself), so the app can later load it and call the editor’s import state history.

---

## 5. How the app uses the editor (summary)

- **Trigger save:** User taps “Save” → app calls `editorKey.currentState.doneEditing()`. The editor then:
  - Captures the current canvas (all layers, filters, crop, etc.) into a single image.
  - Calls `onImageEditingComplete(Uint8List bytes)` with that image (e.g. JPEG).
- **Optional state export:** App can call `editorKey.currentState.exportStateHistory(ExportEditorConfigs(...))` to get an `ExportStateHistory` instance, then `exporter.toMap()` or `exporter.toJson()` to get the JSON to send as `state`.
- **Upload:** App sends a multipart request with `image` (file) and optional `title`, `width`, `height`, `state` (file or string) to the save endpoint.
- **After success:** App can show a success message and e.g. pop the editor or navigate to “My designs” using the returned `id` and `imageUrl`.

---

## 6. Checklist for backend developer

- [ ] **POST** endpoint for saving design (e.g. `/api/designs`).
- [ ] **Auth:** Require valid Bearer token; associate design with user.
- [ ] **Multipart:** Accept `image` (file, required), optional `title`, `width`, `height`, `state` (file or string).
- [ ] Store image file (and optional state JSON); generate stable URLs (or paths) for the image (and state if needed).
- [ ] Return JSON with at least `id`, `imageUrl`, and optionally `thumbnailUrl`, `width`, `height`, `title`, `createdAt`, `stateUrl`/`state`.
- [ ] (Optional) List endpoint for user’s designs (returning `id`, `imageUrl`, `thumbnailUrl`, `title`, `createdAt`, etc.) so the app can show “My designs” and re-open a design by loading image + state.

Once this API is implemented, the app will use it in `onImageEditingComplete` (and optionally when exporting state) to upload the design and handle the response.
