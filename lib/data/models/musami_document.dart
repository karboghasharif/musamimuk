import 'dart:convert';

/// Max pages in a lightweight v1 multipage document.
const int kMusamiDocumentMaxPages = 10;

const String kMusamiDocumentVersionKey = 'musamiDocumentVersion';
const int kMusamiDocumentVersion = 1;

/// One page inside a [MusamiDocument].
class MusamiPage {
  const MusamiPage({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.historyJson,
    this.thumbnailBase64,
  });

  final String id;
  final String name;
  final double width;
  final double height;

  /// Raw Pro Image Editor [ExportStateHistory] JSON for this page.
  final String historyJson;
  final String? thumbnailBase64;

  MusamiPage copyWith({
    String? id,
    String? name,
    double? width,
    double? height,
    String? historyJson,
    String? thumbnailBase64,
    bool clearThumbnail = false,
  }) {
    return MusamiPage(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      historyJson: historyJson ?? this.historyJson,
      thumbnailBase64:
          clearThumbnail ? null : (thumbnailBase64 ?? this.thumbnailBase64),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'historyJson': historyJson,
        if (thumbnailBase64 != null) 'thumbnailBase64': thumbnailBase64,
      };

  factory MusamiPage.fromJson(Map<String, dynamic> json) {
    return MusamiPage(
      id: json['id']?.toString() ?? musamiNewPageId(),
      name: json['name']?.toString() ?? 'Page',
      width: (json['width'] as num?)?.toDouble() ?? 1080,
      height: (json['height'] as num?)?.toDouble() ?? 1080,
      historyJson: json['historyJson']?.toString() ?? '',
      thumbnailBase64: json['thumbnailBase64']?.toString(),
    );
  }
}

/// Versioned multipage envelope stored in `historyJson` / `design_data`.
class MusamiDocument {
  MusamiDocument({
    required this.pages,
    required this.activePageId,
    this.version = kMusamiDocumentVersion,
  }) : assert(pages.isNotEmpty, 'document needs ≥1 page');

  final int version;
  final List<MusamiPage> pages;
  final String activePageId;

  MusamiPage get activePage {
    for (final p in pages) {
      if (p.id == activePageId) return p;
    }
    return pages.first;
  }

  int get activeIndex {
    final i = pages.indexWhere((p) => p.id == activePageId);
    return i < 0 ? 0 : i;
  }

  bool get isMultipage => pages.length > 1;

  MusamiDocument copyWith({
    List<MusamiPage>? pages,
    String? activePageId,
    int? version,
  }) {
    return MusamiDocument(
      pages: pages ?? this.pages,
      activePageId: activePageId ?? this.activePageId,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        kMusamiDocumentVersionKey: version,
        'activePageId': activePageId,
        'pages': pages.map((p) => p.toJson()).toList(growable: false),
      };

  String serialize() => jsonEncode(toJson());
}

String musamiNewPageId() =>
    'page_${DateTime.now().microsecondsSinceEpoch}';

bool musamiIsDocumentEnvelopeMap(dynamic decoded) {
  if (decoded is! Map) return false;
  return decoded[kMusamiDocumentVersionKey] != null &&
      decoded['pages'] is List;
}

bool musamiIsDocumentEnvelopeString(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return false;
  try {
    return musamiIsDocumentEnvelopeMap(jsonDecode(t));
  } catch (_) {
    return false;
  }
}

/// Parses envelope or returns null for legacy / invalid JSON.
MusamiDocument? tryParseMusamiDocument(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  try {
    final decoded = jsonDecode(t);
    if (!musamiIsDocumentEnvelopeMap(decoded)) return null;
    final map = Map<String, dynamic>.from(decoded as Map);
    final rawPages = map['pages'];
    if (rawPages is! List || rawPages.isEmpty) return null;
    final pages = <MusamiPage>[];
    for (final e in rawPages) {
      if (e is Map) {
        pages.add(MusamiPage.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    if (pages.isEmpty) return null;
    final active = map['activePageId']?.toString();
    final activeId = (active != null && pages.any((p) => p.id == active))
        ? active
        : pages.first.id;
    final version = (map[kMusamiDocumentVersionKey] as num?)?.toInt() ??
        kMusamiDocumentVersion;
    return MusamiDocument(
      version: version,
      pages: pages,
      activePageId: activeId,
    );
  } catch (_) {
    return null;
  }
}

/// Wraps classic PIE history JSON as a one-page document.
MusamiDocument wrapLegacyHistory({
  required String historyJson,
  required double width,
  required double height,
  String? pageName,
}) {
  final id = musamiNewPageId();
  return MusamiDocument(
    activePageId: id,
    pages: [
      MusamiPage(
        id: id,
        name: pageName ?? 'Page 1',
        width: width,
        height: height,
        historyJson: historyJson,
      ),
    ],
  );
}

/// PIE history string for import: active page of envelope, else raw legacy.
String? musamiExtractPieHistoryJson(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  final doc = tryParseMusamiDocument(t);
  if (doc != null) {
    final h = doc.activePage.historyJson.trim();
    return h.isEmpty ? null : h;
  }
  return t;
}

/// Serializes for persistence.
///
/// - Multipage (or [forceEnvelope]): full envelope JSON.
/// - Single-page without force: plain PIE `historyJson` (legacy-compatible).
String serializeMusamiDocumentForSave(
  MusamiDocument doc, {
  bool forceEnvelope = false,
}) {
  if (forceEnvelope || doc.isMultipage) {
    return doc.serialize();
  }
  return doc.activePage.historyJson;
}
