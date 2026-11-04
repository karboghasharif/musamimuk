import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/design_pack_models.dart';

/// Loads offline pack indexes under `assets/assets/` (no runtime directory listing).
class DesignPackCatalog {
  DesignPackCatalog._();
  static final DesignPackCatalog instance = DesignPackCatalog._();

  static const String packRoot = 'assets/assets';
  static const String svgManifestPath = '$packRoot/svg-manifest.json';
  static const String bordersManifestPath =
      '$packRoot/borders/borders-manifest.json';
  static const String patternsListPath = '$packRoot/patterns/patterns.json';

  Map<String, dynamic>? _svgManifest;
  List<DesignPackItem>? _borders;
  List<DesignPackItem>? _patterns;
  bool _loaded = false;

  @visibleForTesting
  void debugReset() {
    _svgManifest = null;
    _borders = null;
    _patterns = null;
    _loaded = false;
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    // svg-manifest first so patterns can fall back to it if patterns.json is absent.
    await _loadSvgManifest();
    await Future.wait([
      _loadBorders(),
      _loadPatterns(),
    ]);
    _loaded = true;
  }

  Future<void> _loadSvgManifest() async {
    try {
      final raw = await rootBundle.loadString(svgManifestPath);
      final decoded = jsonDecode(raw);
      _svgManifest = decoded is Map<String, dynamic>
          ? decoded
          : (decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{});
    } catch (e) {
      if (kDebugMode) debugPrint('DesignPackCatalog svg-manifest: $e');
      _svgManifest = <String, dynamic>{};
    }
  }

  Future<void> _loadBorders() async {
    try {
      final raw = await rootBundle.loadString(bordersManifestPath);
      _borders = parseBordersManifest(raw);
    } catch (e) {
      if (kDebugMode) debugPrint('DesignPackCatalog borders: $e');
      _borders = const [];
    }
  }

  /// Pure parser for [bordersManifestPath] JSON (unit-testable).
  @visibleForTesting
  static List<DesignPackItem> parseBordersManifest(String raw) {
    final decoded = jsonDecode(raw);
    final map = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final root = map['root']?.toString() ?? '$packRoot/borders';
    final items = map['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((e) {
          final row = Map<String, dynamic>.from(e);
          final file = row['file']?.toString() ?? '';
          final id = row['id']?.toString() ?? file;
          final thumb = row['thumb']?.toString();
          return DesignPackItem(
            id: 'border_$id',
            name: row['name']?.toString() ?? id,
            category: DesignPackCategory.borders,
            assetPath: file.isEmpty ? '' : '$root/$file',
            thumbPath:
                (thumb == null || thumb.isEmpty) ? null : '$root/$thumb',
          );
        })
        .where((i) => i.assetPath.isNotEmpty)
        .toList(growable: false);
  }

  /// Pure parser for shapes/emoji/specialtext sections of svg-manifest.
  @visibleForTesting
  static List<DesignPackItem> parseSvgSection(
    Map<String, dynamic> manifest, {
    required String section,
    String? subcategory,
  }) {
    final block = manifest[section];
    if (block is! Map) return const [];
    final entries = <String, List<dynamic>>{};
    if (subcategory != null) {
      final list = block[subcategory];
      if (list is List) entries[subcategory] = list;
    } else {
      for (final e in block.entries) {
        if (e.value is List) {
          entries[e.key.toString()] = e.value as List;
        }
      }
    }
    final out = <DesignPackItem>[];
    for (final entry in entries.entries) {
      final sub = entry.key;
      final folder = switch (section) {
        'shapes' => '$packRoot/shapes/$sub',
        'specialtext' => '$packRoot/specialtext/$sub',
        'emoji' => '$packRoot/emoji',
        _ => '$packRoot/$section/$sub',
      };
      for (final raw in entry.value) {
        final file = raw.toString();
        if (file.isEmpty) continue;
        final stem = file.contains('.')
            ? file.substring(0, file.lastIndexOf('.'))
            : file;
        out.add(
          DesignPackItem(
            id: '${section}_${sub}_$stem',
            name: stem.replaceAll('-', ' '),
            category: switch (section) {
              'shapes' => DesignPackCategory.shapes,
              'specialtext' => DesignPackCategory.specialtext,
              'emoji' => DesignPackCategory.emoji,
              _ => DesignPackCategory.shapes,
            },
            assetPath: '$folder/$file',
            subcategory: sub.isEmpty ? null : sub,
          ),
        );
      }
    }
    return out;
  }

  Future<void> _loadPatterns() async {
    try {
      // Prefer patterns.json list; fall back to svg-manifest patterns.
      List<String> names = const [];
      try {
        final raw = await rootBundle.loadString(patternsListPath);
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          names = decoded.map((e) => e.toString()).toList(growable: false);
        }
      } catch (_) {}
      if (names.isEmpty) {
        final fromManifest = _svgManifest?['patterns'];
        if (fromManifest is Map && fromManifest[''] is List) {
          names = (fromManifest[''] as List)
              .map((e) => e.toString())
              .toList(growable: false);
        }
      }
      _patterns = names
          .where((n) => n.trim().isNotEmpty)
          .map(
            (name) => DesignPackItem(
              id: 'pattern_$name',
              name: name.replaceAll(RegExp(r'\.[^.]+$'), '').replaceAll('-', ' '),
              category: DesignPackCategory.patterns,
              assetPath: '$packRoot/patterns/$name',
              thumbPath: '$packRoot/patterns/$name',
            ),
          )
          .toList(growable: false);
    } catch (e) {
      if (kDebugMode) debugPrint('DesignPackCatalog patterns: $e');
      _patterns = const [];
    }
  }

  List<String> subcategories(DesignPackCategory category) {
    final manifest = _svgManifest;
    if (manifest == null) return const [];
    switch (category) {
      case DesignPackCategory.shapes:
        final shapes = manifest['shapes'];
        if (shapes is! Map) return const [];
        return shapes.keys.map((e) => e.toString()).toList(growable: false)
          ..sort();
      case DesignPackCategory.specialtext:
        final special = manifest['specialtext'];
        if (special is! Map) return const [];
        return special.keys.map((e) => e.toString()).toList(growable: false)
          ..sort();
      case DesignPackCategory.emoji:
      case DesignPackCategory.borders:
      case DesignPackCategory.patterns:
        // Emoji lives in a single flat folder (manifest key "").
        return const [];
    }
  }

  List<DesignPackItem> items({
    required DesignPackCategory category,
    String? subcategory,
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    Iterable<DesignPackItem> source;
    switch (category) {
      case DesignPackCategory.borders:
        source = _borders ?? const [];
      case DesignPackCategory.patterns:
        source = _patterns ?? const [];
      case DesignPackCategory.shapes:
        source = _fromSvgSection('shapes', subcategory);
      case DesignPackCategory.specialtext:
        source = _fromSvgSection('specialtext', subcategory);
      case DesignPackCategory.emoji:
        source = _fromSvgSection('emoji', subcategory ?? '');
    }
    if (q.isEmpty) return source.toList(growable: false);
    return source
        .where(
          (i) =>
              i.name.toLowerCase().contains(q) ||
              i.id.toLowerCase().contains(q) ||
              (i.subcategory ?? '').toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Iterable<DesignPackItem> _fromSvgSection(
    String section,
    String? subcategory,
  ) {
    final manifest = _svgManifest;
    if (manifest == null) return const [];
    return parseSvgSection(
      manifest,
      section: section,
      subcategory: subcategory,
    );
  }

  /// Resolves a stored asset path; returns null if empty / obviously invalid.
  static String? resolveAssetPath(String? raw) {
    final path = raw?.trim() ?? '';
    if (path.isEmpty) return null;
    if (path.startsWith('assets/')) return path;
    return '$packRoot/$path';
  }
}
