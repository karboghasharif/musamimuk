import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:musamimuk/presentation/add_new_screen/utils/musami_clipping_mask.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_layer_raster_utils.dart';

const String _maskUrl = 'https://example.test/shapes/hexagon.png';

Map<String, dynamic> _clippedMeta({
  double frameAspect = 1.5,
  double contentAspect = 0.5,
}) {
  return <String, dynamic>{
    'musamiLayerKind': 'gallery',
    'musamiAspect': frameAspect,
    kMusamiClippingMaskMetaKey: true,
    kMusamiClipMaskUrlMetaKey: _maskUrl,
    kMusamiClipContentAspectMetaKey: contentAspect,
  };
}

void main() {
  group('musamiApplyClippingMaskFromMeta', () {
    test('returns the content untouched when no mask is active', () {
      const content = SizedBox.shrink();
      final meta = <String, dynamic>{
        'musamiLayerKind': 'gallery',
        'musamiAspect': 1.5,
      };
      expect(musamiApplyClippingMaskFromMeta(content, meta), same(content));
    });

    test('ignores an active flag without a mask url', () {
      const content = SizedBox.shrink();
      final meta = <String, dynamic>{kMusamiClippingMaskMetaKey: true};
      expect(musamiApplyClippingMaskFromMeta(content, meta), same(content));
    });

    test('wraps the content with the frame and content ratios from meta', () {
      const content = SizedBox.shrink();
      final wrapped = musamiApplyClippingMaskFromMeta(
        content,
        _clippedMeta(frameAspect: 1.5, contentAspect: 0.5),
      );

      expect(wrapped, isA<MusamiClipMaskedContent>());
      final masked = wrapped as MusamiClipMaskedContent;
      expect(masked.maskUrl, _maskUrl);
      expect(masked.maskAspect, 1.5);
      expect(masked.contentAspect, 0.5);
      expect(masked.child, same(content));
    });

    test('falls back to the frame ratio when the content ratio is missing', () {
      final meta = _clippedMeta(frameAspect: 2)
        ..remove(kMusamiClipContentAspectMetaKey);
      final masked =
          musamiApplyClippingMaskFromMeta(const SizedBox.shrink(), meta)
              as MusamiClipMaskedContent;

      expect(masked.contentAspect, 2);
    });
  });

  group('musamiTryUnwrapClipMaskedContent', () {
    test('peels the mask wrapper back to the bare content', () {
      const content = ColoredBox(color: Color(0xFF00FF00));
      final wrapped = musamiApplyClippingMaskFromMeta(content, _clippedMeta());

      expect(musamiTryUnwrapClipMaskedContent(wrapped), same(content));
      expect(musamiTryUnwrapClipMaskedContent(content), isNull);
    });
  });

  group('raster helpers see through the mask wrapper', () {
    test('memory bytes stay reachable for crop / background removal', () {
      final png = Uint8List.fromList(
        img.encodePng(img.Image(width: 2, height: 2)),
      );
      final wrapped = musamiApplyClippingMaskFromMeta(
        Image.memory(png, width: 2, height: 2),
        _clippedMeta(),
      );

      expect(musamiTryExtractMemoryImageBytes(wrapped), equals(png));
    });
  });

  group('MusamiClipMaskedContent layout', () {
    testWidgets('frame keeps the silhouette ratio and covers the content', (
      tester,
    ) async {
      const contentKey = Key('clip-content');
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 100,
              child: FittedBox(
                fit: BoxFit.contain,
                child: MusamiClipMaskedContent(
                  maskUrl: _maskUrl,
                  maskAspect: 1.5,
                  contentAspect: 0.5,
                  child: ColoredBox(
                    key: contentKey,
                    color: Color(0xFF112233),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final frameSize = tester.getSize(find.byType(MusamiClipMaskedContent));
      expect(frameSize.height / frameSize.width, closeTo(1.5, 0.001));

      final contentSize = tester.getSize(find.byKey(contentKey));
      expect(contentSize.height / contentSize.width, closeTo(0.5, 0.001));
      // Cover fit: the content box is wider than the frame before scaling.
      expect(contentSize.width, greaterThanOrEqualTo(frameSize.width));
    });
  });
}
