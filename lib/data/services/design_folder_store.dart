import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/design_folder.dart';
import 'local_design_store.dart';

/// Typed error codes for folder create/rename/delete.
class FolderStoreException implements Exception {
  FolderStoreException(this.code);
  final String code;

  @override
  String toString() => code;
}

/// Persists My Designs folders + cloud design → folder membership.
///
/// Local drafts store `folderId` on [LocalDesignDraft].
/// Cloud designs are tagged client-side until a folders API exists.
class DesignFolderStore {
  DesignFolderStore._();
  static final DesignFolderStore instance = DesignFolderStore._();

  /// Sentinel filter id for the Unfiled chip (not a real folder row).
  static const String unfiledId = '__unfiled__';

  static const int maxFolders = 20;
  static const int minNameLength = 2;
  static const int maxNameLength = 30;

  static final RegExp _safeName = RegExp(
    r"^[\p{L}\p{N} _\-\.'’&()]+$",
    unicode: true,
  );

  static const String _foldersFileName = 'folders.json';
  static const String _cloudMembershipKey = 'design_folder_membership_v1';

  Future<Directory>? _initFuture;

  /// When set, skips `path_provider` (unit tests).
  @visibleForTesting
  Directory? debugRootOverride;

  Future<Directory> _ensureRoot() {
    final override = debugRootOverride;
    if (override != null) {
      return () async {
        if (!await override.exists()) {
          await override.create(recursive: true);
        }
        return override;
      }();
    }
    return _initFuture ??= () async {
      final docs = await getApplicationDocumentsDirectory();
      final root = Directory('${docs.path}/musami_local_designs');
      if (!await root.exists()) {
        await root.create(recursive: true);
      }
      return root;
    }();
  }

  @visibleForTesting
  void debugResetRootCache() {
    _initFuture = null;
  }

  Future<File> _foldersFile() async {
    final root = await _ensureRoot();
    return File('${root.path}/$_foldersFileName');
  }

  /// Returns null when valid; otherwise an error key / message reason code.
  static String? validateName(String raw) {
    final name = raw.trim();
    if (name.length < minNameLength || name.length > maxNameLength) {
      return 'length';
    }
    if (!_safeName.hasMatch(name)) {
      return 'charset';
    }
    return null;
  }

  Future<List<DesignFolder>> listFolders() async {
    try {
      final file = await _foldersFile();
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const [];
      final list = decoded['folders'];
      if (list is! List) return const [];
      final folders = list
          .whereType<Map>()
          .map((e) => DesignFolder.fromJson(Map<String, dynamic>.from(e)))
          .where((f) => f.id.isNotEmpty && f.name.trim().isNotEmpty)
          .toList();
      folders.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.createdAt.compareTo(b.createdAt);
      });
      return folders;
    } catch (e) {
      if (kDebugMode) debugPrint('DesignFolderStore.listFolders: $e');
      return const [];
    }
  }

  Future<void> _writeFolders(List<DesignFolder> folders) async {
    final file = await _foldersFile();
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'folders': folders.map((f) => f.toJson()).toList(growable: false),
      }),
      flush: true,
    );
  }

  Future<DesignFolder> createFolder(String rawName) async {
    final err = validateName(rawName);
    if (err != null) {
      throw ArgumentError(err);
    }
    final name = rawName.trim();
    final existing = await listFolders();
    if (existing.length >= maxFolders) {
      throw FolderStoreException('max');
    }
    final duplicate = existing.any(
      (f) => f.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw FolderStoreException('duplicate');
    }
    final maxOrder = existing.isEmpty
        ? -1
        : existing.map((f) => f.sortOrder).reduce((a, b) => a > b ? a : b);
    final folder = DesignFolder(
      id: 'fld_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      sortOrder: maxOrder + 1,
    );
    await _writeFolders([...existing, folder]);
    return folder;
  }

  Future<DesignFolder> renameFolder(String id, String rawName) async {
    final err = validateName(rawName);
    if (err != null) {
      throw ArgumentError(err);
    }
    final name = rawName.trim();
    final existing = await listFolders();
    final index = existing.indexWhere((f) => f.id == id);
    if (index < 0) {
      throw FolderStoreException('missing');
    }
    final duplicate = existing.any(
      (f) => f.id != id && f.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw FolderStoreException('duplicate');
    }
    final updated = existing[index].copyWith(name: name);
    final next = [...existing]..[index] = updated;
    await _writeFolders(next);
    return updated;
  }

  /// Deletes the folder and moves local drafts / cloud tags to Unfiled.
  Future<void> deleteFolder(String id) async {
    final existing = await listFolders();
    final next = existing.where((f) => f.id != id).toList(growable: false);
    if (next.length == existing.length) {
      throw FolderStoreException('missing');
    }
    await _writeFolders(next);
    await LocalDesignStore.instance.clearFolderMembership(id);
    await clearCloudMembershipForFolder(id);
  }

  Future<Map<String, String>> _readCloudMembership() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cloudMembershipKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, String>{};
      decoded.forEach((key, value) {
        final k = key.toString();
        final v = value?.toString();
        if (k.isNotEmpty && v != null && v.isNotEmpty) {
          out[k] = v;
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeCloudMembership(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cloudMembershipKey, jsonEncode(map));
  }

  Future<String?> cloudFolderId(String designId) async {
    final map = await _readCloudMembership();
    return map[designId];
  }

  Future<Map<String, String>> cloudMembershipSnapshot() =>
      _readCloudMembership();

  Future<void> setCloudFolder({
    required String designId,
    String? folderId,
  }) async {
    final map = await _readCloudMembership();
    if (folderId == null || folderId.isEmpty || folderId == unfiledId) {
      map.remove(designId);
    } else {
      map[designId] = folderId;
    }
    await _writeCloudMembership(map);
  }

  Future<void> clearCloudMembershipForFolder(String folderId) async {
    final map = await _readCloudMembership();
    map.removeWhere((_, value) => value == folderId);
    await _writeCloudMembership(map);
  }
}
