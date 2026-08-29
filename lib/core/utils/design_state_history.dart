import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../network/authenticated_image.dart';

/// Layer kind for animated (Lottie JSON) online assets, e.g. Lordicon icons.
///
/// Needed so imported designs rebuild them with a Lottie player instead of an
/// [Image], which cannot decode the JSON source.
const String kMusamiLottieLayerKind = 'online_asset_lottie';

/// Layer kind for SVG icons (Iconify). Restored via [SvgPicture.network].
const String kMusamiSvgLayerKind = 'online_asset_svg';

/// Large but finite max size for layer [BoxConstraints].
///
/// Unbounded `maxWidth`/`maxHeight` (`double.infinity`) cannot be JSON-encoded
/// by [ExportStateHistory.toJson] (pro_image_editor roundSmart keeps Infinity).
const double kMusamiLayerConstraintMax = 100000;

/// Default min/max constraints for gallery / sticker [WidgetLayer]s.
const BoxConstraints kMusamiWidgetLayerBoxConstraints = BoxConstraints(
  minWidth: 48,
  minHeight: 48,
  maxWidth: kMusamiLayerConstraintMax,
  maxHeight: kMusamiLayerConstraintMax,
);

/// Fallback scale when canvas size is unknown (legacy 20% of intrinsic size).
const double kMusamiAssetLayerDefaultScale = 0.2;

/// Newly inserted images fit inside this fraction of the canvas (contain).
const double kMusamiInsertedImageCanvasFraction = 1 / 3;

bool _musamiSizeUsable(Size size) {
  return !size.isEmpty &&
      size != Size.infinite &&
      size.width.isFinite &&
      size.height.isFinite &&
      size.width > 0 &&
      size.height > 0;
}

/// Canvas size in layer coordinates (rendered paper, then editor body).
Size musamiEditorCanvasSize(ProImageEditorState? editor, {Size? fallback}) {
  final rendered = editor?.sizesManager.decodedImageSize;
  if (rendered != null && _musamiSizeUsable(rendered)) return rendered;

  final body = editor?.sizesManager.bodySize;
  if (body != null && _musamiSizeUsable(body)) return body;

  return fallback ?? const Size(400, 800);
}

/// Scale so [intrinsic] fits inside [fraction] of [canvas], keeping aspect.
double musamiInsertedImageScale({
  required Size intrinsic,
  required Size canvas,
  double fraction = kMusamiInsertedImageCanvasFraction,
}) {
  final iw = intrinsic.width <= 0 ? 1.0 : intrinsic.width;
  final ih = intrinsic.height <= 0 ? 1.0 : intrinsic.height;
  final cw = !canvas.width.isFinite || canvas.width <= 0 ? 1.0 : canvas.width;
  final ch = !canvas.height.isFinite || canvas.height <= 0 ? 1.0 : canvas.height;
  final scale = math.min((cw * fraction) / iw, (ch * fraction) / ih);
  if (!scale.isFinite || scale <= 0) return kMusamiAssetLayerDefaultScale;
  return scale;
}

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
Widget musamiDesignWidgetLoader(String id, {Map<String, dynamic>? meta}) {
  if (id.startsWith('musami-ai-icon:')) {
    final name = meta?['icon']?.toString() ?? id.split(':').last;
    final color = Color((meta?['color'] as num?)?.toInt() ?? 0xFF006F73);
    final backgroundColor = Color(
      (meta?['backgroundColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
    return buildEditorAiIconWidget(
      name: name,
      color: color,
      backgroundColor: backgroundColor,
      width: 100,
      height: 100,
    );
  }

  final url =
      meta?['fileUrl']?.toString() ??
      meta?['file_url']?.toString() ??
      meta?['url']?.toString() ??
      meta?['networkUrl']?.toString() ??
      '';
  if (meta?['musamiLayerKind']?.toString() == kMusamiLottieLayerKind &&
      url.trim().isNotEmpty) {
    return Lottie.network(
      url.trim(),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
    );
  }
  if (meta?['musamiLayerKind']?.toString() == kMusamiSvgLayerKind &&
      url.trim().isNotEmpty) {
    return SvgPicture.network(
      url.trim(),
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
  if (url.trim().isNotEmpty) {
    return Image(
      image: musamiAuthenticatedNetworkImage(url.trim()),
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
    );
  }

  if (id.startsWith('musami-ai-asset:')) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
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
    return ImportStateHistory.fromJson(
      raw,
      configs: musamiDesignImportConfigs(),
    );
  } catch (_) {
    return null;
  }
}

/// Exports the current editor state as JSON for `design_data` / redesign.
Future<String?> musamiExportDesignStateHistory(
  ProImageEditorState editor,
) async {
  try {
    _sanitizeEditorLayersForExport(editor);
    final history = await editor.exportStateHistory(
      configs: musamiDesignExportConfigs,
    );
    final map = await history.toMap();
    return jsonEncode(map);
  } catch (_) {
    return null;
  }
}

/// Replaces infinite layer constraints so export history can be JSON-encoded.
void _sanitizeEditorLayersForExport(ProImageEditorState editor) {
  for (final layer in editor.activeLayers) {
    final c = layer.boxConstraints;
    if (c == null) continue;
    if (c.maxWidth.isFinite && c.maxHeight.isFinite) continue;
    layer.boxConstraints = BoxConstraints(
      minWidth: c.minWidth.isFinite ? c.minWidth : 0,
      minHeight: c.minHeight.isFinite ? c.minHeight : 0,
      maxWidth: c.maxWidth.isFinite ? c.maxWidth : kMusamiLayerConstraintMax,
      maxHeight: c.maxHeight.isFinite ? c.maxHeight : kMusamiLayerConstraintMax,
    );
  }
}

/// Stable export id for built-in sticker layers (see sticker picker).
String musamiStickerExportId(String type, int index) =>
    'musami-sticker:$type:$index';

/// Rebuilds stable AI icon layers during state-history import.
Widget buildEditorAiIconWidget({
  required String name,
  required Color color,
  required Color backgroundColor,
  required double width,
  required double height,
}) {
  final icon = switch (name) {
    'home' => Icons.home_rounded,
    'email' => Icons.email_rounded,
    'user' => Icons.person_rounded,
    'phone' => Icons.phone_rounded,
    'location' => Icons.location_on_rounded,
    'website' => Icons.language_rounded,
    'calendar' => Icons.calendar_month_rounded,
    'star' => Icons.star_rounded,
    'check' => Icons.check_rounded,
    'arrow' => Icons.arrow_forward_rounded,
    _ => Icons.circle,
  };

  return SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color),
        ),
      ),
    ),
  );
}

/// Minimal sticker placeholder used when restoring sticker layers by id.
class _MusamiStickerPlaceholder extends StatelessWidget {
  const _MusamiStickerPlaceholder({required this.type, required this.index});

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
