import 'package:flutter/foundation.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/utils/design_state_history.dart';
import '../../../data/models/musami_document.dart';

/// In-memory multipage document while the editor is open.
///
/// Page switch: export current → store in slot → [importStateHistory] target
/// (replace merge) so layers never leak between pages.
class MusamiDocumentController extends ChangeNotifier {
  factory MusamiDocumentController.fromRaw({
    String? raw,
    required double width,
    required double height,
  }) {
    final parsed = tryParseMusamiDocument(raw);
    if (parsed != null) {
      // Opened an envelope → keep writing envelope even if pages shrink to 1.
      return MusamiDocumentController._(parsed, preferEnvelope: true);
    }
    final legacy = (raw ?? '').trim();
    return MusamiDocumentController._(
      wrapLegacyHistory(
        historyJson: legacy,
        width: width,
        height: height,
      ),
    );
  }

  MusamiDocumentController._(this._doc, {bool preferEnvelope = false})
      : _preferEnvelope = preferEnvelope;

  MusamiDocument _doc;
  bool _busy = false;
  bool _preferEnvelope;

  MusamiDocument get document => _doc;
  List<MusamiPage> get pages => _doc.pages;
  String get activePageId => _doc.activePageId;
  MusamiPage get activePage => _doc.activePage;
  bool get isBusy => _busy;
  bool get isMultipage => _doc.isMultipage;

  /// Persistable string: envelope when multipage / latch, else plain PIE history.
  String serializeForSave() {
    if (_doc.isMultipage) _preferEnvelope = true;
    return serializeMusamiDocumentForSave(
      _doc,
      forceEnvelope: _preferEnvelope,
    );
  }

  void _replace(MusamiDocument next) {
    _doc = next;
    notifyListeners();
  }

  Future<String?> _exportCurrent(ProImageEditorState editor) {
    return musamiExportDesignStateHistory(editor);
  }

  Future<bool> _importHistory(
    ProImageEditorState editor,
    String historyJson,
  ) async {
    final trimmed = historyJson.trim();
    if (trimmed.isEmpty) {
      // Blank page: clear all layers via empty history step.
      editor.addHistory(layers: const []);
      editor.setState(() {});
      return true;
    }
    final import = musamiTryParseDesignImportHistory(trimmed);
    if (import == null) return false;
    await editor.importStateHistory(import);
    return true;
  }

  /// Writes the live editor into the active page slot (no import).
  Future<void> captureActivePage(ProImageEditorState editor) async {
    final history = await _exportCurrent(editor);
    if (history == null || history.trim().isEmpty) return;
    final updated = _doc.pages
        .map(
          (p) => p.id == _doc.activePageId
              ? p.copyWith(historyJson: history)
              : p,
        )
        .toList(growable: false);
    _replace(_doc.copyWith(pages: updated));
  }

  Future<bool> switchToPage(
    ProImageEditorState editor,
    String pageId,
  ) async {
    if (_busy) return false;
    if (pageId == _doc.activePageId) return true;
    if (!_doc.pages.any((p) => p.id == pageId)) return false;
    _busy = true;
    notifyListeners();
    try {
      final history = await _exportCurrent(editor);
      if (history == null || history.trim().isEmpty) return false;
      final afterCapture = _doc.pages
          .map(
            (p) => p.id == _doc.activePageId
                ? p.copyWith(historyJson: history)
                : p,
          )
          .toList(growable: false);
      final target = afterCapture.firstWhere((p) => p.id == pageId);
      final ok = await _importHistory(editor, target.historyJson);
      if (!ok) return false;
      _replace(
        _doc.copyWith(pages: afterCapture, activePageId: pageId),
      );
      return true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> addPage(ProImageEditorState editor) async {
    if (_busy) return null;
    if (_doc.pages.length >= kMusamiDocumentMaxPages) {
      return 'msg_pages_limit_reached';
    }
    _busy = true;
    notifyListeners();
    try {
      final currentHistory = await _exportCurrent(editor);
      if (currentHistory == null || currentHistory.trim().isEmpty) {
        return 'msg_page_action_failed';
      }
      // Capture current, then clear for blank template, export blank, restore.
      editor.addHistory(layers: const []);
      editor.setState(() {});
      final blankHistory = await _exportCurrent(editor) ?? '';
      final restoreOk = await _importHistory(editor, currentHistory);
      if (!restoreOk) return 'msg_page_action_failed';

      final w = _doc.activePage.width;
      final h = _doc.activePage.height;
      final newId = musamiNewPageId();
      final pageIndex = _doc.pages.length + 1;
      final newPage = MusamiPage(
        id: newId,
        name: 'Page $pageIndex',
        width: w,
        height: h,
        historyJson: blankHistory,
      );
      final pages = [
        for (final p in _doc.pages)
          p.id == _doc.activePageId
              ? p.copyWith(historyJson: currentHistory)
              : p,
        newPage,
      ];
      // Stay on current page after add; user can tap the new thumb to switch.
      _replace(_doc.copyWith(pages: pages));
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> duplicateActivePage(ProImageEditorState editor) async {
    if (_busy) return null;
    if (_doc.pages.length >= kMusamiDocumentMaxPages) {
      return 'msg_pages_limit_reached';
    }
    _busy = true;
    notifyListeners();
    try {
      final currentHistory = await _exportCurrent(editor);
      if (currentHistory == null || currentHistory.trim().isEmpty) {
        return 'msg_page_action_failed';
      }
      final w = _doc.activePage.width;
      final h = _doc.activePage.height;
      final newId = musamiNewPageId();
      final pageIndex = _doc.pages.length + 1;
      final dup = MusamiPage(
        id: newId,
        name: 'Page $pageIndex',
        width: w,
        height: h,
        historyJson: currentHistory,
      );
      final pages = <MusamiPage>[
        for (final p in _doc.pages)
          p.id == _doc.activePageId
              ? p.copyWith(historyJson: currentHistory)
              : p,
      ];
      final insertAt = _doc.activeIndex + 1;
      pages.insert(insertAt, dup);
      _replace(_doc.copyWith(pages: pages));
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> deleteActivePage(ProImageEditorState editor) async {
    if (_busy) return null;
    if (_doc.pages.length <= 1) {
      return 'msg_cannot_delete_last_page';
    }
    _busy = true;
    notifyListeners();
    try {
      final removeId = _doc.activePageId;
      final removeIndex = _doc.activeIndex;
      final remaining = _doc.pages.where((p) => p.id != removeId).toList();
      final nextIndex = removeIndex.clamp(0, remaining.length - 1);
      final next = remaining[nextIndex];
      final ok = await _importHistory(editor, next.historyJson);
      if (!ok) return 'msg_page_action_failed';
      _replace(
        MusamiDocument(pages: remaining, activePageId: next.id),
      );
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Move active page by [delta] (−1 left / +1 right).
  Future<void> reorderActiveBy(int delta) async {
    if (_busy || delta == 0) return;
    final i = _doc.activeIndex;
    final j = i + delta;
    if (j < 0 || j >= _doc.pages.length) return;
    final pages = List<MusamiPage>.from(_doc.pages);
    final item = pages.removeAt(i);
    pages.insert(j, item);
    _replace(_doc.copyWith(pages: pages));
  }

  /// Unit-test helper: replace page history without an editor.
  @visibleForTesting
  void debugReplaceDocument(MusamiDocument doc) => _replace(doc);
}
