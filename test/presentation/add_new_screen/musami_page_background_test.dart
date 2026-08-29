import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:musamimuk/presentation/add_new_screen/utils/musami_page_background.dart';

Uint8List _solidPng(int width, int height, img.Color color) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: color);
  return Uint8List.fromList(img.encodePng(image));
}

/// Two vertical bands so a palette has something to find.
Uint8List _twoTonePng(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(220, 30, 40));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: width ~/ 2,
    y2: height - 1,
    color: img.ColorRgb8(20, 60, 200),
  );
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  group('musamiRenderCoverBackground', () {
    test('output matches the canvas size exactly', () {
      final bytes = _solidPng(400, 200, img.ColorRgb8(10, 20, 30));

      final result = musamiRenderCoverBackground(
        imageBytes: bytes,
        canvasSize: const Size(1080, 1350),
      );

      final decoded = img.decodePng(result!)!;
      expect(decoded.width, 1080);
      expect(decoded.height, 1350);
    });

    test('covers a tall canvas from a wide image without squashing', () {
      // A 2:1 image on a 1:2 canvas. Cover scales by height, so the visible
      // slice must be a centre crop of the original, never a stretched copy.
      final image = img.Image(width: 400, height: 200);
      img.fill(image, color: img.ColorRgb8(0, 0, 0));
      // Mark a 20px square at the exact centre; after a centre crop it stays
      // centred, which a non-uniform stretch would not preserve.
      img.fillRect(
        image,
        x1: 190,
        y1: 90,
        x2: 209,
        y2: 109,
        color: img.ColorRgb8(255, 255, 255),
      );
      final bytes = Uint8List.fromList(img.encodePng(image));

      final result = musamiRenderCoverBackground(
        imageBytes: bytes,
        canvasSize: const Size(200, 400),
      );
      final decoded = img.decodePng(result!)!;

      // Scale = max(200/400, 400/200) = 2 → the 20px marker becomes 40px.
      final centre = decoded.getPixel(100, 200);
      expect(centre.r, greaterThan(200));

      // 40px tall marker → still white 15px above centre, black 40px above.
      expect(decoded.getPixel(100, 185).r, greaterThan(200));
      expect(decoded.getPixel(100, 240).r, lessThan(60));
    });

    test('returns null for a zero-sized canvas', () {
      final bytes = _solidPng(10, 10, img.ColorRgb8(1, 2, 3));
      expect(
        musamiRenderCoverBackground(
          imageBytes: bytes,
          canvasSize: Size.zero,
        ),
        isNull,
      );
    });

    test('returns null for undecodable bytes', () {
      expect(
        musamiRenderCoverBackground(
          imageBytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          canvasSize: const Size(100, 100),
        ),
        isNull,
      );
    });
  });

  group('musamiExtractDominantColors', () {
    test('finds both bands of a two-tone image', () {
      final palette = musamiExtractDominantColors(_twoTonePng(120, 120));

      expect(palette.length, greaterThanOrEqualTo(2));
      final hasRed = palette.any((c) => c.r > 0.7 && c.b < 0.4);
      final hasBlue = palette.any((c) => c.b > 0.6 && c.r < 0.4);
      expect(hasRed, isTrue);
      expect(hasBlue, isTrue);
    });

    test('collapses a solid image to a single swatch', () {
      final palette = musamiExtractDominantColors(
        _solidPng(64, 64, img.ColorRgb8(12, 200, 90)),
      );

      expect(palette, hasLength(1));
      expect((palette.single.g * 255).round(), closeTo(200, 6));
    });

    test('never returns more than the requested count', () {
      final noise = img.Image(width: 64, height: 64);
      for (var y = 0; y < noise.height; y++) {
        for (var x = 0; x < noise.width; x++) {
          noise.setPixelRgb(x, y, x * 4 % 256, y * 4 % 256, (x + y) % 256);
        }
      }
      final palette = musamiExtractDominantColors(
        Uint8List.fromList(img.encodePng(noise)),
        maxColors: 4,
      );

      expect(palette.length, lessThanOrEqualTo(4));
    });

    test('returns nothing for undecodable bytes', () {
      expect(
        musamiExtractDominantColors(Uint8List.fromList(<int>[9, 9, 9])),
        isEmpty,
      );
    });
  });
}
