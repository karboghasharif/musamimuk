import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A font the user imported from their device (TTF/OTF).
class UserFontItem {
  const UserFontItem({
    required this.id,
    required this.name,
    required this.family,
    required this.fileName,
    required this.format,
    required this.importedAt,
  });

  final String id;
  final String name;

  /// Stable [FontLoader] family id (`musami_user_<id>`).
  final String family;
  final String fileName;
  final String format;
  final DateTime importedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'family': family,
        'fileName': fileName,
        'format': format,
        'importedAt': importedAt.toIso8601String(),
      };

  factory UserFontItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    return UserFontItem(
      id: id,
      name: (json['name'] ?? 'Font').toString(),
      family: (json['family'] ?? 'musami_user_$id').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      format: (json['format'] ?? 'ttf').toString().toLowerCase(),
      importedAt: DateTime.tryParse((json['importedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Result of importing a user font.
sealed class UserFontImportResult {}

class UserFontImportSuccess extends UserFontImportResult {
  UserFontImportSuccess(this.font);
  final UserFontItem font;
}

class UserFontImportCancelled extends UserFontImportResult {}

class UserFontImportFailure extends UserFontImportResult {
  UserFontImportFailure(this.message);
  final String message;
}

/// Local “My fonts” catalog: import TTF/OTF from the device, persist, and
/// register with [FontLoader] for the text editor.
class UserFontLibrary extends ChangeNotifier {
  UserFontLibrary._();

  static final UserFontLibrary instance = UserFontLibrary._();

  static const _indexFileName = 'index.json';

  final Set<String> _loadedFamilies = {};
  List<UserFontItem> _fonts = const [];
  bool _ready = false;
  bool _importing = false;
  String? _error;

  List<UserFontItem> get fonts => _fonts;
  bool get isReady => _ready;
  bool get isImporting => _importing;
  String? get error => _error;

  bool isFamilyLoaded(String family) => _loadedFamilies.contains(family);

  static String _newId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return bytes.map(hex).join();
  }

  Future<Directory> _fontsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/musami_user_fonts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _indexFile() async {
    final dir = await _fontsDir();
    return File('${dir.path}/$_indexFileName');
  }

  /// Loads the on-disk index and registers each font with [FontLoader].
  Future<void> ensureLoaded({bool force = false}) async {
    if (_ready && !force) return;
    try {
      final index = await _indexFile();
      if (!await index.exists()) {
        _fonts = const [];
        _ready = true;
        _error = null;
        notifyListeners();
        return;
      }
      final raw = jsonDecode(await index.readAsString());
      final list = <UserFontItem>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is Map) {
            list.add(
              UserFontItem.fromJson(Map<String, dynamic>.from(entry)),
            );
          }
        }
      }
      _fonts = list;
      _ready = true;
      _error = null;
      notifyListeners();

      for (final font in _fonts) {
        await loadStyle(font);
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('UserFontLibrary.ensureLoaded: $e');
      _error = 'Could not load your fonts.';
      _ready = true;
      notifyListeners();
    }
  }

  Future<void> _persistIndex() async {
    final index = await _indexFile();
    await index.writeAsString(
      jsonEncode(_fonts.map((f) => f.toJson()).toList(growable: false)),
      flush: true,
    );
  }

  /// Opens the system file picker for `.ttf` / `.otf` and imports the file.
  Future<UserFontImportResult> importFromDevice() async {
    if (_importing) {
      return UserFontImportFailure('Import already in progress.');
    }
    _importing = true;
    _error = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['ttf', 'otf'],
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        _importing = false;
        notifyListeners();
        return UserFontImportCancelled();
      }

      final picked = result.files.first;
      final ext = (picked.extension ?? '').toLowerCase();
      if (ext != 'ttf' && ext != 'otf') {
        _importing = false;
        _error = 'Only TTF and OTF fonts are supported.';
        notifyListeners();
        return UserFontImportFailure(_error!);
      }

      Uint8List? bytes = picked.bytes;
      if ((bytes == null || bytes.isEmpty) && picked.path != null) {
        bytes = await File(picked.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        _importing = false;
        _error = 'Could not read the selected font file.';
        notifyListeners();
        return UserFontImportFailure(_error!);
      }

      final id = _newId();
      final baseName = (picked.name.isNotEmpty ? picked.name : 'font.$ext')
          .replaceAll(RegExp(r'[^\w.\- ]+'), '_');
      final displayName = baseName
          .replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '')
          .trim();
      final family = 'musami_user_$id';
      final storedName = '$id.$ext';

      final dir = await _fontsDir();
      final file = File('${dir.path}/$storedName');
      await file.writeAsBytes(bytes, flush: true);

      final item = UserFontItem(
        id: id,
        name: displayName.isEmpty ? 'My font' : displayName,
        family: family,
        fileName: storedName,
        format: ext,
        importedAt: DateTime.now(),
      );

      final loader = FontLoader(family);
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _loadedFamilies.add(family);

      _fonts = [..._fonts, item];
      await _persistIndex();
      _importing = false;
      _error = null;
      notifyListeners();
      return UserFontImportSuccess(item);
    } catch (e) {
      if (kDebugMode) debugPrint('UserFontLibrary.importFromDevice: $e');
      _importing = false;
      _error = 'Could not import this font.';
      notifyListeners();
      return UserFontImportFailure(_error!);
    }
  }

  /// Registers [font] with [FontLoader] if needed and returns a [TextStyle].
  Future<TextStyle?> loadStyle(UserFontItem font) async {
    final family = font.family.trim();
    if (family.isEmpty) return null;
    try {
      if (!_loadedFamilies.contains(family)) {
        final dir = await _fontsDir();
        final file = File('${dir.path}/${font.fileName}');
        if (!await file.exists()) {
          _error = 'Font file is missing. Re-import “${font.name}”.';
          notifyListeners();
          return null;
        }
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          _error = 'Font file is empty.';
          notifyListeners();
          return null;
        }
        final loader = FontLoader(family);
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        _loadedFamilies.add(family);
      }
      return TextStyle(fontFamily: family);
    } catch (e) {
      if (kDebugMode) debugPrint('UserFontLibrary.loadStyle: $e');
      _error = 'Could not load “${font.name}”.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> delete(UserFontItem font) async {
    try {
      final dir = await _fontsDir();
      final file = File('${dir.path}/${font.fileName}');
      if (await file.exists()) {
        await file.delete();
      }
      _fonts = _fonts.where((f) => f.id != font.id).toList(growable: false);
      _loadedFamilies.remove(font.family);
      await _persistIndex();
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('UserFontLibrary.delete: $e');
      return false;
    }
  }
}
