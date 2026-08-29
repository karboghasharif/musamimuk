# ProImageEditor AI commands

Natural-language edits (layers / blur / filters / tune / transform), fully
editable multi-layer design composition, and optional OpenAI GPT Image sticker
and background generation.

## Security

- Vendor API keys and vendor URLs are never included in the Flutter app.
- All AI requests use the authenticated Musamimuk API client and bearer token.
- Backend endpoints are rooted at `https://srv1813447.hstgr.cloud/api/v1`.
- Prompts and generated image bodies are excluded from application logs.

## Run

```bash
flutter run
```

## In the editor

1. Open **Add New** (ProImageEditor screen).
2. Use the floating AI bar at the bottom (or move it to the top).
3. Editor AI uses **ChatGPT (OpenAI)** via the Musamimuk backend proxy
   (no Gemini toggle; no vendor keys in the app).
4. Mode menu: **Text commands**, **Generate editable design**,
   **Generate sticker**, **Replace background**.
5. Type a command or tap the info icon for examples, then Send.

## AI Studio (Home)

Home **AI Studio** tiles open ChatGPT-powered tools:

| Tile | Flow |
| --- | --- |
| Generate Images | Prompt → `POST ai/editor/openai/images` → preview → open editor |
| Generate Designs | Prompt + size → editor with composition mode auto-started |
| AI Chat | Multi-turn `POST ai/editor/openai` design assistant |
| AI Vision | Photo + question → multimodal ChatGPT chat |
| Gallery / Remove BG / Inspired | Existing screens |
| Generate Videos | Coming soon message |

Ensure `OPENAI_API_KEY` is set on the Laravel backend (never in Flutter).

Edits apply through `editor.addHistory(...)` so **Undo / Redo** still work.

## Fully editable designs

Banner, template, poster, flyer, LinkedIn, and layout prompts are routed to a
structured composition flow. The AI returns a layer manifest rather than a
finished banner PNG:

- Every text item is a native editable `TextLayer`.
- Photos are generated separately and remain individual `WidgetLayer`s.
- Repeated photo placements reuse the same generated asset and may use
  rectangular or circular clipping.
- Icons are separate stable widget layers.
- Blocks, circles, rings, curves, and dividers are separate `PaintLayer`s.

All assets are generated and validated before one history entry is committed.
If any required asset fails, the canvas is left unchanged. Generated photos
are exported as individual widget records, so reopening a saved design keeps
them separate instead of depending on a device-local flattened banner path.

Example:

> Create a professional editable LinkedIn banner with a white left panel,
> teal text placeholders, a circular black-and-white architecture photo,
> teal rings, and separate home, email, and user icons.

Use **Generate sticker** only when one flattened visual/sticker is intended.
Pixels inside a generated sticker are not individually editable.

## Example text commands

- Add a red arrow pointing to the center
- Add text Hello World in white at the top
- Increase brightness a bit
- Add a light blur
- Add a happy emoji in the top-right corner
- Flip the image horizontally

## Code map

| Piece | Path |
| --- | --- |
| Backend API service | `lib/data/services/editor_ai/editor_ai_api_service.dart` |
| Typed API models | `lib/data/models/editor_ai_api_models.dart` |
| System prompt | `lib/data/services/editor_ai/build_ai_system_config.dart` |
| Composition model | `lib/data/services/editor_ai/editor_ai_composition.dart` |
| Composition builder | `lib/data/services/editor_ai/editor_ai_composition_builder.dart` |
| Providers | `lib/data/services/editor_ai/editor_ai_*_provider.dart` |
| UI bar | `lib/presentation/add_new_screen/widgets/editor_ai_command_bar.dart` |
| Wiring | `MainEditorWidgets.bodyItems` in `add_new_screen.dart` |
