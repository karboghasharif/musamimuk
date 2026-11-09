import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/design_state_history.dart';
import 'package:musamimuk/data/models/musami_document.dart';
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

  test('envelope design_data imports active page PIE history only', () {
    final pie = jsonEncode(buildMinifiedExportMap([
      TextLayer(
        text: 'Page two',
        color: textColor,
        background: const Color(0x00000000),
        colorMode: LayerBackgroundMode.onlyColor,
        align: TextAlign.center,
      ),
    ]));
    final envelope = MusamiDocument(
      activePageId: 'page_2',
      pages: [
        MusamiPage(
          id: 'page_1',
          name: 'Page 1',
          width: 1080,
          height: 1080,
          historyJson: jsonEncode(buildMinifiedExportMap([])),
        ),
        MusamiPage(
          id: 'page_2',
          name: 'Page 2',
          width: 1080,
          height: 1080,
          historyJson: pie,
        ),
      ],
    ).serialize();

    final imported = musamiTryParseDesignImportHistory(envelope);
    expect(imported, isNotNull);
    final texts = imported!.stateHistory.last.layers.whereType<TextLayer>();
    expect(texts.single.text, 'Page two');
  });

  test('photo transform meta survives design_data round-trip', () {
    final photo = WidgetLayer(
      widget: const SizedBox(width: 300, height: 180),
      width: 300,
      scale: 1.25,
      offset: const Offset(40, -12),
      rotation: 0.35,
      flipX: true,
      flipY: false,
      exportConfigs: const WidgetLayerExportConfigs(
        networkUrl: 'https://example.com/media/photo.png',
        meta: {
          'musamiLayerKind': 'gallery',
          'musamiImageFitMode': 'stretch',
          'musamiMaintainAspectRatio': false,
        },
      ),
      meta: const {
        'musamiLayerKind': 'gallery',
        'fileUrl': 'https://example.com/media/photo.png',
        'musamiAspect': 0.6,
        'musamiImageAspect': 0.75,
        'musamiImageFitMode': 'stretch',
        'musamiMaintainAspectRatio': false,
        'musamiCropAlignX': -0.4,
        'musamiCropAlignY': 0.2,
        'musamiLayerLocked': true,
        'musamiOpacity': 0.85,
        'musamiClippingMask': true,
        'musamiClipMaskUrl': 'https://example.com/mask.png',
      },
    );

    final json = jsonEncode(buildMinifiedExportMap([photo]));
    final imported = musamiTryParseDesignImportHistory(json);
    expect(imported, isNotNull);

    final layer = imported!.stateHistory.last.layers.whereType<WidgetLayer>().single;
    expect(layer.width, closeTo(300, 0.001));
    expect(layer.scale, closeTo(1.25, 0.001));
    expect(layer.offset.dx, closeTo(40, 0.001));
    expect(layer.offset.dy, closeTo(-12, 0.001));
    expect(layer.rotation, closeTo(0.35, 0.001));
    expect(layer.flipX, isTrue);
    expect(layer.flipY, isFalse);
    expect(layer.meta?['musamiAspect'], 0.6);
    expect(layer.meta?['musamiImageAspect'], 0.75);
    expect(layer.meta?['musamiImageFitMode'], 'stretch');
    expect(layer.meta?['musamiMaintainAspectRatio'], isFalse);
    expect(layer.meta?['musamiCropAlignX'], -0.4);
    expect(layer.meta?['musamiCropAlignY'], 0.2);
    expect(layer.meta?['musamiLayerLocked'], isTrue);
    expect(layer.meta?['musamiOpacity'], 0.85);
    expect(layer.meta?['musamiClippingMask'], isTrue);
    expect(layer.meta?['musamiClipMaskUrl'], 'https://example.com/mask.png');
  });

  test('legacy photo without fit keys stays crop after round-trip', () {
    final legacy = WidgetLayer(
      widget: const SizedBox(width: 200, height: 200),
      width: 200,
      exportConfigs: const WidgetLayerExportConfigs(
        networkUrl: 'https://example.com/legacy.png',
      ),
      meta: const {
        'musamiLayerKind': 'gallery',
        'musamiAspect': 1.0,
        'musamiImageAspect': 1.0,
      },
    );

    final imported = musamiTryParseDesignImportHistory(
      jsonEncode(buildMinifiedExportMap([legacy])),
    );
    final layer =
        imported!.stateHistory.last.layers.whereType<WidgetLayer>().single;
    expect(layer.meta?.containsKey('musamiImageFitMode'), isFalse);
    expect(layer.meta?.containsKey('musamiMaintainAspectRatio'), isFalse);
  });

  test('multipage envelope retains per-page photo geometry on reopen', () {
    final page1History = jsonEncode(buildMinifiedExportMap([
      WidgetLayer(
        widget: const SizedBox(width: 220, height: 110),
        width: 220,
        scale: 2.0,
        offset: const Offset(10, 20),
        exportConfigs: const WidgetLayerExportConfigs(
          networkUrl: 'https://example.com/p1.png',
        ),
        meta: const {
          'musamiLayerKind': 'gallery',
          'musamiAspect': 0.5,
          'musamiImageAspect': 0.5,
          'musamiImageFitMode': 'stretch',
          'musamiMaintainAspectRatio': false,
        },
      ),
    ]));
    final page2History = jsonEncode(buildMinifiedExportMap([
      WidgetLayer(
        widget: const SizedBox(width: 180, height: 180),
        width: 180,
        scale: 1.0,
        exportConfigs: const WidgetLayerExportConfigs(
          networkUrl: 'https://example.com/p2.png',
        ),
        meta: const {
          'musamiLayerKind': 'gallery',
          'musamiAspect': 1.0,
          'musamiImageAspect': 1.0,
          'musamiImageFitMode': 'crop',
          'musamiMaintainAspectRatio': true,
        },
      ),
    ]));

    final envelope = MusamiDocument(
      activePageId: 'page_1',
      pages: [
        MusamiPage(
          id: 'page_1',
          name: 'Page 1',
          width: 1080,
          height: 1080,
          historyJson: page1History,
        ),
        MusamiPage(
          id: 'page_2',
          name: 'Page 2',
          width: 1080,
          height: 1080,
          historyJson: page2History,
        ),
      ],
    ).serialize();

    final doc = tryParseMusamiDocument(envelope);
    expect(doc, isNotNull);
    expect(doc!.pages, hasLength(2));

    final reopenP1 = musamiTryParseDesignImportHistory(doc.pages[0].historyJson);
    final reopenP2 = musamiTryParseDesignImportHistory(doc.pages[1].historyJson);
    final p1 = reopenP1!.stateHistory.last.layers.whereType<WidgetLayer>().single;
    final p2 = reopenP2!.stateHistory.last.layers.whereType<WidgetLayer>().single;

    expect(p1.width, closeTo(220, 0.001));
    expect(p1.scale, closeTo(2.0, 0.001));
    expect(p1.meta?['musamiImageFitMode'], 'stretch');
    expect(p1.meta?['musamiMaintainAspectRatio'], isFalse);

    expect(p2.width, closeTo(180, 0.001));
    expect(p2.meta?['musamiImageFitMode'], 'crop');
    expect(p2.meta?['musamiMaintainAspectRatio'], isTrue);
  });
}

