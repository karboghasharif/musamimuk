import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/config/editor_ai_config.dart';
import '../../../core/utils/app_toast.dart';
import 'build_ai_system_config.dart';
import 'editor_ai_response_utils.dart';

/// Shared OpenAI / Gemini command + image-generation surface for ProImageEditor.
abstract class EditorAiMessageBase {
  EditorAiMessageBase({required this.context});

  final BuildContext context;

  EditorAiProviderKind get provider;
  bool get isImageGenerationSupported;

  /// Returns `true` when editor history was applied.
  Future<bool> sendCommand(ProImageEditorState editor, String command);

  /// Creates a multi-layer design composition in one atomic history update.
  Future<bool> sendDesignCompositionRequest(
    ProImageEditorState editor,
    String prompt,
  );

  /// [asBackground] true → replace canvas background; false → add sticker layer.
  /// Returns `true` when the editor was updated successfully.
  Future<bool> sendImageGenerationRequest(
    ProImageEditorState editor,
    String prompt, {
    bool asBackground = false,
  });

  @protected
  String buildSystemMessage(ProImageEditorState editor) {
    final state = editor.stateManager;
    final sizesManager = editor.sizesManager;

    final history = {
      'layers': state.activeLayers.map((layer) => layer.toMap()).toList(),
      'blur': state.activeBlur,
      'transform': state.transformConfigs.isNotEmpty
          ? state.transformConfigs.toMap()
          : null,
      'filters': state.activeFilters.allMatrices,
      'tune': state.activeTuneAdjustments.map((tune) => tune.toMap()).toList(),
    };

    return buildAiSystemConfig(
      configs: editor.configs,
      imageSize: sizesManager.decodedImageSize,
      editorBodySize: sizesManager.bodySize,
      activeHistory: json.encode(history),
      safeArea: const EdgeInsets.all(24),
    );
  }

  /// Strips optional ```json fences some models still emit.
  @protected
  String sanitizeAiJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      final firstNl = text.indexOf('\n');
      if (firstNl != -1) text = text.substring(firstNl + 1);
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3).trim();
      }
    }
    return text.trim();
  }

  /// Parses and applies the AI response. Returns `true` on success.
  @protected
  Future<bool> handleAiResponse(
    ProImageEditorState editor,
    String response,
  ) async {
    if (!context.mounted) return false;
    final cleaned = sanitizeAiJson(response);
    if (cleaned.isEmpty) {
      _notifyError('Empty AI response');
      return false;
    }
    try {
      final decoded = json.decode(cleaned);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('AI response is not a JSON object');
      }
      final result = decoded;

      final blur = result.containsKey('blur')
          ? safeParseDouble(result['blur'])
          : null;

      final filters = result.containsKey('filters') && result['filters'] is List
          ? (result['filters'] as List)
                .map(
                  (matrix) => (matrix as List)
                      .map((v) => (v as num).toDouble())
                      .toList()
                      .cast<double>(),
                )
                .toList()
                .cast<List<double>>()
          : null;

      final tuneAdjustments =
          result.containsKey('tune') && result['tune'] is List
          ? (result['tune'] as List)
                .whereType<Map>()
                .map(
                  (e) => TuneAdjustmentMatrix.fromMap(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : null;

      List<Layer>? layers;
      if (result.containsKey('layers') && result['layers'] is List) {
        final rawLayers = result['layers'] as List;
        final parsed = parseAiLayers(rawLayers);
        final hadOnlyWidgetMaps =
            rawLayers.isNotEmpty &&
            rawLayers.every(
              (entry) =>
                  entry is Map &&
                  entry['type']?.toString().toLowerCase() == 'widget',
            );
        if (parsed.isEmpty && rawLayers.isNotEmpty && !hadOnlyWidgetMaps) {
          throw const FormatException('All AI layers failed to parse');
        }
        // Always merge so AI image stickers (WidgetLayers) are not wiped when
        // the model returns only new text/paint layers or omits widget JSON.
        layers = mergeAiCommandLayers(
          existing: editor.activeLayers,
          fromAi: parsed,
        );
      }

      TransformConfigs? transformConfigs;
      if (result.containsKey('transform') && result['transform'] is Map) {
        final transformMap = Map<String, dynamic>.from(
          result['transform'] as Map,
        );
        if (isUsableAiTransform(transformMap)) {
          transformConfigs = TransformConfigs.fromMap(transformMap);
        }
      }

      editor.addHistory(
        blur: blur,
        filters: filters != null
            ? [FilterState(name: 'ai', matrices: filters)]
            : null,
        tuneAdjustments: tuneAdjustments,
        layers: layers,
        transformConfigs: transformConfigs,
      );
      return true;
    } catch (_) {
      _notifyError('AI response could not be applied');
      return false;
    }
  }

  @protected
  void notifyUser(String message, {bool isError = false}) {
    if (!context.mounted) return;
    showAppToast(
      message,
      type: isError ? ToastificationType.error : ToastificationType.info,
    );
    // Also surface via SnackBar when a ScaffoldMessenger is available.
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _notifyError(String message) => notifyUser(message, isError: true);
}
