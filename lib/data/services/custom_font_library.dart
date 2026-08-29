import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/custom_font_models.dart';
import '../repositories/custom_font_repository.dart';

/// App-wide cache of active custom fonts from `GET /fonts`.
class CustomFontLibrary extends ChangeNotifier {
  CustomFontLibrary._({CustomFontRepository? repository})
      : _repo = repository ?? CustomFontRepository();

  static final CustomFontLibrary instance = CustomFontLibrary._();

  final CustomFontRepository _repo;

  List<CustomFontItem> _fonts = const [];
  bool _loading = false;
  String? _error;
  String? _lastLanguageFilter;
  DateTime? _lastFetchedAt;

  List<CustomFontItem> get fonts => _fonts;
  bool get isLoading => _loading;
  String? get error => _error;

  List<CustomFontItem> fontsForScript({required bool arabic}) {
    return _fonts
        .where((f) => arabic ? f.isArabicCapable : f.isEnglishCapable)
        .where((f) => f.isFlutterLoadable)
        .toList(growable: false);
  }

  /// Loads (or refreshes) the active font catalog.
  Future<void> ensureLoaded({
    String? language,
    bool force = false,
  }) async {
    final lang = language?.trim().toLowerCase();
    if (!force &&
        _fonts.isNotEmpty &&
        _lastLanguageFilter == lang &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < const Duration(minutes: 10)) {
      return;
    }
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    final result = await _repo.listAllFonts(language: lang);
    if (result is CustomFontFailure<List<CustomFontItem>>) {
      _error = result.message;
      _loading = false;
      notifyListeners();
      return;
    }

    final success = result as CustomFontSuccess<List<CustomFontItem>>;
    _fonts = success.data;
    _lastLanguageFilter = lang;
    _lastFetchedAt = DateTime.now();
    _loading = false;
    _error = null;
    notifyListeners();

    // Warm-load a few preview families in the background (best-effort).
    _warmLoadPreviews(_fonts.take(6));
  }

  Future<void> _warmLoadPreviews(Iterable<CustomFontItem> items) async {
    for (final font in items) {
      if (!font.isFlutterLoadable) continue;
      try {
        await _repo.ensureLoaded(font);
      } catch (e) {
        if (kDebugMode) debugPrint('CustomFontLibrary warm: $e');
      }
    }
    notifyListeners();
  }

  /// Downloads + registers [font], returning a style ready for the text editor.
  Future<TextStyle?> loadStyle(CustomFontItem font) async {
    final result = await _repo.ensureLoaded(font);
    if (result is CustomFontFailure<TextStyle>) {
      _error = result.message;
      notifyListeners();
      return null;
    }
    notifyListeners();
    return (result as CustomFontSuccess<TextStyle>).data;
  }

  bool isReady(CustomFontItem font) => _repo.isFamilyLoaded(font.family);
}
