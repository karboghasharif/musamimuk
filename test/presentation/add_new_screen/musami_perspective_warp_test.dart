import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:musamimuk/presentation/add_new_screen/utils/musami_perspective_warp.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_perspective_warp_meta.dart';

Uint8List _solidPng({int w = 40, int h = 30}) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgba8(20, 120, 200, 255));
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('musamiPerspectiveWarpPng', () {
    test('identity quad returns non-empty png', () {
      final src = _solidPng();
      final result = musamiPerspectiveWarpPng(
        bytes: src,
        quadNormalized: musamiDefaultWarpQuad(),
        maxEdge: 64,
      );
      expect(result, isNotNull);
      expect(result!.pngBytes, isNotEmpty);
      expect(result.width, greaterThan(0));
      expect(result.height, greaterThan(0));
      final decoded = img.decodeImage(result.pngBytes);
      expect(decoded, isNotNull);
    });

    test('skewed quad still produces pixels', () {
      final src = _solidPng(w: 60, h: 40);
      final result = musamiPerspectiveWarpPng(
        bytes: src,
        quadNormalized: const [
          0.1,
          0.0,
          0.9,
          0.05,
          1.0,
          1.0,
          0.0,
          0.95,
        ],
        maxEdge: 128,
      );
      expect(result, isNotNull);
      expect(result!.pngBytes.length, greaterThan(100));
      expect(result.quadNormalized.length, 8);
    });

    test('homography maps corners', () {
      final h = musamiComputeHomography(
        srcCorners: const [
          MusamiWarpPoint(0, 0),
          MusamiWarpPoint(10, 0),
          MusamiWarpPoint(10, 10),
          MusamiWarpPoint(0, 10),
        ],
        dstCorners: const [
          MusamiWarpPoint(0, 0),
          MusamiWarpPoint(10, 0),
          MusamiWarpPoint(10, 10),
          MusamiWarpPoint(0, 10),
        ],
      );
      expect(h, isNotNull);
      final p = musamiApplyHomography(h!, 5, 5);
      expect(p, isNotNull);
      expect(p!.x, closeTo(5, 0.1));
      expect(p.y, closeTo(5, 0.1));
    });

    test('meta quad parse', () {
      expect(musamiParseWarpQuad([0, 0, 1, 0, 1, 1, 0, 1]), isNotNull);
      expect(musamiParseWarpQuad([0, 0, 1]), isNull);
      expect(musamiMetaIsPerspectiveWarped({
        kMusamiWarpSourceMetaKey: kMusamiWarpSourceWarped,
      }), isTrue);
    });
  });
}
