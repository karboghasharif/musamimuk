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
