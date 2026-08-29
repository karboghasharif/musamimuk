import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/config/editor_ai_config.dart';
import '../../../core/network/authenticated_image.dart';
import '../../../core/utils/design_state_history.dart';
import '../../models/editor_ai_api_models.dart';
import 'editor_ai_api_service.dart';
import 'editor_ai_asset_registry.dart';
import 'editor_ai_composition.dart';
import 'editor_ai_composition_builder.dart';
import 'editor_ai_message_base.dart';
import 'editor_ai_response_utils.dart';

/// OpenAI-compatible editor operations routed through the Musamimuk backend.
class EditorAiOpenAiProvider extends EditorAiMessageBase {
  EditorAiOpenAiProvider({
    required super.context,
    EditorAiApiService? apiService,
  }) : _apiService = apiService ?? EditorAiApiService();

  final EditorAiApiService _apiService;

  static const String _generatedStickerDirectoryName = 'ai_stickers';
  static const int _maxGeneratedImageBytes = 20 * 1024 * 1024;

  @override
  EditorAiProviderKind get provider => EditorAiProviderKind.openAi;

  @override
  bool get isImageGenerationSupported => true;

  @override
  Future<bool> sendCommand(ProImageEditorState editor, String command) async {
    try {
      final response = await _apiService.sendOpenAiEditor(
        OpenAiEditorRequest(
          messages: [
            AiMessage(role: 'system', content: buildSystemMessage(editor)),
            AiMessage(role: 'user', content: command),
          ],
          responseFormat: const {'type': 'text'},
        ),
      );
      return handleAiResponse(editor, response.content);
    } on EditorAiApiException catch (error) {
      notifyUser(error.message, isError: true);
      return false;
    } catch (_) {
      notifyUser('AI request failed. Please try again.', isError: true);
      return false;
    }
  }

  @override
  Future<bool> sendDesignCompositionRequest(
    ProImageEditorState editor,
    String prompt,
  ) async {
    try {
      final response = await _apiService.sendOpenAiEditor(
        OpenAiEditorRequest(
          messages: [
            AiMessage(
              role: 'system',
              content: _buildCompositionSystemPrompt(editor),
            ),
            AiMessage(role: 'user', content: prompt),
          ],
          responseFormat: const {'type': 'text'},
        ),
      );
      final plan = decodeJsonMap(sanitizeAiJson(response.content));
      if (plan == null) {
        notifyUser('AI returned an invalid design plan.', isError: true);
        return false;
      }

      final composition = EditorAiComposition.fromMap(plan);
      final imageBytes = <String, Uint8List>{};
      final generatedAssets = <String, GeneratedAiAsset>{};
      for (final element in composition.elements) {
        if (element.type != EditorAiCompositionElementType.image ||
            imageBytes.containsKey(element.assetId)) {
          continue;
        }
        final generated = await _requestCompositionImage(element);
        if (generated == null) return false;
        final bytes = await _resolveAssetBytes(generated);
        if (bytes == null) return false;
        imageBytes[element.assetId!] = bytes;
        generatedAssets[element.assetId!] = generated;
        EditorAiAssetRegistry.register(editor, generated.id);
      }

      final decodedSize = editor.sizesManager.decodedImageSize;
      final bodySize = editor.sizesManager.bodySize;
      final canvasSize =
          !decodedSize.isEmpty &&
              decodedSize.width.isFinite &&
              decodedSize.height.isFinite
          ? decodedSize
          : bodySize;
      final layers = EditorAiCompositionBuilder.buildLayers(
        composition: composition,
        canvasSize: canvasSize,
        imageAssets: imageBytes,
        generatedAssets: generatedAssets,
        initialTextFontSize: editor.configs.textEditor.initFontSize,
      );
      if (layers.isEmpty) {
        notifyUser('AI design contains no editable layers.', isError: true);
        return false;
      }
      if (!context.mounted || !editor.mounted) return false;

      editor.addHistory(layers: <Layer>[...editor.activeLayers, ...layers]);
      final textLayers = layers.whereType<TextLayer>().toList(growable: false);
      editor.layerInteractionManager.selectedLayerId =
          (textLayers.isNotEmpty ? textLayers.first : layers.first).id;
      editor.setState(() {});
      return true;
    } on EditorAiApiException catch (error) {
      notifyUser(error.message, isError: true);
      return false;
    } on FormatException catch (_) {
      notifyUser('AI design plan could not be applied.', isError: true);
      return false;
    } catch (_) {
      notifyUser('Editable design could not be created.', isError: true);
      return false;
    }
  }

  @override
  Future<bool> sendImageGenerationRequest(
    ProImageEditorState editor,
    String prompt, {
    bool asBackground = false,
  }) async {
    try {
      final generationPrompt = asBackground
          ? prompt
          : _buildStickerGenerationPrompt(prompt);
      final response = await _apiService.generateOpenAiImage(
        OpenAiImageRequest(
          prompt: generationPrompt,
          background: asBackground ? 'opaque' : 'transparent',
        ),
      );
      final asset = response.assets.first;
      final imageBytes = await _resolveAssetBytes(asset);
      if (imageBytes == null || !context.mounted) return false;

      EditorAiAssetRegistry.register(editor, asset.id);
      if (asBackground) {
        await editor.updateBackgroundImage(EditorImage(byteArray: imageBytes));
        return true;
      }

      final stickerLayer = await _buildSelectableStickerLayer(
        editor: editor,
        imageBytes: imageBytes,
        asset: asset,
      );
      editor.addLayer(stickerLayer);
      editor.layerInteractionManager.selectedLayerId =
          editor.activeLayers.last.id;
      editor.setState(() {});
      return true;
    } on EditorAiApiException catch (error) {
      notifyUser(error.message, isError: true);
      return false;
    } catch (_) {
      notifyUser('Image generation failed. Please retry.', isError: true);
      return false;
    }
  }

  Future<WidgetLayer> _buildSelectableStickerLayer({
    required ProImageEditorState editor,
    required Uint8List imageBytes,
    required GeneratedAiAsset asset,
  }) async {
    final decodedSize = await _decodeImageSize(imageBytes);
    final layerWidth = decodedSize.width.clamp(1.0, 10000.0);
    final layerHeight = decodedSize.height.clamp(1.0, 10000.0);
    final durableUrl = asset.url?.trim();
    final fallbackFile = durableUrl == null || durableUrl.isEmpty
        ? await _persistGeneratedSticker(imageBytes)
        : null;
    final imageProvider = durableUrl != null && durableUrl.isNotEmpty
        ? musamiAuthenticatedNetworkImage(durableUrl)
        : MemoryImage(imageBytes);

    final canvasSize = musamiEditorCanvasSize(
      editor,
      fallback: context.mounted ? MediaQuery.sizeOf(context) : null,
    );
    final exportMeta = <String, dynamic>{
      'musamiLayerKind': 'ai-image',
      'aiGenerated': true,
      'aiAssetId': asset.id,
      if (durableUrl != null && durableUrl.isNotEmpty) 'url': durableUrl,
      if (fallbackFile != null) 'fileUrl': fallbackFile.path,
    };

    return WidgetLayer(
      width: layerWidth,
      scale: musamiInsertedImageScale(
        intrinsic: Size(layerWidth, layerHeight),
        canvas: canvasSize,
      ),
      offset: Offset.zero,
      boxConstraints: kMusamiWidgetLayerBoxConstraints,
      interaction: LayerInteraction(enableEdit: false),
      exportConfigs: WidgetLayerExportConfigs(
        id: 'musami-ai-asset:${asset.id}',
        fileUrl: fallbackFile?.path,
        meta: exportMeta,
      ),
      meta: {...exportMeta, 'musamiAspect': layerHeight / layerWidth},
      widget: SizedBox(
        width: layerWidth,
        height: layerHeight,
        child: Image(
          image: imageProvider,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  Future<GeneratedAiAsset?> _requestCompositionImage(
    EditorAiCompositionElement element,
  ) async {
    try {
      final isWide = element.width >= element.height * 1.25;
      final response = await _apiService.generateOpenAiImage(
        OpenAiImageRequest(
          prompt:
              '''
Create one isolated photographic asset for an editable design:
${element.imagePrompt}

No text, letters, numbers, logos, watermarks, borders, frames, icons, mockups,
or graphic layout. Return only the requested photographic visual.
''',
          size: isWide ? '1536x1024' : '1024x1024',
          quality: 'medium',
          background: 'opaque',
        ),
      );
      return response.assets.first;
    } on EditorAiApiException catch (error) {
      notifyUser(error.message, isError: true);
      return null;
    }
  }

  Future<Uint8List?> _resolveAssetBytes(GeneratedAiAsset asset) async {
    Uint8List? bytes;
    try {
      bytes = asset.decodeBytes();
    } on FormatException {
      bytes = null;
    }
    if (bytes == null && asset.url?.trim().isNotEmpty == true) {
      bytes = await _apiService.downloadGeneratedAsset(asset.url!.trim());
    }
    if (bytes == null || bytes.isEmpty) {
      notifyUser('Image generation returned no image.', isError: true);
      return null;
    }
    if (bytes.lengthInBytes > _maxGeneratedImageBytes) {
      notifyUser('Generated image is too large.', isError: true);
      return null;
    }
    if (!context.mounted) return null;
    await precacheImage(MemoryImage(bytes), context);
    return bytes;
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    codec.dispose();
    return size;
  }

  Future<File> _persistGeneratedSticker(Uint8List imageBytes) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final stickerDirectory = Directory(
      '${supportDirectory.path}/$_generatedStickerDirectoryName',
    );
    if (!await stickerDirectory.exists()) {
      await stickerDirectory.create(recursive: true);
    }
    final filename = 'ai_sticker_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File('${stickerDirectory.path}/$filename');
    return file.writeAsBytes(imageBytes, flush: true);
  }

  String _buildStickerGenerationPrompt(String userPrompt) {
    return '''
Create a single sticker/icon asset based on this request:
$userPrompt

Requirements:
- One centered subject only.
- Clean sticker/icon composition with a clear silhouette.
- No text, letters, watermark, frame, scene, mockup, or extra objects.
- Keep generous empty space around the subject.
- Square composition suitable for placing as a movable design-canvas sticker.
''';
  }

  String _buildCompositionSystemPrompt(ProImageEditorState editor) {
    final decodedSize = editor.sizesManager.decodedImageSize;
    return '''
You are a professional graphic designer planning a fully editable composition.
Return raw JSON only with this exact root shape:
{"elements":[...]}

Canvas size: ${decodedSize.width} x ${decodedSize.height}.
Every element uses normalized coordinates from 0 to 1:
- x and y are the element center.
- width and height are the element bounds.
- zIndex controls back-to-front order.

Supported element objects:
1. Text:
{"type":"text","text":"Your Name","x":0.2,"y":0.4,"width":0.3,
"height":0.1,"fontSize":0.06,"fontWeight":700,"align":"left",
"color":"#006F73","backgroundColor":"#00000000","zIndex":10}

2. Image:
{"type":"image","assetId":"architecture","prompt":"black and white
architectural street photograph","clip":"none","x":0.75,"y":0.5,
"width":0.5,"height":1.0,"zIndex":2}
Use the same assetId and exact prompt to reuse one photo in multiple placements.
clip is "none" or "circle".

3. Icon:
{"type":"icon","icon":"home","x":0.65,"y":0.35,"width":0.05,
"height":0.08,"color":"#008A8F","backgroundColor":"#FFFFFFFF","zIndex":20}
Supported icons: ${supportedEditorAiIcons.join(', ')}.

4. Shape:
{"type":"shape","shape":"rectangle","x":0.2,"y":0.5,"width":0.4,
"height":1.0,"color":"#FFFFFFFF","strokeWidth":0.005,"fill":true,
"zIndex":0}
Supported shapes: rectangle, circle, line.

Rules:
- Include every schema property on every element. Set inapplicable properties to null.
- Decompose the request into separate editable elements.
- Image prompts contain photographic subject matter only.
- Every text string, icon, and decorative shape is a separate element.
- Give text enough width for its longest word.
- Physical circles must not be stretched into ovals.
- Keep all bounds within 0..1 and return at most
  ${EditorAiComposition.maxElements} elements and
  ${EditorAiComposition.maxImageAssets} unique image assets.
- Return JSON only, with no markdown or explanation.
''';
  }
}
