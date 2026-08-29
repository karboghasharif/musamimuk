import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/presentation/add_new_screen/widgets/musami_layer_context_menu.dart';

/// Pumps a screen whose single button opens the menu anchored to itself.
Future<void> _pumpMenuHost(
  WidgetTester tester, {
  required List<MusamiContextMenuSection> Function() sections,
  Alignment anchorAlignment = Alignment.bottomCenter,
  Size surface = const Size(400, 800),
}) async {
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: anchorAlignment,
          child: Builder(
            builder: (anchorContext) => ElevatedButton(
              onPressed: () => showMusamiLayerContextMenu(
                context: anchorContext,
                anchorRect: musamiAnchorRectFromContext(anchorContext)!,
                sections: sections(),
              ),
              child: const Text('More'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders every row and one divider between sections', (
    tester,
  ) async {
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onSelected: () {},
          ),
          MusamiContextMenuItem(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
            onSelected: () {},
          ),
        ]),
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.info_outline_rounded,
            label: 'Info',
            onSelected: () {},
          ),
        ]),
      ],
    );
    await _openMenu(tester);

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('skips empty sections so no stray divider is drawn', (
    tester,
  ) async {
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onSelected: () {},
          ),
        ]),
        const MusamiContextMenuSection([]),
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.info_outline_rounded,
            label: 'Info',
            onSelected: () {},
          ),
        ]),
      ],
    );
    await _openMenu(tester);

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('selecting a row closes the menu and runs the action', (
    tester,
  ) async {
    var ran = 0;
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onSelected: () => ran++,
          ),
        ]),
      ],
    );
    await _openMenu(tester);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(ran, 1);
    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('a disabled row does nothing and keeps the menu open', (
    tester,
  ) async {
    var ran = 0;
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.content_paste_rounded,
            label: 'Paste',
            enabled: false,
            onSelected: () => ran++,
          ),
        ]),
      ],
    );
    await _openMenu(tester);

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();

    expect(ran, 0);
    expect(find.text('Paste'), findsOneWidget);
  });

  testWidgets('tapping outside dismisses the menu', (tester) async {
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onSelected: () {},
          ),
        ]),
      ],
    );
    await _openMenu(tester);
    expect(find.text('Copy'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsNothing);
  });

  testWidgets('a repeated request while a menu is open does not stack panels', (
    tester,
  ) async {
    List<MusamiContextMenuSection> sections() => [
      MusamiContextMenuSection([
        MusamiContextMenuItem(
          icon: Icons.copy_rounded,
          label: 'Copy',
          onSelected: () {},
        ),
      ]),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (anchorContext) => ElevatedButton(
                onPressed: () {
                  final anchor = musamiAnchorRectFromContext(anchorContext)!;
                  showMusamiLayerContextMenu(
                    context: anchorContext,
                    anchorRect: anchor,
                    sections: sections(),
                  );
                  showMusamiLayerContextMenu(
                    context: anchorContext,
                    anchorRect: anchor,
                    sections: sections(),
                  );
                },
                child: const Text('More'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('reopens cleanly after being dismissed', (tester) async {
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onSelected: () {},
          ),
        ]),
      ],
    );

    for (var i = 0; i < 3; i++) {
      await _openMenu(tester);
      expect(find.text('Copy'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsNothing);
    }
  });

  testWidgets('a submenu row opens a nested menu and closes both on select', (
    tester,
  ) async {
    var aligned = 0;
    await _pumpMenuHost(
      tester,
      sections: () => [
        MusamiContextMenuSection([
          MusamiContextMenuItem(
            icon: Icons.align_horizontal_left_rounded,
            label: 'Align to page',
            submenu: () => [
              MusamiContextMenuSection([
                MusamiContextMenuItem(
                  icon: Icons.align_horizontal_left_rounded,
                  label: 'Align left',
                  onSelected: () => aligned++,
                ),
              ]),
            ],
          ),
        ]),
      ],
    );
    await _openMenu(tester);

    await tester.tap(find.text('Align to page'));
    await tester.pumpAndSettle();
    expect(find.text('Align left'), findsOneWidget);
    expect(find.text('Align to page'), findsOneWidget);

    await tester.tap(find.text('Align left'));
    await tester.pumpAndSettle();

    expect(aligned, 1);
    expect(find.text('Align left'), findsNothing);
    expect(find.text('Align to page'), findsNothing);
  });

  group('positioning', () {
    List<MusamiContextMenuSection> longMenu() => [
      MusamiContextMenuSection(
        List<MusamiContextMenuItem>.generate(
          14,
          (i) => MusamiContextMenuItem(
            icon: Icons.circle_outlined,
            label: 'Row $i',
            onSelected: () {},
          ),
        ),
      ),
    ];

    Future<Rect> panelRect(WidgetTester tester) async {
      final finder = find.byType(Material).last;
      final box = tester.renderObject<RenderBox>(finder);
      return box.localToGlobal(Offset.zero) & box.size;
    }

    testWidgets('opens above a bottom anchor and stays on screen', (
      tester,
    ) async {
      await _pumpMenuHost(
        tester,
        sections: () => [
          MusamiContextMenuSection([
            MusamiContextMenuItem(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onSelected: () {},
            ),
          ]),
        ],
      );
      await _openMenu(tester);

      final anchor = tester.getRect(find.text('More'));
      final panel = await panelRect(tester);

      expect(panel.bottom, lessThanOrEqualTo(anchor.top));
      expect(panel.top, greaterThanOrEqualTo(0));
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(400));
    });

    testWidgets('flips below when the anchor is at the top', (tester) async {
      await _pumpMenuHost(
        tester,
        anchorAlignment: Alignment.topCenter,
        sections: () => [
          MusamiContextMenuSection([
            MusamiContextMenuItem(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onSelected: () {},
            ),
          ]),
        ],
      );
      await _openMenu(tester);

      final anchor = tester.getRect(find.text('More'));
      final panel = await panelRect(tester);

      expect(panel.top, greaterThanOrEqualTo(anchor.bottom));
      expect(panel.bottom, lessThanOrEqualTo(800));
    });

    testWidgets('a menu taller than the viewport scrolls instead of clipping', (
      tester,
    ) async {
      await _pumpMenuHost(
        tester,
        sections: longMenu,
        surface: const Size(360, 420),
      );
      await _openMenu(tester);

      final panel = await panelRect(tester);
      expect(panel.top, greaterThanOrEqualTo(0));
      expect(panel.bottom, lessThanOrEqualTo(420));
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(360));

      expect(find.text('Row 0'), findsOneWidget);
      await tester.drag(find.text('Row 0'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Row 13'), findsOneWidget);
    });

    testWidgets('never overflows a narrow viewport', (tester) async {
      await _pumpMenuHost(
        tester,
        sections: () => [
          MusamiContextMenuSection([
            MusamiContextMenuItem(
              icon: Icons.wallpaper_rounded,
              label: 'Set image as background',
              onSelected: () {},
            ),
          ]),
        ],
        surface: const Size(240, 500),
      );
      await _openMenu(tester);

      final panel = await panelRect(tester);
      expect(panel.width, lessThanOrEqualTo(240));
      expect(panel.left, greaterThanOrEqualTo(0));
      expect(panel.right, lessThanOrEqualTo(240));
      expect(tester.takeException(), isNull);
    });
  });
}
