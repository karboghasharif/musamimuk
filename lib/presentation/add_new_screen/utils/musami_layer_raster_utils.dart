import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:musamimuk/core/network/api_client.dart';

/// Extracts raw bytes from the first [MemoryImage] found under [root].
///
/// Used to detect gallery-backed (bitmap) layers and to feed the
/// [CropRotateEditor] without duplicating bytes in layer [meta].
Uint8List? musamiTryExtractMemoryImageBytes(Widget root) {
  final queue = <Widget>[root];
  while (queue.isNotEmpty) {
    final widget = queue.removeAt(0);

    if (widget is Image) {
      final ImageProvider p = widget.image;
      if (p is MemoryImage) {
        return p.bytes;
      }
      if (p is ResizeImage) {
        final inner = p.imageProvider;
        if (inner is MemoryImage) {
          return inner.bytes;
        }
      }
    }

    if (widget is SingleChildRenderObjectWidget) {
      final child = widget.child;
      if (child != null) queue.add(child);
    } else if (widget is MultiChildRenderObjectWidget) {
      for (final c in widget.children) {
        queue.add(c);
      }
    }
  }
  return null;
}

/// True when this widget layer is backed by in-memory raster data we can crop.
bool musamiWidgetLayerHasRasterCropSource(Widget layerWidget) {
  return musamiTryExtractMemoryImageBytes(layerWidget) != null;
}

ImageProvider? musamiTryExtractImageProvider(Widget root) {
  final queue = <Widget>[root];
  while (queue.isNotEmpty) {
    final widget = queue.removeAt(0);
    if (widget is Image) {
      return widget.image;
    }
    if (widget is SingleChildRenderObjectWidget) {
      final child = widget.child;
      if (child != null) queue.add(child);
    } else if (widget is MultiChildRenderObjectWidget) {
      for (final c in widget.children) {
        queue.add(c);
      }
    }
  }
  return null;
}

String? musamiTryExtractNetworkImageUrl(Widget root) {
  final provider = musamiTryExtractImageProvider(root);
  if (provider == null) return null;

  ImageProvider resolved = provider;
  if (resolved is ResizeImage) {
    resolved = resolved.imageProvider;
  }
  if (resolved is NetworkImage) {
    return resolved.url;
  }
  return null;
}

/// Resolves raster bytes from a widget layer (memory gallery or remote asset).
Future<Uint8List?> musamiResolveRasterBytesForBackgroundRemoval(
  Widget root,
) async {
  final memory = musamiTryExtractMemoryImageBytes(root);
  if (memory != null && memory.isNotEmpty) return memory;

  final url = musamiTryExtractNetworkImageUrl(root);
  if (url == null || url.trim().isEmpty) return null;

  try {
    final response = await ApiClient().dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

/// Prefix for any future non-destructive crop metadata. Not used in the current
/// destructive-bytes implementation; [replace] strips these defensively.
const String kMusamiCropMetaKeyPrefix = 'musamiCrop';

bool musamiIsCropMetaKey(String key) =>
    key == 'musamiCropRevision' || key.startsWith(kMusamiCropMetaKeyPrefix);
