import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musamimuk/presentation/add_new_screen/add_new_screen.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_image_fit.dart';
import 'package:musamimuk/presentation/add_new_screen/widgets/musami_text_layer_transform_overlay.dart';

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

/// Simulates free-stretch handle growth the same way the overlay projects
/// pointer deltas onto a handle sign (+1 / 0 / -1).
Size _resizeFromHandle({
  required Size start,
  required Offset handleSign,
  required Offset deltaLocal,
  bool maintainAspect = false,
}) {
  final isCorner = handleSign.dx != 0 && handleSign.dy != 0;
  final isHorizontalEdge = handleSign.dx != 0 && handleSign.dy == 0;
  final grow = Offset(
    handleSign.dx == 0 ? 0 : deltaLocal.dx * handleSign.dx,
    handleSign.dy == 0 ? 0 : deltaLocal.dy * handleSign.dy,
  );
  return musamiResizeFrameFromGesture(
    start: start,
    grow: grow,
    maintainAspect: maintainAspect,
    isCorner: isCorner,
    isHorizontalEdge: isHorizontalEdge,
  );
}

void main() {
  group('musamiImageFitModeFromMeta', () {
    test('defaults to crop', () {
      expect(musamiImageFitModeFromMeta(null), kMusamiImageFitCrop);
      expect(musamiImageFitModeFromMeta(<String, dynamic>{}), kMusamiImageFitCrop);
      expect(
        musamiImageFitModeFromMeta(<String, dynamic>{
          kMusamiImageFitModeMetaKey: 'nope',
        }),
        kMusamiImageFitCrop,
      );
    });

    test('reads stretch', () {
      expect(
        musamiImageFitModeFromMeta(<String, dynamic>{
          kMusamiImageFitModeMetaKey: 'stretch',
        }),
        kMusamiImageFitStretch,
      );
      expect(
        musamiImageFitBoxFit(<String, dynamic>{
          kMusamiImageFitModeMetaKey: 'STRETCH',
        }),
        BoxFit.fill,
      );
      expect(musamiImageFitBoxFit(null), BoxFit.cover);
    });
  });

  group('musamiLayerSupportsImageFitMode', () {
    test('blocks shapes and canvas borders', () {
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'shape',
        }),
        isFalse,
      );
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'design_pack_border',
          'musamiBorderMode': 'canvas_frame',
        }),
        isFalse,
      );
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'online_asset_lottie',
        }),
        isFalse,
      );
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'gallery',
        }),
        isTrue,
      );
    });

    test('excludes non-photo special widget layers', () {
      for (final kind in const [
        'ai-shape',
        'ai-icon',
        'lottie',
        'online_asset_svg',
        'design_pack_shape',
      ]) {
        expect(
          musamiLayerSupportsImageFitMode(<String, dynamic>{
            'musamiLayerKind': kind,
          }),
          isFalse,
          reason: kind,
        );
      }
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'sticker',
        }),
        isTrue,
      );
      expect(
        musamiLayerSupportsImageFitMode(<String, dynamic>{
          'musamiLayerKind': 'ai-image',
        }),
        isTrue,
      );
    });
  });

  group('legacy defaults and independence', () {
    test('missing fit stays crop; missing aspect lock stays free', () {
      final legacy = <String, dynamic>{
        'musamiLayerKind': 'gallery',
        'musamiAspect': 1.2,
      };
      expect(musamiImageFitModeFromMeta(legacy), kMusamiImageFitCrop);
      expect(musamiImageFitBoxFit(legacy), BoxFit.cover);
      expect(musamiMaintainAspectFromMeta(legacy), isFalse);
    });

    test('unlocking aspect does not rewrite explicit crop fit', () {
      final meta = <String, dynamic>{
        kMusamiImageFitModeMetaKey: kMusamiImageFitCrop,
        kMusamiMaintainAspectMetaKey: true,
      };
      // Mirror toolbar unlock: flip lock only.
      meta[kMusamiMaintainAspectMetaKey] = false;
      expect(musamiImageFitModeFromMeta(meta), kMusamiImageFitCrop);
      expect(musamiMaintainAspectFromMeta(meta), isFalse);
    });

    test('explicit stretch legacy documents stay stretch', () {
      final meta = <String, dynamic>{
        kMusamiImageFitModeMetaKey: kMusamiImageFitStretch,
        kMusamiMaintainAspectMetaKey: false,
      };
      expect(musamiImageFitModeFromMeta(meta), kMusamiImageFitStretch);
      expect(musamiImageFitBoxFit(meta), BoxFit.fill);
    });
  });

  group('musamiCopyImageTransformPersistenceMeta', () {
    test('copies contract keys without sharing the source map', () {
      final source = <String, dynamic>{
        kMusamiImageFitModeMetaKey: kMusamiImageFitStretch,
        kMusamiMaintainAspectMetaKey: true,
        kMusamiPhotoFrameAspectMetaKey: 0.8,
        kMusamiPhotoImageAspectMetaKey: 1.1,
        'musamiCropAlignX': -0.2,
        'musamiLayerLocked': true,
        'musamiClippingMask': true,
        'musamiClipMaskUrl': 'https://example.com/mask.png',
        'unrelated': 'keep-out',
      };
      final target = <String, dynamic>{'musamiLayerKind': 'gallery'};
      musamiCopyImageTransformPersistenceMeta(target, source);
      expect(target[kMusamiImageFitModeMetaKey], kMusamiImageFitStretch);
      expect(target[kMusamiMaintainAspectMetaKey], isTrue);
      expect(target['musamiCropAlignX'], -0.2);
      expect(target['musamiLayerLocked'], isTrue);
      expect(target['musamiClippingMask'], isTrue);
      expect(target.containsKey('unrelated'), isFalse);
      source[kMusamiImageFitModeMetaKey] = kMusamiImageFitCrop;
      expect(target[kMusamiImageFitModeMetaKey], kMusamiImageFitStretch);
    });
  });

  group('musamiBuildReplaceImageMeta', () {
    test('keeps crop/lock/clip from existing; updates image aspect from pick', () {
      final existing = <String, dynamic>{
        'musamiLayerKind': 'gallery',
        kMusamiImageFitModeMetaKey: kMusamiImageFitCrop,
        kMusamiMaintainAspectMetaKey: true,
        kMusamiPhotoFrameAspectMetaKey: 0.6,
        kMusamiPhotoImageAspectMetaKey: 0.9,
        'musamiCropAlignX': 0.3,
        'musamiLayerLocked': true,
        'musamiOpacity': 0.7,
        'musamiClippingMask': true,
        'musamiBorderW': 4.0,
      };
      final picked = musamiPhotoInsertMeta(
        layerKind: 'gallery',
        width: 400,
        height: 200,
      );
      picked['musamiOpacity'] = 1.0;

      final meta = musamiBuildReplaceImageMeta(
        existing: existing,
        picked: picked,
        frameAspect: 0.6,
        imageAspect: 0.5,
      );

      expect(meta[kMusamiImageFitModeMetaKey], kMusamiImageFitCrop);
      expect(meta[kMusamiMaintainAspectMetaKey], isTrue);
      expect(meta[kMusamiPhotoFrameAspectMetaKey], closeTo(0.6, 0.0001));
      expect(meta[kMusamiPhotoImageAspectMetaKey], closeTo(0.5, 0.0001));
      expect(meta['musamiCropAlignX'], 0.3);
      expect(meta['musamiLayerLocked'], isTrue);
      expect(meta['musamiOpacity'], 0.7);
      expect(meta['musamiClippingMask'], isTrue);
      expect(meta['musamiBorderW'], 4.0);
    });

    test('keeps stretch after resize-style replace', () {
      final existing = <String, dynamic>{
        kMusamiImageFitModeMetaKey: kMusamiImageFitStretch,
        kMusamiMaintainAspectMetaKey: false,
        kMusamiPhotoFrameAspectMetaKey: 2.0,
      };
      final meta = musamiBuildReplaceImageMeta(
        existing: existing,
        picked: musamiPhotoInsertMeta(layerKind: 'sticker'),
        frameAspect: 2.0,
        imageAspect: 1.0,
      );
      expect(meta[kMusamiImageFitModeMetaKey], kMusamiImageFitStretch);
      expect(meta[kMusamiMaintainAspectMetaKey], isFalse);
    });
  });

  group('musamiMaintainAspectFromMeta', () {
    test('defaults to free stretch', () {
      expect(musamiMaintainAspectFromMeta(null), isFalse);
      expect(musamiMaintainAspectFromMeta(<String, dynamic>{}), isFalse);
    });

    test('reads lock flag', () {
      expect(
        musamiMaintainAspectFromMeta(<String, dynamic>{
          kMusamiMaintainAspectMetaKey: true,
        }),
        isTrue,
      );
    });
  });

  group('musamiPhotoInsertMeta', () {
    test('writes free-stretch defaults and aspects', () {
      final meta = musamiPhotoInsertMeta(
        layerKind: 'gallery',
        width: 200,
        height: 100,
      );
      expect(meta['musamiLayerKind'], 'gallery');
      expect(meta[kMusamiImageFitModeMetaKey], kMusamiImageFitStretch);
      expect(meta[kMusamiMaintainAspectMetaKey], isFalse);
      expect(meta[kMusamiPhotoFrameAspectMetaKey], closeTo(0.5, 0.0001));
      expect(meta[kMusamiPhotoImageAspectMetaKey], closeTo(0.5, 0.0001));
    });

    test('omits aspects when size missing', () {
      final meta = musamiPhotoInsertMeta(layerKind: 'sticker');
      expect(meta.containsKey(kMusamiPhotoFrameAspectMetaKey), isFalse);
      expect(meta[kMusamiImageFitModeMetaKey], kMusamiImageFitStretch);
    });
  });

  group('musamiResizeFrameFromGesture', () {
    test('free corner grows independently', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(200, 300),
        grow: const Offset(30, 50),
        maintainAspect: false,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width, closeTo(230, 0.001));
      expect(next.height, closeTo(350, 0.001));
    });

    test('locked right edge keeps aspect', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(200, 300),
        grow: const Offset(40, 0),
        maintainAspect: true,
        isCorner: false,
        isHorizontalEdge: true,
      );
      expect(next.width, closeTo(240, 0.001));
      expect(next.height, closeTo(360, 0.001));
    });

    test('locked corner follows dominant axis', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(100, 100),
        grow: const Offset(50, 10),
        maintainAspect: true,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width, closeTo(150, 0.001));
      expect(next.height, closeTo(150, 0.001));
    });

    test('zero movement returns start size', () {
      const start = Size(200, 300);
      final next = musamiResizeFrameFromGesture(
        start: start,
        grow: Offset.zero,
        maintainAspect: false,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width, closeTo(200, 0.001));
      expect(next.height, closeTo(300, 0.001));
    });

    test('clamps negative shrinks to minimum', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(100, 100),
        grow: const Offset(-500, -500),
        maintainAspect: false,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width, kMusamiMinFrameSizePx);
      expect(next.height, kMusamiMinFrameSizePx);
    });

    test('clamps extreme growth to maximum', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(100, 100),
        grow: const Offset(999999, 999999),
        maintainAspect: false,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width, kMusamiMaxFrameSizePx);
      expect(next.height, kMusamiMaxFrameSizePx);
    });

    test('invalid grow uses finite clamp', () {
      final next = musamiResizeFrameFromGesture(
        start: const Size(100, 100),
        grow: const Offset(double.nan, double.infinity),
        maintainAspect: false,
        isCorner: true,
        isHorizontalEdge: false,
      );
      expect(next.width.isFinite, isTrue);
      expect(next.height.isFinite, isTrue);
      expect(next.width, greaterThanOrEqualTo(kMusamiMinFrameSizePx));
      expect(next.height, greaterThanOrEqualTo(kMusamiMinFrameSizePx));
    });

    test('repeated free-stretch from same start has no drift', () {
      const start = Size(200, 300);
      Size? last;
      for (var i = 1; i <= 20; i++) {
        last = musamiResizeFrameFromGesture(
          start: start,
          grow: Offset(i * 5.0, i * 3.0),
          maintainAspect: false,
          isCorner: true,
          isHorizontalEdge: false,
        );
      }
      expect(last!.width, closeTo(200 + 20 * 5.0, 0.001));
      expect(last.height, closeTo(300 + 20 * 3.0, 0.001));
    });
  });

  group('eight free-stretch handles', () {
    const start = Size(200, 300);

    test('right-center increases width only', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(1, 0),
        deltaLocal: const Offset(30, 40),
      );
      expect(next.width, closeTo(230, 0.001));
      expect(next.height, closeTo(300, 0.001));
    });

    test('left-center increases width when dragging left', () {
      // Left handle sign (-1,0): local dx negative → grow.dx positive.
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(-1, 0),
        deltaLocal: const Offset(-25, 10),
      );
      expect(next.width, closeTo(225, 0.001));
      expect(next.height, closeTo(300, 0.001));
    });

    test('bottom-center increases height only', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(0, 1),
        deltaLocal: const Offset(10, 50),
      );
      expect(next.width, closeTo(200, 0.001));
      expect(next.height, closeTo(350, 0.001));
    });

    test('top-center increases height when dragging up', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(0, -1),
        deltaLocal: const Offset(5, -40),
      );
      expect(next.width, closeTo(200, 0.001));
      expect(next.height, closeTo(340, 0.001));
    });

    test('bottom-right grows both axes', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(1, 1),
        deltaLocal: const Offset(30, 50),
      );
      expect(next.width, closeTo(230, 0.001));
      expect(next.height, closeTo(350, 0.001));
    });

    test('top-left grows both axes when dragging outward', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(-1, -1),
        deltaLocal: const Offset(-20, -30),
      );
      expect(next.width, closeTo(220, 0.001));
      expect(next.height, closeTo(330, 0.001));
    });

    test('top-right grows width and height', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(1, -1),
        deltaLocal: const Offset(15, -25),
      );
      expect(next.width, closeTo(215, 0.001));
      expect(next.height, closeTo(325, 0.001));
    });

    test('bottom-left grows width and height', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(-1, 1),
        deltaLocal: const Offset(-18, 22),
      );
      expect(next.width, closeTo(218, 0.001));
      expect(next.height, closeTo(322, 0.001));
    });

    test('right-center can shrink width', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(1, 0),
        deltaLocal: const Offset(-40, 0),
      );
      expect(next.width, closeTo(160, 0.001));
      expect(next.height, closeTo(300, 0.001));
    });

    test('bottom-center can shrink height', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(0, 1),
        deltaLocal: const Offset(0, -60),
      );
      expect(next.width, closeTo(200, 0.001));
      expect(next.height, closeTo(240, 0.001));
    });
  });

  group('aspect-locked handles', () {
    const start = Size(200, 300); // aspect 1.5

    test('locked left edge scales height with width', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(-1, 0),
        deltaLocal: const Offset(-40, 0),
        maintainAspect: true,
      );
      expect(next.width, closeTo(240, 0.001));
      expect(next.height, closeTo(360, 0.001));
    });

    test('locked top edge scales width with height', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(0, -1),
        deltaLocal: const Offset(0, -30),
        maintainAspect: true,
      );
      expect(next.height, closeTo(330, 0.001));
      expect(next.width, closeTo(220, 0.001));
    });

    test('locked bottom-right follows dominant width', () {
      final next = _resizeFromHandle(
        start: start,
        handleSign: const Offset(1, 1),
        deltaLocal: const Offset(40, 5),
        maintainAspect: true,
      );
      expect(next.width, closeTo(240, 0.001));
      expect(next.height, closeTo(360, 0.001));
    });
  });

  group('musamiOffsetKeepingAnchor', () {
    test('right-edge grow keeps left edge fixed', () {
      // Centre was at 0; frame 200 wide → left at -100. New width 230 → left
      // should stay at -100 ⇒ centre moves +15.
      final next = musamiOffsetKeepingAnchor(
        startOffset: Offset.zero,
        startFrame: const Size(200, 300),
        newFrame: const Size(230, 300),
        anchorSign: const Offset(-1, 0),
      );
      expect(next.dx, closeTo(15, 0.001));
      expect(next.dy, closeTo(0, 0.001));
    });

    test('bottom-edge grow keeps top edge fixed', () {
      final next = musamiOffsetKeepingAnchor(
        startOffset: Offset.zero,
        startFrame: const Size(200, 300),
        newFrame: const Size(200, 350),
        anchorSign: const Offset(0, -1),
      );
      expect(next.dx, closeTo(0, 0.001));
      expect(next.dy, closeTo(25, 0.001));
    });

    test('bottom-right grow keeps top-left corner fixed', () {
      final next = musamiOffsetKeepingAnchor(
        startOffset: Offset.zero,
        startFrame: const Size(200, 300),
        newFrame: const Size(230, 350),
        anchorSign: const Offset(-1, -1),
      );
      expect(next.dx, closeTo(15, 0.001));
      expect(next.dy, closeTo(25, 0.001));
    });

    test('top-left grow keeps bottom-right corner fixed', () {
      final next = musamiOffsetKeepingAnchor(
        startOffset: Offset.zero,
        startFrame: const Size(200, 300),
        newFrame: const Size(220, 330),
        anchorSign: const Offset(1, 1),
      );
      expect(next.dx, closeTo(-10, 0.001));
      expect(next.dy, closeTo(-15, 0.001));
    });
  });

  group('musamiScreenDeltaToCanvasDelta zoom', () {
    test('1.0x leaves delta unchanged', () {
      final d = musamiScreenDeltaToCanvasDelta(const Offset(40, -20), 1.0);
      expect(d.dx, closeTo(40, 0.0001));
      expect(d.dy, closeTo(-20, 0.0001));
    });

    test('0.5x doubles canvas delta', () {
      final d = musamiScreenDeltaToCanvasDelta(const Offset(40, -20), 0.5);
      expect(d.dx, closeTo(80, 0.0001));
      expect(d.dy, closeTo(-40, 0.0001));
    });

    test('1.5x scales canvas delta', () {
      final d = musamiScreenDeltaToCanvasDelta(const Offset(30, 15), 1.5);
      expect(d.dx, closeTo(20, 0.0001));
      expect(d.dy, closeTo(10, 0.0001));
    });

    test('2.0x halves canvas delta', () {
      final d = musamiScreenDeltaToCanvasDelta(const Offset(40, -20), 2.0);
      expect(d.dx, closeTo(20, 0.0001));
      expect(d.dy, closeTo(-10, 0.0001));
    });

    test('invalid zoom falls back to screen delta', () {
      final d = musamiScreenDeltaToCanvasDelta(const Offset(10, 5), 0);
      expect(d, const Offset(10, 5));
    });

    test('zoom-aware free right-edge resize matches expected width', () {
      // Finger moves +60 screen px at 2x zoom ⇒ +30 canvas ⇒ width 230.
      final canvas = musamiScreenDeltaToCanvasDelta(const Offset(60, 0), 2.0);
      final next = _resizeFromHandle(
        start: const Size(200, 300),
        handleSign: const Offset(1, 0),
        deltaLocal: canvas,
      );
      expect(next.width, closeTo(230, 0.001));
      expect(next.height, closeTo(300, 0.001));
    });
  });

  group('musamiTransformHandleOrigin', () {
    const box = Size(200, 300);
    const hit = 44.0;

    test('mid-edge handles are point boxes, not full-edge strips', () {
      final top = musamiTransformHandleOrigin(
        handle: TextTransformHandle.top,
        boxSize: box,
        hitSize: hit,
      );
      final left = musamiTransformHandleOrigin(
        handle: TextTransformHandle.left,
        boxSize: box,
        hitSize: hit,
      );
      expect(top.dx, closeTo(100 - hit / 2, 0.001));
      expect(top.dy, closeTo(-hit / 2, 0.001));
      expect(left.dx, closeTo(-hit / 2, 0.001));
      expect(left.dy, closeTo(150 - hit / 2, 0.001));
    });

    test('corner handles sit on corners without covering mid-edges', () {
      final tl = musamiTransformHandleOrigin(
        handle: TextTransformHandle.topLeft,
        boxSize: box,
        hitSize: hit,
      );
      final br = musamiTransformHandleOrigin(
        handle: TextTransformHandle.bottomRight,
        boxSize: box,
        hitSize: hit,
      );
      expect(tl, Offset(-hit / 2, -hit / 2));
      expect(br.dx, closeTo(200 - hit / 2, 0.001));
      expect(br.dy, closeTo(300 - hit / 2, 0.001));

      final top = musamiTransformHandleOrigin(
        handle: TextTransformHandle.top,
        boxSize: box,
        hitSize: hit,
      );
      // Top-mid and top-left boxes must not share the same origin.
      expect(top.dx, isNot(closeTo(tl.dx, 0.001)));
    });
  });

  group('musamiFrameWidgetLayerCore stretch', () {
    testWidgets('fill warps landscape image into a tall frame', (tester) async {
      tester.view.physicalSize = const Size(4000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const contentKey = Key('content');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: musamiFrameWidgetLayerCore(
              _content(key: contentKey, width: 1200, height: 800),
              width: 300,
              aspect: 2, // 300×600
              fit: BoxFit.fill,
            ),
          ),
        ),
      );

      final frame = tester.getSize(find.byKey(kMusamiLayerFrameBoxKey));
      expect(frame, const Size(300, 600));

      final painted = tester.getRect(find.byKey(contentKey));
      // Fill stretches content exactly to the frame (distorts 1.5 → 0.5 ratio).
      expect(painted.width, closeTo(300, 0.5));
      expect(painted.height, closeTo(600, 0.5));
      expect(painted.width / painted.height, closeTo(0.5, 0.01));
    });

    testWidgets('cover keeps intrinsic ratio (no warp)', (tester) async {
      tester.view.physicalSize = const Size(4000, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const contentKey = Key('content');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: musamiFrameWidgetLayerCore(
              _content(key: contentKey, width: 1200, height: 800),
              width: 300,
              aspect: 2,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      final painted = tester.getRect(find.byKey(contentKey));
      expect(painted.width / painted.height, closeTo(1200 / 800, 0.0001));
    });
  });
}
