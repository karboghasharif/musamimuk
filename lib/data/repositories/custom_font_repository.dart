import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_utils.dart';
import '../models/custom_font_models.dart';

sealed class CustomFontResult<T> {}

class CustomFontSuccess<T> extends CustomFontResult<T> {
  CustomFontSuccess(this.data, {this.message});
  final T data;
  final String? message;
}

class CustomFontFailure<T> extends CustomFontResult<T> {
  CustomFontFailure(this.message);
  final String message;
}

/// Client for `GET /fonts` + on-device download / [FontLoader] registration.
///
/// Do **not** call `/admin/fonts/*` — those are web-admin only.
class CustomFontRepository {
  CustomFontRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static final Set<String> _loadedFamilies = <String>{};
  Future<Directory>? _cacheDirFuture;

  bool isFamilyLoaded(String family) => _loadedFamilies.contains(family);

  Future<Directory> _ensureCacheDir() {
    return _cacheDirFuture ??= () async {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/musami_custom_fonts');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }();
  }

  /// GET `/fonts`
  Future<CustomFontResult<CustomFontListPage>> listFonts({
    String? language,
    DateTime? updatedSince,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page.clamp(1, 10000),
        'per_page': perPage.clamp(1, 100),
      };
      if (language != null && language.trim().isNotEmpty) {
        query['language'] = language.trim().toLowerCase();
      }
      if (updatedSince != null) {
        query['updated_since'] = updatedSince.toUtc().toIso8601String();
      }

      final response = await _api.dio.get<Map<String, dynamic>>(
        'fonts',
        queryParameters: query,
      );
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return CustomFontFailure(
          apiExtractMessage(envelope) ?? 'Unable to load fonts.',
        );
      }

      final items = apiExtractDataList(envelope)
          .map(CustomFontItem.fromJson)
          .where((f) => f.fileUrl.isNotEmpty)
          .toList(growable: false);

      final meta = envelope['meta'];
      var currentPage = page;
      var lastPage = 1;
      var total = items.length;
      var resolvedPerPage = perPage;
      if (meta is Map) {
        currentPage = apiParseInt(meta['current_page'], fallback: page);
        lastPage = apiParseInt(meta['last_page'], fallback: 1);
        total = apiParseInt(meta['total'], fallback: items.length);
        resolvedPerPage = apiParseInt(meta['per_page'], fallback: perPage);
      }

      return CustomFontSuccess(
        CustomFontListPage(
          items: items,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
          perPage: resolvedPerPage,
        ),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return CustomFontFailure(apiMessageFromDioException(e));
    } catch (_) {
      return CustomFontFailure('Unable to load fonts.');
    }
  }

  /// GET `/fonts/{id}` or `/fonts/{uuid}`
  Future<CustomFontResult<CustomFontItem>> getFont(String idOrUuid) async {
    final key = idOrUuid.trim();
    if (key.isEmpty) return CustomFontFailure('Invalid font id.');
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('fonts/$key');
      final envelope = response.data;
      if (envelope == null || !apiResponseIsSuccess(envelope)) {
        return CustomFontFailure(
          apiExtractMessage(envelope) ?? 'Font not found.',
        );
      }
      final map = apiExtractPayloadMap(envelope);
      if (map == null) {
        // Some APIs nest the item under data as the object itself.
        final raw = envelope['data'] ?? envelope['dbData'];
        if (raw is Map) {
          return CustomFontSuccess(
            CustomFontItem.fromJson(raw.cast<String, dynamic>()),
            message: apiExtractMessage(envelope),
          );
        }
        return CustomFontFailure('Font not found.');
      }
      return CustomFontSuccess(
        CustomFontItem.fromJson(map),
        message: apiExtractMessage(envelope),
      );
    } on DioException catch (e) {
      return CustomFontFailure(apiMessageFromDioException(e));
    } catch (_) {
      return CustomFontFailure('Unable to load font.');
    }
  }

  /// Downloads (if needed), registers with [FontLoader], returns a [TextStyle].
  Future<CustomFontResult<TextStyle>> ensureLoaded(CustomFontItem font) async {
    if (!font.isFlutterLoadable) {
      return CustomFontFailure(
        'This font format (${font.fileFormat}) is not supported on mobile yet.',
      );
    }
    final family = font.family.trim();
    if (family.isEmpty) {
      return CustomFontFailure('Invalid font family.');
    }

    try {
      if (!_loadedFamilies.contains(family)) {
        final bytes = await _readOrDownloadBytes(font);
        if (bytes == null || bytes.isEmpty) {
          return CustomFontFailure('Could not download font file.');
        }
        final loader = FontLoader(family);
        loader.addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
        _loadedFamilies.add(family);
      }

      return CustomFontSuccess(
        TextStyle(
          fontFamily: family,
          fontWeight: font.fontWeight,
          fontStyle: font.fontStyle,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('CustomFontRepository.ensureLoaded: $e');
      return CustomFontFailure('Could not load font “${font.name}”.');
    }
  }

  Future<Uint8List?> _readOrDownloadBytes(CustomFontItem font) async {
    final dir = await _ensureCacheDir();
    final ext = font.fileFormat.isNotEmpty ? font.fileFormat : 'ttf';
    final checksum = font.checksumSha256.trim();
    final fileName = checksum.isNotEmpty
        ? '${font.id}_$checksum.$ext'
        : '${font.id}_${font.updatedAt?.millisecondsSinceEpoch ?? 0}.$ext';
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      final existing = await file.readAsBytes();
      if (existing.isNotEmpty) return existing;
    }

    final response = await _api.dio.get<List<int>>(
      font.fileUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        // Font CDN / storage may not need JSON Accept.
        headers: const {'Accept': '*/*'},
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    final bytes = Uint8List.fromList(data);
    await file.writeAsBytes(bytes, flush: true);

    // Persist a tiny side-car for debugging / future incremental sync.
    final metaFile = File('${dir.path}/${font.id}.json');
    await metaFile.writeAsString(jsonEncode(font.toJson()), flush: true);
    return bytes;
  }

  /// Fetches all pages (up to [maxPages]) for a language filter.
  Future<CustomFontResult<List<CustomFontItem>>> listAllFonts({
    String? language,
    DateTime? updatedSince,
    int perPage = 50,
    int maxPages = 20,
  }) async {
    final all = <CustomFontItem>[];
    var page = 1;
    while (page <= maxPages) {
      final result = await listFonts(
        language: language,
        updatedSince: updatedSince,
        page: page,
        perPage: perPage,
      );
      if (result is CustomFontFailure<CustomFontListPage>) {
        if (all.isEmpty) return CustomFontFailure(result.message);
        break;
      }
      final success = result as CustomFontSuccess<CustomFontListPage>;
      all.addAll(success.data.items);
      if (!success.data.hasMore) break;
      page++;
    }
    all.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return CustomFontSuccess(List.unmodifiable(all));
  }
}
