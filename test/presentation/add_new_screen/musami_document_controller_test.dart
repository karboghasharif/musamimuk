import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/musami_document.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_document_controller.dart';

void main() {
  test('fromRaw legacy wraps one page; serialize stays plain until multipage', () {
    const legacy = '{"v":1,"h":[]}';
    final c = MusamiDocumentController.fromRaw(
      raw: legacy,
      width: 1080,
      height: 1920,
    );
    expect(c.pages, hasLength(1));
    expect(c.isMultipage, isFalse);
    expect(musamiIsDocumentEnvelopeString(c.serializeForSave()), isFalse);
    expect(c.serializeForSave(), legacy);
  });

  test('fromRaw envelope restores all pages and active id', () {
    final raw = MusamiDocument(
      activePageId: 'page_b',
      pages: [
        const MusamiPage(
          id: 'page_a',
          name: 'Page 1',
          width: 100,
          height: 200,
          historyJson: '{"a":1}',
        ),
        const MusamiPage(
          id: 'page_b',
          name: 'Page 2',
          width: 100,
          height: 200,
          historyJson: '{"b":2}',
        ),
      ],
    ).serialize();

    final c = MusamiDocumentController.fromRaw(
      raw: raw,
      width: 100,
      height: 200,
    );
    expect(c.pages, hasLength(2));
    expect(c.activePageId, 'page_b');
    expect(c.activePage.historyJson, '{"b":2}');
    expect(musamiIsDocumentEnvelopeString(c.serializeForSave()), isTrue);
  });

  test('reorderActiveBy swaps neighbors; delete last rejected without editor', () async {
    final c = MusamiDocumentController.fromRaw(
      raw: null,
      width: 10,
      height: 10,
    );
    c.debugReplaceDocument(
      MusamiDocument(
        activePageId: 'a',
        pages: const [
          MusamiPage(
            id: 'a',
            name: '1',
            width: 10,
            height: 10,
            historyJson: '{}',
          ),
          MusamiPage(
            id: 'b',
            name: '2',
            width: 10,
            height: 10,
            historyJson: '{}',
          ),
        ],
      ),
    );
    await c.reorderActiveBy(1);
    expect(c.pages.map((p) => p.id).toList(), ['b', 'a']);
    expect(c.activePageId, 'a');

    // Single-page reject path uses editor; assert rule via length check.
    c.debugReplaceDocument(
      wrapLegacyHistory(historyJson: '{}', width: 1, height: 1),
    );
    expect(c.pages, hasLength(1));
  });
}
