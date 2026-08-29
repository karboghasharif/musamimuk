import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/design_state_history.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_composition.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_composition_builder.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_composition_schema.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  group('EditorAiComposition', () {
    test('strict schema rejects unknown fields and limits layer count', () {
      expect(editorAiCompositionJsonSchema['additionalProperties'], isFalse);
      final elements =
          (editorAiCompositionJsonSchema['properties'] as Map)['elements']
              as Map;
      expect(elements['maxItems'], EditorAiComposition.maxElements);
      expect((elements['items'] as Map)['additionalProperties'], isFalse);
    });

    test('parses, validates, and sorts editable elements', () {
      final composition = EditorAiComposition.fromMap({
        'elements': [
          {
            'type': 'text',
            'text': 'Your Name',
            'x': 0.2,
            'y': 0.3,
            'width': 0.3,
            'height': 0.1,
            'fontSize': 0.06,
            'fontWeight': 700,
            'color': '#006F73',
            'zIndex': 3,
          },
          {
            'type': 'shape',
            'shape': 'rectangle',
            'x': 0.5,
            'y': 0.5,
            'width': 1.0,
            'height': 1.0,
            'color': '#FFFFFF',
            'zIndex': 0,
          },
        ],
      });

      expect(
        composition.elements.first.type,
        EditorAiCompositionElementType.shape,
      );
      expect(composition.elements.last.text, 'Your Name');
      expect(composition.elements.last.color, 0xFF006F73);
    });

    test('rejects conflicting prompts for a reused image asset', () {
      Map<String, dynamic> image(String prompt) => {
        'type': 'image',
        'assetId': 'architecture',
        'prompt': prompt,
        'x': 0.5,
        'y': 0.5,
        'width': 0.5,
        'height': 0.5,
      };

      expect(
        () => EditorAiComposition.fromMap({
          'elements': [
            image('black and white street'),
            image('colorful building'),
          ],
        }),
        throwsFormatException,
      );
    });
  });

  test('builder creates separate native selectable layer types', () {
    final composition = EditorAiComposition.fromMap({
      'elements': [
        {
          'type': 'shape',
          'shape': 'circle',
          'x': 0.5,
          'y': 0.5,
          'width': 0.4,
          'height': 0.4,
          'color': '#008A8F',
          'fill': false,
        },
        {
          'type': 'image',
          'assetId': 'architecture',
          'prompt': 'black and white architectural street photo',
          'clip': 'circle',
          'x': 0.5,
          'y': 0.5,
          'width': 0.3,
          'height': 0.3,
        },
        {
          'type': 'text',
          'text': 'Your Name',
          'x': 0.2,
          'y': 0.3,
          'width': 0.3,
          'height': 0.1,
          'fontSize': 0.06,
          'fontWeight': 700,
          'color': '#006F73',
        },
        {
          'type': 'icon',
          'icon': 'home',
          'x': 0.7,
          'y': 0.4,
          'width': 0.05,
          'height': 0.08,
          'color': '#008A8F',
          'backgroundColor': '#FFFFFF',
        },
      ],
    });

    final layers = EditorAiCompositionBuilder.buildLayers(
      composition: composition,
      canvasSize: const Size(1200, 400),
      imageAssets: {
        'architecture': Uint8List.fromList([1, 2, 3]),
      },
      generatedAssets: const {},
      initialTextFontSize: 32,
    );

    final shapes = layers.whereType<PaintLayer>().toList(growable: false);
    expect(shapes, hasLength(1));
    expect(shapes.single.item.offsets.first!.dx, greaterThan(0));
    expect(layers.whereType<TextLayer>(), hasLength(1));
    expect(layers.whereType<WidgetLayer>(), hasLength(2));
    expect(layers.every((layer) => layer.interaction.enableSelection), isTrue);

    final image = layers.whereType<WidgetLayer>().firstWhere(
      (layer) => layer.meta?['musamiLayerKind'] == 'ai-image',
    );
    expect(image.meta?['aiClip'], 'circle');
    expect(image.meta?['musamiAspect'], 1);

    final text = layers.whereType<TextLayer>().single;
    expect(text.fontScale, 0.75);

    final icon = layers.whereType<WidgetLayer>().firstWhere(
      (layer) => layer.meta?['musamiLayerKind'] == 'ai-icon',
    );
    expect(icon.exportConfigs.id, 'musami-ai-icon:home');

    final restoredIcon = musamiDesignWidgetLoader(
      icon.exportConfigs.id!,
      meta: icon.exportConfigs.meta,
    );
    expect(restoredIcon, isNotNull);
  });
}
