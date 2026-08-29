import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/design_state_history.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/services/import_export/constants/export_import_version.dart';
import 'package:pro_image_editor/shared/services/import_export/utils/key_minifier.dart';

/// Regression tests for saved-design round-trips (`design_data`).
///
/// Reopened designs lost user colours (e.g. a shape recoloured blue reopened
/// black): the visual meta must survive `export → JSON → import` so the editor
/// can re-apply it after import (see `_restoreImportedWidgetLayerVisuals`).
void main() {
  const int shapeTintArgb = 0xFF2196F3;
  const Color textColor = Color(0xFFFFFFFF);

  /// Builds an export map with the same structure/minification the app uses
  /// via [musamiDesignExportConfigs] (`enableMinify: true`, span `current`).
  Map<String, dynamic> buildMinifiedExportMap(List<Layer> layers) {
    final minifier = EditorKeyMinifier(enableMinify: true);

    var references = <String, dynamic>{
      for (final layer in layers)
        layer.id: layer.toMap(maxDecimalPlaces: 3, enableMinify: true),
    };
    var historyLayers = layers
        .map((layer) => layer.toMapFromReference(layer))
        .toList();
    historyLayers = minifier.convertListOfLayerKeys(historyLayers);
    references = minifier.convertReferenceKeys(references);

    final converted = minifier.convertLayerId(
      [
        {'l': historyLayers},
      ],
      references,
    );

    return {
      'v': ExportImportVersion.latest,
      'm': true,
      'p': 0,
      'h': converted.history,
      'r': converted.references,
      'i': {'w': 1080.0, 'h': 1080.0},
      'l': {'w': 400.0, 'h': 400.0},
    };
  }

  test('shape tint meta and text colour survive design_data round-trip', () {
    final shapeLayer = WidgetLayer(
      widget: const SizedBox(width: 100, height: 100),
      width: 200,
      scale: 0.4,
      exportConfigs: const WidgetLayerExportConfigs(
        networkUrl: 'https://example.com/media/shape.png',
        meta: {
          'musamiLayerKind': 'shape',
          'fileUrl': 'https://example.com/media/shape.png',
        },
      ),
      meta: const {
        'musamiLayerKind': 'shape',
        'fileUrl': 'https://example.com/media/shape.png',
        'musamiImageTintArgb': shapeTintArgb,
        'musamiOpacity': 0.8,
      },
    );
    final textLayer = TextLayer(
      text: 'My CV',
      color: textColor,
      background: const Color(0x00000000),
      colorMode: LayerBackgroundMode.onlyColor,
      align: TextAlign.center,
    );

    final json = jsonEncode(buildMinifiedExportMap([shapeLayer, textLayer]));
    final imported = musamiTryParseDesignImportHistory(json);

    expect(imported, isNotNull);
    final layers = imported!.stateHistory.last.layers;
    expect(layers, hasLength(2));

    final importedShape = layers.whereType<WidgetLayer>().single;
    expect(importedShape.meta?['musamiLayerKind'], 'shape');
    expect(importedShape.meta?['musamiImageTintArgb'], shapeTintArgb);
    expect(importedShape.meta?['musamiOpacity'], 0.8);

    final importedText = layers.whereType<TextLayer>().single;
    expect(importedText.color, textColor);
    expect(importedText.colorMode, LayerBackgroundMode.onlyColor);
  });
}
