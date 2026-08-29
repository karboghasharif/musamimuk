import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_response_utils.dart';
import 'package:pro_image_editor/core/models/layers/layer_interaction.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  group('mergeAiCommandLayers', () {
    test('keeps existing AI images when model only returns new text', () {
      final imageA = _widgetLayer(id: 'img-a');
      final imageB = _widgetLayer(id: 'img-b');
      final newText = TextLayer(
        id: 'text-1',
        text: 'Hello',
        color: Colors.white,
      );

      final merged = mergeAiCommandLayers(
        existing: [imageA, imageB],
        fromAi: [newText],
      );

      expect(merged, hasLength(3));
      expect(merged.whereType<WidgetLayer>().map((l) => l.id), [
        'img-a',
        'img-b',
      ]);
      expect(merged.whereType<TextLayer>().single.text, 'Hello');
    });

    test('ignores AI widget maps and restores live widget layers', () {
      final image = _widgetLayer(id: 'img-live');
      final text = TextLayer(id: 'text-1', text: 'Title', color: Colors.white);

      final parsed = parseAiLayers([
        {'type': 'widget', 'id': 'img-live', 'x': 0, 'y': 0},
        {
          'type': 'text',
          'id': 'text-1',
          'text': 'Title',
          'color': 0xFFFFFFFF,
          'background': 0x00000000,
        },
      ]);

      final merged = mergeAiCommandLayers(existing: [image], fromAi: parsed);

      expect(parsed.whereType<WidgetLayer>(), isEmpty);
      expect(merged.whereType<WidgetLayer>().single.id, 'img-live');
      expect(merged.whereType<TextLayer>().single.text, 'Title');
    });

    test('updates existing text without dropping images', () {
      final image = _widgetLayer(id: 'img-a');
      final oldText = TextLayer(id: 'text-1', text: 'Old', color: Colors.white);
      final newText = TextLayer(id: 'text-1', text: 'New', color: Colors.white);

      final merged = mergeAiCommandLayers(
        existing: [image, oldText],
        fromAi: [newText],
      );

      expect(merged.whereType<WidgetLayer>().single.id, 'img-a');
      expect(merged.whereType<TextLayer>().single.text, 'New');
    });
  });
}

WidgetLayer _widgetLayer({required String id}) {
  return WidgetLayer(
    id: id,
    width: 120,
    scale: 0.2,
    interaction: LayerInteraction(enableEdit: false),
    widget: const SizedBox(width: 120, height: 120),
  );
}
