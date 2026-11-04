import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// One locally auto-saved editor draft.
class LocalDesignDraft {
  const LocalDesignDraft({
    required this.id,
    required this.name,
    required this.historyJson,
    required this.width,
    required this.height,
    required this.updatedAt,
    this.thumbnailPath,
    this.folderId,
  });

  final String id;
  final String name;
  final String historyJson;
  final double width;
  final double height;
  final DateTime updatedAt;
  final String? thumbnailPath;

  /// Null / missing = Unfiled.
  final String? folderId;

  LocalDesignDraft copyWith({
    String? id,
    String? name,
    String? historyJson,
    double? width,
    double? height,
    DateTime? updatedAt,
    String? thumbnailPath,
    String? folderId,
    bool clearFolderId = false,
  }) {
    return LocalDesignDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      historyJson: historyJson ?? this.historyJson,
      width: width ?? this.width,
      height: height ?? this.height,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'historyJson': historyJson,
        'width': width,
        'height': height,
        'updatedAt': updatedAt.toIso8601String(),
        if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
        if (folderId != null && folderId!.isNotEmpty) 'folderId': folderId,
      };

  factory LocalDesignDraft.fromJson(Map<String, dynamic> json) {
    final rawFolder = json['folderId']?.toString().trim();
    return LocalDesignDraft(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled',
      historyJson: json['historyJson']?.toString() ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 1080,
      height: (json['height'] as num?)?.toDouble() ?? 1080,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      thumbnailPath: json['thumbnailPath']?.toString(),
      // Missing / empty folderId → Unfiled (safe migration).
      folderId: (rawFolder == null || rawFolder.isEmpty) ? null : rawFolder,
    );
  }
}

/// Persists editor drafts under the app documents directory (no Hive).
class LocalDesignStore {
  LocalDesignStore._();
  static final LocalDesignStore instance = LocalDesignStore._();

  static const String _indexFileName = 'index.json';
  static const int maxDrafts = 40;

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

  /// Test helper: clear cached documents root.
  @visibleForTesting
  void debugResetRootCache() {
    _initFuture = null;
  }

  Future<File> _indexFile() async {
    final root = await _ensureRoot();
    return File('${root.path}/$_indexFileName');
  }

  Future<List<LocalDesignDraft>> listDrafts() async {
    try {
      final file = await _indexFile();
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final drafts = decoded
          .whereType<Map>()
          .map((e) => LocalDesignDraft.fromJson(Map<String, dynamic>.from(e)))
          .where((d) => d.id.isNotEmpty && d.historyJson.isNotEmpty)
          .toList();
      drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return drafts;
    } catch (e) {
      if (kDebugMode) debugPrint('LocalDesignStore.listDrafts: $e');
      return const [];
    }
  }

  Future<void> _writeIndex(List<LocalDesignDraft> drafts) async {
    final file = await _indexFile();
    final trimmed = drafts.take(maxDrafts).toList(growable: false);
    await file.writeAsString(
      jsonEncode(trimmed.map((d) => d.toJson()).toList(growable: false)),
      flush: true,
    );
  }

  Future<String> _saveThumbnail(String id, Uint8List? pngBytes) async {
    if (pngBytes == null || pngBytes.isEmpty) return '';
    final root = await _ensureRoot();
    final path = '${root.path}/thumb_$id.png';
    await File(path).writeAsBytes(pngBytes, flush: true);
    return path;
  }

  /// Upserts a draft. Pass [existingId] to update the same autosave slot.
  /// Preserves existing [folderId] unless [folderId] is explicitly provided.
  Future<LocalDesignDraft> saveDraft({
    String? existingId,
    required String name,
    required String historyJson,
    required double width,
    required double height,
    Uint8List? thumbnailPng,
    String? folderId,
    bool clearFolderId = false,
  }) async {
    final id = (existingId != null && existingId.isNotEmpty)
        ? existingId
        : 'local_${DateTime.now().millisecondsSinceEpoch}';
    final existing = await listDrafts();
    LocalDesignDraft? previous;
    for (final d in existing) {
      if (d.id == id) {
        previous = d;
        break;
      }
    }
    final thumbPath = await _saveThumbnail(id, thumbnailPng);
    final resolvedFolder = clearFolderId
        ? null
        : (folderId ?? previous?.folderId);
    final draft = LocalDesignDraft(
      id: id,
      name: name.trim().isEmpty ? 'Untitled draft' : name.trim(),
      historyJson: historyJson,
      width: width,
      height: height,
      updatedAt: DateTime.now(),
      thumbnailPath: thumbPath.isEmpty
          ? previous?.thumbnailPath
          : thumbPath,
      folderId: resolvedFolder,
    );

    final next = <LocalDesignDraft>[
      draft,
      ...existing.where((d) => d.id != id),
    ];
    await _writeIndex(next);
    return draft;
  }

  Future<void> deleteDraft(String id) async {
    final existing = await listDrafts();
    final target = existing.where((d) => d.id == id).toList();
    final next = existing.where((d) => d.id != id).toList();
    await _writeIndex(next);
    for (final d in target) {
      final path = d.thumbnailPath;
      if (path == null || path.isEmpty) continue;
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  Future<LocalDesignDraft?> getDraft(String id) async {
    final all = await listDrafts();
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<LocalDesignDraft?> moveDraft({
    required String id,
    String? folderId,
  }) async {
    final existing = await listDrafts();
    final index = existing.indexWhere((d) => d.id == id);
    if (index < 0) return null;
    final resolved =
        (folderId == null || folderId.isEmpty) ? null : folderId;
    final updated = existing[index].copyWith(
      folderId: resolved,
      clearFolderId: resolved == null,
      updatedAt: DateTime.now(),
    );
    final next = [...existing]..[index] = updated;
    await _writeIndex(next);
    return updated;
  }

  /// When a folder is deleted, drafts in it become Unfiled.
  Future<void> clearFolderMembership(String folderId) async {
    final existing = await listDrafts();
    var changed = false;
    final next = existing.map((d) {
      if (d.folderId != folderId) return d;
      changed = true;
      return d.copyWith(clearFolderId: true);
    }).toList(growable: false);
    if (changed) await _writeIndex(next);
  }
}

/// Encodes a small PNG thumbnail from raw RGBA image bytes (best-effort).
Future<Uint8List?> musamiEncodePngThumbnail(
  Uint8List imageBytes, {
  int maxSide = 256,
}) async {
  try {
    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: maxSide,
      targetHeight: maxSide,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    return byteData?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}
