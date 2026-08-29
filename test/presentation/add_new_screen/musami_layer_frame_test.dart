import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musamimuk/presentation/add_new_screen/add_new_screen.dart';

/// Intrinsic image content: a box at the source pixel ratio.
Widget _content({
  required Key key,
  required double width,
  required double height,
}) {
  return SizedBox(
    key: key,
    width: width,
    height: height,
    child: const ColoredBox(color: Color(0xFF00FF00)),
  );
}

Future<Rect> _pumpFrame(
  WidgetTester tester, {
  required Key contentKey,
  required Size image,
  required double frameWidth,
  required double frameAspect,
}) async {
  // Large surface so tall/wide frames are never clipped by the test viewport.
  tester.view.physicalSize = const Size(4000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: musamiFrameWidgetLayerCore(
          _content(key: contentKey, width: image.width, height: image.height),
          width: frameWidth,
          aspect: frameAspect,
        ),
      ),
    ),
  );
  return tester.getRect(find.byKey(contentKey));
}

void main() {
  group('musamiFrameWidgetLayerCore', () {
    testWidgets('frame takes the requested size regardless of image ratio', (
      tester,
    ) async {
      const contentKey = Key('content');
      await _pumpFrame(
        tester,
        contentKey: contentKey,
        image: const Size(1200, 800),
        frameWidth: 300,
        frameAspect: 2, // 300 x 600 frame from a 1.5 landscape image
      );

      final frame = tester.getSize(find.byKey(kMusamiLayerFrameBoxKey));
      expect(frame, const Size(300, 600));
    });

    testWidgets('landscape image in a tall frame is covered, never squashed', (
      tester,
    ) async {
      const contentKey = Key('content');
      final painted = await _pumpFrame(
        tester,
        contentKey: contentKey,
        image: const Size(1200, 800),
        frameWidth: 300,
        frameAspect: 2,
      );

      // coverScale = max(300 / 1200, 600 / 800) = 0.75 -> 900 x 600 painted.
      expect(painted.width, closeTo(900, 0.01));
      expect(painted.height, closeTo(600, 0.01));
      expect(painted.width / painted.height, closeTo(1200 / 800, 0.0001));
    });

    testWidgets('portrait image in a wide frame is covered, never squashed', (
      tester,
    ) async {
      const contentKey = Key('content');
      final painted = await _pumpFrame(
        tester,
        contentKey: contentKey,
        image: const Size(800, 1200),
        frameWidth: 700,
        frameAspect: 300 / 700,
      );

      // coverScale = max(700 / 800, 300 / 1200) = 0.875 -> 700 x 1050 painted.
      expect(painted.width, closeTo(700, 0.01));
      expect(painted.height, closeTo(1050, 0.01));
      expect(painted.width / painted.height, closeTo(800 / 1200, 0.0001));
    });

    testWidgets('image keeps its ratio across a sequence of frame ratios', (
      tester,
    ) async {
      const contentKey = Key('content');
      const image = Size(1200, 800);
      const ratios = <double>[0.25, 0.5, 1, 1.5, 2, 4];

      for (final aspect in ratios) {
        final painted = await _pumpFrame(
          tester,
          contentKey: contentKey,
          image: image,
          frameWidth: 400,
          frameAspect: aspect,
        );
        expect(
          painted.width / painted.height,
          closeTo(image.width / image.height, 0.0001),
          reason: 'distorted at frame aspect $aspect',
        );
        // Cover: the content is always at least as large as the frame.
        expect(painted.width, greaterThanOrEqualTo(400 - 0.01));
        expect(painted.height, greaterThanOrEqualTo(400 * aspect - 0.01));
      }
    });

    testWidgets('content is clipped to the frame', (tester) async {
      const contentKey = Key('content');
      await _pumpFrame(
        tester,
        contentKey: contentKey,
        image: const Size(1200, 800),
        frameWidth: 300,
        frameAspect: 2,
      );

      expect(
        find.descendant(
          of: find.byKey(kMusamiLayerFrameBoxKey),
          matching: find.byType(ClipRect),
        ),
        findsOneWidget,
      );
    });
  });

  group('musamiUnwrapLayerFrameBox', () {
    test('returns the intrinsic content of a frame box', () {
      const content = SizedBox(width: 1200, height: 800);
      final framed = musamiFrameWidgetLayerCore(
        content,
        width: 300,
        aspect: 2,
      );
      expect(musamiUnwrapLayerFrameBox(framed), same(content));
    });

    test('leaves an unframed core untouched', () {
      const bare = SizedBox(width: 10, height: 10);
      expect(musamiUnwrapLayerFrameBox(bare), same(bare));
    });

    test('re-framing does not nest frame shells', () {
      const content = SizedBox(width: 1200, height: 800);
      var framed = musamiFrameWidgetLayerCore(content, width: 300, aspect: 2);
      for (var i = 0; i < 5; i++) {
        framed = musamiResizeWidgetLayerCore(
          framed,
          width: 100.0 * (i + 1),
          aspect: 0.5 + i,
        );
      }
      expect(musamiUnwrapLayerFrameBox(framed), same(content));
    });
  });

  group('geometry sanitizers', () {
    test('width rejects zero, negative, NaN and infinity', () {
      expect(musamiSanitizedLayerWidth(0), 1.0);
      expect(musamiSanitizedLayerWidth(-40), 1.0);
      expect(musamiSanitizedLayerWidth(double.nan), 1.0);
      expect(musamiSanitizedLayerWidth(double.infinity), 1.0);
      expect(musamiSanitizedLayerWidth(320), 320);
    });

    test('aspect rejects zero, negative, NaN and infinity', () {
      expect(musamiSanitizedLayerAspect(0), 1.0);
      expect(musamiSanitizedLayerAspect(-2), 1.0);
      expect(musamiSanitizedLayerAspect(double.nan), 1.0);
      expect(musamiSanitizedLayerAspect(double.infinity), 1.0);
      expect(musamiSanitizedLayerAspect(1.25), 1.25);
    });
  });

  group('musamiLayerCropAlignment', () {
    test('defaults to centre', () {
      expect(musamiLayerCropAlignment(null), Alignment.center);
      expect(musamiLayerCropAlignment(<String, dynamic>{}), Alignment.center);
    });

    test('reads and clamps stored crop alignment', () {
      expect(
        musamiLayerCropAlignment(<String, dynamic>{
          kMusamiCropAlignXMetaKey: -0.5,
          kMusamiCropAlignYMetaKey: 4,
        }),
        const Alignment(-0.5, 1),
      );
    });
  });
}
