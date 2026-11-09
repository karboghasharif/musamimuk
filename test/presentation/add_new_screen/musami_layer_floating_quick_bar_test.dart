import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/presentation/add_new_screen/widgets/musami_layer_floating_quick_bar.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

Layer _layerAt({required double offsetY}) {
  return TextLayer(
    text: 'Hi',
    offset: Offset(0, offsetY),
  );
}

void main() {
  group('musamiSelectionOverlayClipInsets', () {
    test('reserves app bar and residual bottom chrome', () {
      final insets = musamiSelectionOverlayClipInsets(
        screenSize: const Size(360, 800),
        appBarHeight: 80,
        canvasBodySize: const Size(360, 520),
      );
      expect(insets.top, 80);
      expect(insets.bottom, closeTo(200, 0.001));
    });

    test('minTop wins when live appBarHeight is still zero', () {
      final insets = musamiSelectionOverlayClipInsets(
        screenSize: const Size(360, 800),
        appBarHeight: 0,
        canvasBodySize: const Size(360, 600),
        minTop: 59,
      );
      expect(insets.top, 59);
      expect(insets.bottom, closeTo(141, 0.001));
    });

    test('zero body skips bottom clip', () {
      final insets = musamiSelectionOverlayClipInsets(
        screenSize: const Size(360, 800),
        appBarHeight: 59,
        canvasBodySize: Size.zero,
      );
      expect(insets.top, 59);
      expect(insets.bottom, 0);
    });
  });

  group('musamiLayerQuickBarPlacement', () {
    const canvas = Size(400, 800);

    test('top-half layer shows bar below', () {
      final layer = _layerAt(offsetY: -200);
      expect(
        musamiLayerQuickBarPlacement(layer: layer, canvasBodySize: canvas),
        MusamiLayerQuickBarPlacement.below,
      );
    });

    test('bottom-half layer shows bar above', () {
      final layer = _layerAt(offsetY: 200);
      expect(
        musamiLayerQuickBarPlacement(layer: layer, canvasBodySize: canvas),
        MusamiLayerQuickBarPlacement.above,
      );
    });

    test('layer centred on page prefers below (top half boundary)', () {
      final layer = _layerAt(offsetY: 0);
      expect(
        musamiLayerQuickBarPlacement(layer: layer, canvasBodySize: canvas),
        MusamiLayerQuickBarPlacement.below,
      );
    });
  });

  group('musamiLayerQuickBarAnchorForBounds', () {
    test('places bar below axis-aligned selection bounds', () {
      final anchor = musamiLayerQuickBarAnchorForBounds(
        bounds: const Rect.fromLTWH(0, 0, 100, 80),
        placement: MusamiLayerQuickBarPlacement.below,
      );
      expect(anchor.dx, 50);
      expect(anchor.dy, 80 + kMusamiLayerQuickBarGap);
    });

    test('places bar above axis-aligned selection bounds', () {
      final anchor = musamiLayerQuickBarAnchorForBounds(
        bounds: const Rect.fromLTWH(0, 0, 100, 80),
        placement: MusamiLayerQuickBarPlacement.above,
      );
      expect(anchor.dx, 50);
      expect(anchor.dy, -kMusamiLayerQuickBarGap - kMusamiLayerQuickBarHeight);
    });
  });

  group('musamiLayerQuickBarClampedCenterX', () {
    test('keeps bar on-screen near left edge', () {
      final x = musamiLayerQuickBarClampedCenterX(
        centerX: 10,
        barWidth: 160,
        viewportWidth: 360,
      );
      expect(x, greaterThan(10));
      expect(x, closeTo(8 + 80, 0.001));
    });

    test('keeps bar on-screen near right edge', () {
      final x = musamiLayerQuickBarClampedCenterX(
        centerX: 350,
        barWidth: 160,
        viewportWidth: 360,
      );
      expect(x, lessThan(350));
      expect(x, closeTo(360 - 8 - 80, 0.001));
    });
  });

  testWidgets('floating quick bar renders more button', (tester) async {
    var moreTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MusamiLayerFloatingQuickBar(
              actions: MusamiLayerQuickBarActions(
                isLocked: false,
                onLockToggle: () {},
                onDuplicate: () {},
                onDelete: () {},
                onMore: (_) => moreTapped = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    expect(moreTapped, isTrue);
  });
}
