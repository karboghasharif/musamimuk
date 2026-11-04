import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/design_state_history.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_curved_text_meta.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_curved_text_painter.dart';
import 'package:musamimuk/presentation/add_new_screen/widgets/musami_curved_text_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusamiCurvedTextParams meta', () {
    test('round-trips Arabic sample + arcAmount', () {
      final params = MusamiCurvedTextParams.fromPlainText(
        text: 'بسم الله الرحمن الرحيم',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: Color(0xFF006F73),
        ),
      ).copyWith(arcAmount: -0.6, clockwise: true);

      expect(params.rtl, isTrue);
      expect(musamiTextLooksArabic(params.sourceString), isTrue);

      final meta = params.toMeta();
      expect(meta['musamiLayerKind'], kMusamiCurvedTextLayerKind);
      expect(meta[kMusamiCurvedTextFlagMetaKey], isTrue);
      expect(meta[kMusamiCurvedSourceStringMetaKey], 'بسم الله الرحمن الرحيم');
      expect(musamiClampCurvedArcAmount(meta[kMusamiCurvedArcAmountMetaKey]),
          closeTo(-0.6, 1e-9));
      expect(meta[kMusamiCurvedClockwiseMetaKey], isTrue);
      expect(meta[kMusamiCurvedRtlMetaKey], isTrue);

      final restored = MusamiCurvedTextParams.fromMeta(meta);
      expect(restored.sourceString, params.sourceString);
      expect(restored.arcAmount, closeTo(-0.6, 1e-9));
      expect(restored.clockwise, isTrue);
      expect(restored.rtl, isTrue);
      expect(restored.fontSize, 40);
      expect(restored.color.toARGB32(), const Color(0xFF006F73).toARGB32());
    });

    test('clamps arcAmount and treats missing meta safely', () {
      expect(musamiClampCurvedArcAmount(2), 1);
      expect(musamiClampCurvedArcAmount(-3), -1);
      final empty = MusamiCurvedTextParams.fromMeta(null);
      expect(empty.sourceString, isEmpty);
      expect(empty.arcAmount, kMusamiCurvedArcAmountDefault);
      expect(musamiMetaIsCurvedText(empty.toMeta()), isTrue);
    });
  });

  group('layout + loader', () {
    test('layout size is finite for Arabic curve', () {
      final params = MusamiCurvedTextParams.fromPlainText(
        text: 'مرحبا بكم',
      ).copyWith(arcAmount: 0.8);
      final size = musamiCurvedTextLayoutSize(params);
      expect(size.width.isFinite, isTrue);
      expect(size.height.isFinite, isTrue);
      expect(size.width, greaterThan(8));
      expect(size.height, greaterThan(8));
    });

    testWidgets('widgetLoader builds curved text for Arabic sample',
        (tester) async {
      final params = MusamiCurvedTextParams.fromPlainText(
        text: 'مرحبا بكم',
      ).copyWith(arcAmount: 0.5);
      final meta = params.toMeta();
      final widget = musamiDesignWidgetLoader(
        '$kMusamiCurvedTextIdPrefix test',
        meta: meta,
      );
      expect(widget, isA<MusamiCurvedTextLayer>());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: widget),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MusamiCurvedTextLayer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
