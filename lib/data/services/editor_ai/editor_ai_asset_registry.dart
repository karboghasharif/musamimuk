import 'package:pro_image_editor/pro_image_editor.dart';

/// Tracks backend-generated asset IDs associated with an editor session.
class EditorAiAssetRegistry {
  EditorAiAssetRegistry._();

  static final Expando<Set<String>> _assets = Expando<Set<String>>();

  static void register(ProImageEditorState editor, String assetId) {
    final normalized = assetId.trim();
    if (normalized.isEmpty) return;
    (_assets[editor] ??= <String>{}).add(normalized);
  }

  static void registerAll(
    ProImageEditorState editor,
    Iterable<String> assetIds,
  ) {
    for (final assetId in assetIds) {
      register(editor, assetId);
    }
  }

  static Set<String> collect(ProImageEditorState editor) {
    final result = <String>{...?_assets[editor]};
    for (final layer in editor.activeLayers) {
      final assetId = layer.meta?['aiAssetId']?.toString().trim();
      if (assetId != null && assetId.isNotEmpty) result.add(assetId);
    }
    return result;
  }
}
