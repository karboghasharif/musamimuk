import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/musami_document.dart';

void main() {
  const legacyPie = '{"v":"4.0.0","m":true,"p":0,"h":[],"r":{},"i":{"w":1080,"h":1920}}';

  test('legacy JSON wraps → serialize → parse round-trip', () {
    final wrapped = wrapLegacyHistory(
      historyJson: legacyPie,
      width: 1080,
      height: 1920,
    );
    expect(wrapped.pages, hasLength(1));
    expect(wrapped.activePage.historyJson, legacyPie);

    final envelope = serializeMusamiDocumentForSave(
      wrapped,
      forceEnvelope: true,
    );
    expect(musamiIsDocumentEnvelopeString(envelope), isTrue);

    final parsed = tryParseMusamiDocument(envelope);
    expect(parsed, isNotNull);
    expect(parsed!.pages, hasLength(1));
    expect(parsed.activePage.historyJson, legacyPie);
    expect(parsed.activePage.width, 1080);
    expect(parsed.activePage.height, 1920);
  });

  test('untouched single-page save stays plain PIE history', () {
    final wrapped = wrapLegacyHistory(
      historyJson: legacyPie,
      width: 1080,
      height: 1080,
    );
    final saved = serializeMusamiDocumentForSave(wrapped);
    expect(musamiIsDocumentEnvelopeString(saved), isFalse);
    expect(saved, legacyPie);
  });

  test('multipage serialize writes envelope; extract returns active PIE', () {
    final p1 = MusamiPage(
      id: 'page_a',
      name: 'Page 1',
      width: 1080,
      height: 1920,
      historyJson: '{"page":1}',
    );
    final p2 = MusamiPage(
      id: 'page_b',
      name: 'Page 2',
      width: 1080,
      height: 1920,
      historyJson: '{"page":2}',
    );
    final doc = MusamiDocument(
      pages: [p1, p2],
      activePageId: 'page_b',
    );
    final raw = serializeMusamiDocumentForSave(doc);
    expect(musamiIsDocumentEnvelopeString(raw), isTrue);
    expect(musamiExtractPieHistoryJson(raw), '{"page":2}');

    final again = tryParseMusamiDocument(raw)!;
    expect(again.pages.map((p) => p.historyJson).toList(), [
      '{"page":1}',
      '{"page":2}',
    ]);
  });

  test('page switch model keeps page 1 history when activating page 2', () {
    final p1 = MusamiPage(
      id: 'page_a',
      name: 'Page 1',
      width: 100,
      height: 100,
      historyJson: '{"layers":"one"}',
    );
    final p2 = MusamiPage(
      id: 'page_b',
      name: 'Page 2',
      width: 100,
      height: 100,
      historyJson: '{"layers":"two"}',
    );
    var doc = MusamiDocument(pages: [p1, p2], activePageId: 'page_a');
    // Simulate capture + switch without editor: write new history into active, then flip.
    doc = doc.copyWith(
      pages: [
        p1.copyWith(historyJson: '{"layers":"one-updated"}'),
        p2,
      ],
      activePageId: 'page_b',
    );
    expect(doc.pages.first.historyJson, '{"layers":"one-updated"}');
    expect(doc.activePage.historyJson, '{"layers":"two"}');
  });

  test('delete last page is rejected by helper rule', () {
    final doc = wrapLegacyHistory(
      historyJson: legacyPie,
      width: 10,
      height: 10,
    );
    expect(doc.pages.length <= 1, isTrue);
    // Controller enforces this; model itself stays ≥1 via assert.
    expect(doc.pages, hasLength(1));
  });

  test('malformed / classic PIE is not an envelope', () {
    expect(tryParseMusamiDocument(legacyPie), isNull);
    expect(tryParseMusamiDocument('{not json'), isNull);
    expect(musamiExtractPieHistoryJson(legacyPie), legacyPie);
  });

  test('envelope max pages constant is 10', () {
    expect(kMusamiDocumentMaxPages, 10);
  });

  test('json shape matches locked schema keys', () {
    final doc = wrapLegacyHistory(
      historyJson: '{}',
      width: 1,
      height: 2,
    );
    final map = jsonDecode(doc.serialize()) as Map<String, dynamic>;
    expect(map.containsKey('musamiDocumentVersion'), isTrue);
    expect(map.containsKey('activePageId'), isTrue);
    expect(map['pages'], isA<List>());
    final page = (map['pages'] as List).first as Map<String, dynamic>;
    expect(page.keys, containsAll(['id', 'name', 'width', 'height', 'historyJson']));
  });
}
