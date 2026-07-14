import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:musamimuk/presentation/add_new_screen/utils/musami_layer_raster_utils.dart';

void main() {
  group('musamiIsCropMetaKey', () {
    test('identifies documented and prefixed crop keys', () {
      expect(musamiIsCropMetaKey('musamiCropRevision'), isTrue);
      expect(musamiIsCropMetaKey('musamiCropRectNorm'), isTrue);
      expect(musamiIsCropMetaKey('musamiOpacity'), isFalse);
      expect(musamiIsCropMetaKey('musamiBorderW'), isFalse);
    });
  });

  group('musamiTryExtractMemoryImageBytes', () {
    test('returns null for a non-image subtree', () {
      const w = ColoredBox(color: Color(0xFF000000), child: SizedBox.shrink());
      expect(musamiTryExtractMemoryImageBytes(w), isNull);
    });

    test('finds bytes under DecoratedBox and ClipRRect stack', () {
      final png = Uint8List.fromList(
        img.encodePng(img.Image(width: 2, height: 2)),
      );
      final widget = DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            png,
            width: 2,
            height: 2,
            gaplessPlayback: true,
          ),
        ),
      );
      final out = musamiTryExtractMemoryImageBytes(widget);
      expect(out, isNotNull);
      expect(out, equals(png));
    });
  });

  group('replace meta merge (crop keys)', () {
    test('strip pattern removes only crop-related keys', () {
      final meta = <String, dynamic>{
        'musamiLayerKind': 'gallery',
        'musamiOpacity': 0.5,
        'musamiCropRevision': 3,
        'musamiCropRectNorm': '0.1',
      };
      meta.removeWhere((k, _) => musamiIsCropMetaKey(k));
      expect(meta.containsKey('musamiCropRevision'), isFalse);
      expect(meta['musamiOpacity'], 0.5);
      expect(meta['musamiLayerKind'], 'gallery');
    });
  });
}
