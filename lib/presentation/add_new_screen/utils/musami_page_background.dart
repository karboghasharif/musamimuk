import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Sample grid used for dominant-colour extraction. Small enough to run on the
/// UI isolate without a frame drop, large enough to be representative.
const int _kPaletteSampleEdge = 64;

/// Buckets per channel when quantising colours (5 bits ≈ 32 levels).
const int _kPaletteChannelBits = 5;

/// Decodes [bytes], treating malformed input as "no image".
///
/// `decodeImage` probes every format it knows and can throw a [RangeError] on
/// truncated data instead of returning `null`, so the throw is folded into the
/// same null result.
img.Image? _decode(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      return null;
    }
    return decoded;
  } catch (_) {
    return null;
  }
}

/// Fits [imageBytes] to a [canvasSize] page background without distortion.
///
/// Uses a cover/crop strategy — the image is scaled by
/// `max(canvasW / imgW, canvasH / imgH)` so both axes are covered, then the
/// overflow is cropped around the centre. The source ratio is preserved
/// exactly; the image is never squashed to the page ratio.
///
/// Returns encoded PNG bytes sized to the canvas, or `null` if decoding fails.
Uint8List? musamiRenderCoverBackground({
  required Uint8List imageBytes,
  required Size canvasSize,
}) {
  final targetWidth = canvasSize.width.round();
  final targetHeight = canvasSize.height.round();
  if (targetWidth <= 0 || targetHeight <= 0) return null;

  final decoded = _decode(imageBytes);
  if (decoded == null) return null;

  final coverScale = math.max(
    targetWidth / decoded.width,
    targetHeight / decoded.height,
  );
  final scaledWidth = math.max(1, (decoded.width * coverScale).round());
  final scaledHeight = math.max(1, (decoded.height * coverScale).round());

  final scaled = img.copyResize(
    decoded,
    width: scaledWidth,
    height: scaledHeight,
    interpolation: img.Interpolation.cubic,
  );

  final cropped = img.copyCrop(
    scaled,
    x: ((scaledWidth - targetWidth) / 2).round().clamp(0, scaledWidth - 1),
    y: ((scaledHeight - targetHeight) / 2).round().clamp(0, scaledHeight - 1),
    width: math.min(targetWidth, scaledWidth),
    height: math.min(targetHeight, scaledHeight),
  );

  return Uint8List.fromList(img.encodePng(cropped));
}

/// Extracts up to [maxColors] dominant colours from [imageBytes].
///
/// Quantises pixels into coarse RGB buckets on a downsampled copy and returns
/// the most frequent buckets, brightest-first ties broken by frequency. Fully
/// transparent and near-duplicate colours are skipped.
List<Color> musamiExtractDominantColors(
  Uint8List imageBytes, {
  int maxColors = 6,
}) {
  final decoded = _decode(imageBytes);
  if (decoded == null) return const <Color>[];

  final sample = img.copyResize(
    decoded,
    width: decoded.width >= decoded.height ? _kPaletteSampleEdge : null,
    height: decoded.height > decoded.width ? _kPaletteSampleEdge : null,
    interpolation: img.Interpolation.average,
  );

  final shift = 8 - _kPaletteChannelBits;
  final counts = <int, int>{};
  final sums = <int, List<int>>{};

  for (var y = 0; y < sample.height; y++) {
    for (var x = 0; x < sample.width; x++) {
      final pixel = sample.getPixel(x, y);
      if (pixel.a < 32) continue;

      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final bucket =
          ((r >> shift) << (_kPaletteChannelBits * 2)) |
          ((g >> shift) << _kPaletteChannelBits) |
          (b >> shift);

      counts[bucket] = (counts[bucket] ?? 0) + 1;
      final sum = sums.putIfAbsent(bucket, () => <int>[0, 0, 0]);
      sum[0] += r;
      sum[1] += g;
      sum[2] += b;
    }
  }
  if (counts.isEmpty) return const <Color>[];

  final ranked = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  final palette = <Color>[];
  for (final bucket in ranked) {
    final count = counts[bucket]!;
    final sum = sums[bucket]!;
    final color = Color.fromARGB(
      255,
      (sum[0] / count).round().clamp(0, 255),
      (sum[1] / count).round().clamp(0, 255),
      (sum[2] / count).round().clamp(0, 255),
    );
    if (palette.any((existing) => _colorDistance(existing, color) < 40)) {
      continue;
    }
    palette.add(color);
    if (palette.length >= maxColors) break;
  }
  return palette;
}

double _colorDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

/// Request payload for the background isolate: bytes plus the target size.
typedef _CoverRequest = (Uint8List bytes, int width, int height);

Uint8List? _renderCoverBackgroundTask(_CoverRequest request) {
  return musamiRenderCoverBackground(
    imageBytes: request.$1,
    canvasSize: Size(request.$2.toDouble(), request.$3.toDouble()),
  );
}

List<int> _extractDominantColorsTask(Uint8List bytes) {
  return musamiExtractDominantColors(
    bytes,
  ).map((color) => color.toARGB32()).toList(growable: false);
}

/// [musamiRenderCoverBackground] on a background isolate.
///
/// Decoding and resampling a full-page bitmap takes long enough to drop frames
/// on the UI isolate, so it is offloaded.
Future<Uint8List?> musamiRenderCoverBackgroundAsync({
  required Uint8List imageBytes,
  required Size canvasSize,
}) {
  final width = canvasSize.width.round();
  final height = canvasSize.height.round();
  if (width <= 0 || height <= 0) return Future<Uint8List?>.value();
  return compute(_renderCoverBackgroundTask, (imageBytes, width, height));
}

/// [musamiExtractDominantColors] on a background isolate.
Future<List<Color>> musamiExtractDominantColorsAsync(
  Uint8List imageBytes,
) async {
  final argb = await compute(_extractDominantColorsTask, imageBytes);
  return argb.map(Color.new).toList(growable: false);
}
