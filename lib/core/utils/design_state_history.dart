import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Export settings aligned with [pro_image_editor] import/export examples.
const ExportEditorConfigs musamiDesignExportConfigs = ExportEditorConfigs(
  historySpan: ExportHistorySpan.current,
  enableMinify: true,
  maxDecimalPlaces: 3,
);

/// Import settings for redesign — replaces editor history and rescales layers.
ImportEditorConfigs musamiDesignImportConfigs() {
  return ImportEditorConfigs(
    mergeMode: ImportEditorMergeMode.replace,
    recalculateSizeAndPosition: true,
    enableInitialEmptyState: true,
    widgetLoader: musamiDesignWidgetLoader,
  );
}

/// Restores custom widget layers referenced by [WidgetLayerExportConfigs.id].
///
/// Network/asset layers are restored automatically via [WidgetLayerExportConfigs]
/// (`networkUrl`, `assetPath`, `fileUrl`). Layers without export configs are
/// restored from exported `widgetRecords` (raster snapshots).
Widget musamiDesignWidgetLoader(
  String id, {
  Map<String, dynamic>? meta,
}) {
  final url = meta?['fileUrl']?.toString() ??
      meta?['file_url']?.toString() ??
      meta?['url']?.toString() ??
      meta?['networkUrl']?.toString() ??
      '';
  if (url.trim().isNotEmpty) {
    return Image(
      image: NetworkImage(url.trim()),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
    );
  }

  if (id.startsWith('musami-sticker:')) {
    final parts = id.split(':');
    if (parts.length >= 3) {
      return _MusamiStickerPlaceholder(
        type: parts[1],
        index: int.tryParse(parts[2]) ?? 0,
      );
    }
  }

  return Container(
    width: 100,
    height: 100,
    color: Colors.grey.shade300,
    alignment: Alignment.center,
    child: const Icon(Icons.widgets_outlined),
  );
}

/// Parses Pro Image Editor history JSON for [StateHistoryConfigs.initStateHistory].
ImportStateHistory? musamiTryParseDesignImportHistory(String? rawJson) {
  final raw = rawJson?.trim();
  if (raw == null || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map && decoded is! List) return null;
    return ImportStateHistory.fromJson(raw, configs: musamiDesignImportConfigs());
  } catch (_) {
    return null;
  }
}

/// Exports the current editor state as JSON for `design_data` / redesign.
Future<String?> musamiExportDesignStateHistory(ProImageEditorState editor) async {
  try {
    final history = await editor.exportStateHistory(
      configs: musamiDesignExportConfigs,
    );
    return history.toJson();
  } catch (_) {
    return null;
  }
}

/// Stable export id for built-in sticker layers (see sticker picker).
String musamiStickerExportId(String type, int index) =>
    'musami-sticker:$type:$index';

/// Minimal sticker placeholder used when restoring sticker layers by id.
class _MusamiStickerPlaceholder extends StatelessWidget {
  const _MusamiStickerPlaceholder({
    required this.type,
    required this.index,
  });

  final String type;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.emoji_emotions_outlined,
        size: 48,
        color: Colors.primaries[index % Colors.primaries.length],
      ),
    );
  }
}
