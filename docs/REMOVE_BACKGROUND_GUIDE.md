# How to Remove Background from Images (Free Only)

The app uses **only free** background-removal options: no paid API keys required.

---

## 1. What the app uses (free services)

### Services (in `lib/core/services/`)

| File | Role |
|------|------|
| **background_removal_service.dart** | Main entry: tries **Hugging Face** first, then **local processing**. No Remove.bg in the default flow. |
| **hugging_face_service.dart** | [Hugging Face Inference API](https://huggingface.co/inference-api) – **free tier** (free account + token at huggingface.co). Model: `microsoft/U-2-Net`. |
| **remove_bg_service.dart** | Not used in the default flow (paid API). Left in the project in case you want to add it later with your own key. |

**Flow in `BackgroundRemovalService.removeBackground()`:**

1. **Hugging Face API** – free tier; good quality. You need a **free** Hugging Face account and an [access token](https://huggingface.co/settings/tokens). Set it in `hugging_face_service.dart` (or via env/config).
2. **Local processing** – free, no key, works offline. Removes **white**, **very light**, and **green-screen**-style backgrounds. Best for simple backgrounds.
3. If both fail or are skipped, the **original image** is returned.

### Screens

- **Home → “Remove Background”** → `Screen19RemoveBackgroundScreen` (screen_19).
- **Enhanced flow** → `EnhancedRemoveBackgroundScreen` (pick image → remove background → preview/save).

So **to remove background:** user can go **Home → Remove Background**, pick an image, and the app runs `BackgroundRemovalService.removeBackground(imageBytes, onProgress: ...)` and shows the result.

---

## 2. How to use it in your app

### Option A: From Home (already wired)

- User taps **“Remove Background”** on the home screen.
- App opens the remove-background screen; user picks an image (camera/gallery).
- App calls `BackgroundRemovalService.removeBackground(...)` and shows the result (and can save or share).

### Option B: From inside the image editor (add_new_screen)

If you want “Add image from gallery → remove background → add to canvas”:

1. When the user picks an image from gallery (e.g. in the “Add new” overlay), get the image bytes.
2. Call:
   ```dart
   final removed = await BackgroundRemovalService.removeBackground(
     imageBytes,
     onProgress: (p) => /* update progress UI */,
   );
   ```
3. If `removed != null`, add `removed` as a new layer (e.g. sticker/image layer) in the editor instead of the original image.

So the “remove background” step is: **get bytes → `BackgroundRemovalService.removeBackground(bytes)` → use returned bytes (PNG with transparency) as the image to add**.

### Option C: From “Add new” overlay (Gallery)

- In the grid item that opens gallery, after the user picks a photo:
  - Optionally show a dialog: “Remove background?” Yes / No.
  - If Yes: call `BackgroundRemovalService.removeBackground(pickedImageBytes)` and use the result as the image to add to the canvas.
  - If No: use the original bytes.

---

## 3. Free options in use

| Approach | Cost | Notes |
|----------|------|------|
| **Hugging Face Inference API** | Free tier | Free account + token. Rate limits apply. Good quality. |
| **Local processing** | Free | No key, offline. White / light / green-screen removal. |

Remove.bg is **not** used in the default flow (it’s paid after a small free tier). The app runs **Hugging Face first**, then **local processing**, then returns the original image if both fail.

---

## 4. Getting a free Hugging Face token

1. Sign up at [huggingface.co](https://huggingface.co/join) (free).
2. Go to [Settings → Access Tokens](https://huggingface.co/settings/tokens).
3. Create a token (read or write).
4. Put it in `lib/core/services/hugging_face_service.dart` as `_apiKey`, or better: load from environment / `--dart-define` so you don’t commit it.

The free Inference API has rate limits; if you hit them, the app falls back to **local processing** (white/light/green removal).

## 5. Recommendations

- **Keep Hugging Face first** for best free quality; use **local processing** when offline or when HF is rate-limited.
- **Local processing** works best for photos on **white**, **light gray**, or **green-screen** backgrounds. For complex backgrounds, HF gives better results.
- To avoid committing the HF token, use `--dart-define=HF_TOKEN=your_token` and read it in code, or proxy through your own backend that holds the token.

---

## 6. Summary

- **Free only:** The app uses **Hugging Face** (free tier) and **local** white/light/green removal. No paid APIs in the default flow.
- **To remove background:** use **Home → Remove Background**, or call **`BackgroundRemovalService.removeBackground(imageBytes, onProgress: ...)`** from anywhere you have image bytes.
- **Hugging Face:** Create a free account and token at huggingface.co; set the token in `HuggingFaceService` (or via env).
- **Local fallback:** Works offline for white, very light, and green-screen backgrounds.
