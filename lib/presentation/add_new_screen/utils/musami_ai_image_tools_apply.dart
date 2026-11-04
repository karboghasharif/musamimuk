import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../data/models/editor_ai_api_models.dart';
import '../../../data/services/editor_ai/editor_ai_api_service.dart';
import 'musami_layer_raster_utils.dart';

/// Captures PNG/JPEG bytes for the selected image layer (active page).
Future<Uint8List?> musamiCaptureLayerImageBytes(WidgetLayer layer) {
  return musamiResolveRasterBytesForBackgroundRemoval(layer.widget);
}

String musamiBytesToBase64(Uint8List bytes) => base64Encode(bytes);

/// Replaces [layer] image content with [bytes], keeping transform/scale.
Future<WidgetLayer?> musamiReplaceWidgetLayerRaster({
  required BuildContext context,
  required ProImageEditorState editor,
  required WidgetLayer layer,
  required Uint8List bytes,
  required double width,
  required double height,
  required WidgetLayer Function(
    WidgetLayer current,
    Map<String, dynamic> meta, {
    List<TuneAdjustmentItem>? tuneAdjustmentItems,
  }) rebuildVisuals,
  List<TuneAdjustmentItem>? tuneItems,
  Widget Function({
    required ImageProvider image,
    required double width,
    required double height,
  })? buildCore,
}) async {
  if (bytes.isEmpty || !context.mounted) return null;
  final provider = MemoryImage(bytes);
  await precacheImage(provider, context);
  if (!context.mounted) return null;

  final meta = Map<String, dynamic>.from(layer.meta ?? {});
  final aspect = height > 0 && width > 0 ? height / width : 1.0;
  meta['musamiAspect'] = aspect;
  meta['musamiImageAspect'] = aspect;

  final core = buildCore != null
      ? buildCore(image: provider, width: width, height: height)
      : SizedBox(
          width: width,
          height: height,
          child: Image(image: provider, fit: BoxFit.contain),
        );

  final preliminary = layer.copyWith(
    widget: core,
    width: width,
    meta: meta,
    exportConfigs: WidgetLayerExportConfigs(
      id: layer.exportConfigs.id,
      meta: meta,
    ),
  );
  final updated = rebuildVisuals(
    preliminary,
    meta,
    tuneAdjustmentItems: tuneItems,
  );

  final idx = editor.activeLayers.indexWhere((l) => l.id == layer.id);
  if (idx < 0) return null;
  // Single undo step via replaceLayer history.
  editor.replaceLayer(index: idx, layer: updated);
  editor.layerInteractionManager.selectedLayerId = updated.id;
  editor.setState(() {});
  return updated;
}

Future<EditorAiImageToolResponse> musamiRunUpscale({
  required EditorAiApiService api,
  required Uint8List imageBytes,
  required int scale,
}) {
  return api.upscaleImage(
    EditorAiUpscaleRequest(
      imageBase64: musamiBytesToBase64(imageBytes),
      scale: scale,
      quality: 'high',
    ),
  );
}

Future<EditorAiImageToolResponse> musamiRunInpaint({
  required EditorAiApiService api,
  required Uint8List imageBytes,
  required Uint8List maskBytes,
  required String prompt,
}) {
  return api.inpaintImage(
    EditorAiInpaintRequest(
      imageBase64: musamiBytesToBase64(imageBytes),
      maskBase64: musamiBytesToBase64(maskBytes),
      prompt: prompt,
      quality: 'high',
    ),
  );
}
