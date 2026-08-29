import 'dart:convert';

import 'package:pro_image_editor/pro_image_editor.dart';

/// Shared helpers for decoding LLM HTTP responses safely.
Map<String, dynamic>? decodeJsonMap(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
  return null;
}

String editorAiDioErrorMessage(Object error, {required String fallback}) {
  final text = error.toString();
  if (text.contains('401')) return 'Invalid API key';
  if (text.contains('SocketException') || text.contains('connection')) {
    return 'Network error — check internet / VPN';
  }
  return fallback;
}

/// Fills defaults models often omit so [Layer.fromMap] does not throw.
///
/// Notably [TextLayer.fromMap] requires int `color` and `background`.
Map<String, dynamic> normalizeAiLayerMap(Map<String, dynamic> raw) {
  final map = Map<String, dynamic>.from(raw);
  final type = map['type']?.toString();

  map['x'] ??= 0.0;
  map['y'] ??= 0.0;
  map['rotation'] ??= 0.0;
  map['scale'] ??= 1.0;
  map['flipX'] ??= false;
  map['flipY'] ??= false;

  if (type == 'text') {
    map['text'] ??= '';
    map['colorMode'] ??= 'onlyColor';
    map['color'] ??= 0xFF111111; // near-black (visible on white canvas)
    // Required even for onlyColor — transparent ARGB.
    map['background'] ??= 0x00000000;
    map['align'] ??= 'center';
    map['fontScale'] ??= 1.0;
  } else if (type == 'emoji') {
    map['emoji'] ??= '🙂';
  } else if (type == 'paint' || type == 'painting') {
    map['opacity'] ??= 1.0;
    if (map['rawSize'] is! Map) {
      map['rawSize'] = {'w': 40.0, 'h': 40.0};
    }
    if (map['item'] is Map) {
      final item = Map<String, dynamic>.from(map['item'] as Map);
      item['mode'] ??= 'arrow';
      item['color'] ??= 0xFFFF0000;
      item['strokeWidth'] ??= 5.0;
      item['opacity'] ??= 1.0;
      item['fill'] ??= false;
      if (item['offsets'] is! List) {
        item['offsets'] = [
          {'x': 0.0, 'y': 0.0},
          {'x': 40.0, 'y': 40.0},
        ];
      }
      map['item'] = item;
    }
  }

  return map;
}

/// Parses AI layer maps; skips individual bad layers instead of failing all.
///
/// Widget/image layers are ignored here — they cannot be reconstructed from
/// model JSON and must be preserved from the live editor state instead.
List<Layer> parseAiLayers(List<dynamic> rawLayers) {
  final out = <Layer>[];
  for (final entry in rawLayers) {
    if (entry is! Map) continue;
    final type = entry['type']?.toString().toLowerCase();
    if (type == 'widget') continue;
    try {
      final normalized = normalizeAiLayerMap(Map<String, dynamic>.from(entry));
      final layer = Layer.fromMap(normalized);
      if (layer is WidgetLayer) continue;
      out.add(layer);
    } catch (_) {}
  }
  return out;
}

/// Merges AI text-command layers with the live editor layers.
///
/// Image stickers are [WidgetLayer]s that cannot round-trip through AI JSON.
/// Those live instances are always kept. When the model only returns brand-new
/// layers (typical "add text"), they are appended so existing images stay.
List<Layer> mergeAiCommandLayers({
  required List<Layer> existing,
  required List<Layer> fromAi,
}) {
  final aiUsable = fromAi.where((layer) => layer is! WidgetLayer).toList();
  if (aiUsable.isEmpty) return List<Layer>.from(existing);

  final existingIds = <String>{
    for (final layer in existing)
      if (layer.id.isNotEmpty) layer.id,
  };
  final isAdditive = aiUsable.every(
    (layer) => layer.id.isEmpty || !existingIds.contains(layer.id),
  );
  if (isAdditive) {
    return <Layer>[...existing, ...aiUsable];
  }

  final preservedWidgets = existing.whereType<WidgetLayer>().toList(
    growable: false,
  );
  final aiIds = <String>{
    for (final layer in aiUsable)
      if (layer.id.isNotEmpty) layer.id,
  };

  // Keep non-widget layers the model omitted only when they are not present
  // in the AI list (model may intentionally delete text/paint/emoji).
  // Widget layers are always restored afterward.
  final merged = <Layer>[...aiUsable];
  for (final widget in preservedWidgets) {
    if (widget.id.isEmpty || !aiIds.contains(widget.id)) {
      merged.add(widget);
    }
  }
  return merged;
}

/// Only apply transform if crop size is sane (avoids empty/broken configs).
bool isUsableAiTransform(Map<String, dynamic> map) {
  final crop = map['cropRect'];
  if (crop is! Map) return false;
  final left = (crop['left'] as num?)?.toDouble() ?? 0;
  final top = (crop['top'] as num?)?.toDouble() ?? 0;
  final right = (crop['right'] as num?)?.toDouble() ?? 0;
  final bottom = (crop['bottom'] as num?)?.toDouble() ?? 0;
  return right > left && bottom > top;
}
