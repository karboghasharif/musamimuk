import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/design_pack_models.dart';
import 'package:musamimuk/data/services/design_pack_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesignPackCatalog.resolveAssetPath', () {
    test('keeps full assets/ paths', () {
      expect(
        DesignPackCatalog.resolveAssetPath(
          'assets/assets/borders/files/border-1.svg',
        ),
        'assets/assets/borders/files/border-1.svg',
      );
    });

    test('prefixes relative pack paths', () {
      expect(
        DesignPackCatalog.resolveAssetPath('borders/files/border-1.svg'),
        'assets/assets/borders/files/border-1.svg',
      );
    });

    test('returns null for empty / whitespace', () {
      expect(DesignPackCatalog.resolveAssetPath(null), isNull);
      expect(DesignPackCatalog.resolveAssetPath(''), isNull);
      expect(DesignPackCatalog.resolveAssetPath('   '), isNull);
    });
  });

  group('DesignPackCatalog.parseBordersManifest', () {
    test('builds asset + thumb paths from root', () {
      final items = DesignPackCatalog.parseBordersManifest(
        jsonEncode({
          'root': 'assets/assets/borders',
          'items': [
            {
              'id': 'border-1',
              'file': 'files/border-1.svg',
              'name': 'border 1',
              'thumb': 'thumbs/thumb.border-1.png',
            },
            {
              'id': 'skip',
              'file': '',
            },
          ],
        }),
      );
      expect(items, hasLength(1));
      expect(items.first.assetPath,
          'assets/assets/borders/files/border-1.svg');
      expect(items.first.thumbPath,
          'assets/assets/borders/thumbs/thumb.border-1.png');
      expect(items.first.layerKind, 'design_pack_border');
    });

    test('handles missing items list', () {
      expect(
        DesignPackCatalog.parseBordersManifest('{"root":"x"}'),
        isEmpty,
      );
    });
  });

  group('DesignPackCatalog.parseSvgSection', () {
    final manifest = <String, dynamic>{
      'shapes': {
        'basic': ['circle.svg', 'square.svg'],
        'labels': ['tag.svg'],
      },
      'specialtext': {
        'allah': ['allah-1.svg'],
      },
      'emoji': {
        '': ['smile.svg'],
      },
    };

    test('filters by subcategory', () {
      final items = DesignPackCatalog.parseSvgSection(
        manifest,
        section: 'shapes',
        subcategory: 'basic',
      );
      expect(items, hasLength(2));
      expect(
        items.first.assetPath,
        'assets/assets/shapes/basic/circle.svg',
      );
      expect(items.first.subcategory, 'basic');
      expect(items.first.layerKind, 'design_pack_shape');
    });

    test('missing section / subcategory yields empty', () {
      expect(
        DesignPackCatalog.parseSvgSection(
          manifest,
          section: 'shapes',
          subcategory: 'nope',
        ),
        isEmpty,
      );
      expect(
        DesignPackCatalog.parseSvgSection(
          const {},
          section: 'shapes',
        ),
        isEmpty,
      );
    });

    test('specialtext + emoji paths', () {
      final motifs = DesignPackCatalog.parseSvgSection(
        manifest,
        section: 'specialtext',
        subcategory: 'allah',
      );
      expect(
        motifs.single.assetPath,
        'assets/assets/specialtext/allah/allah-1.svg',
      );
      expect(motifs.single.layerKind, 'design_pack_specialtext');

      final emoji = DesignPackCatalog.parseSvgSection(
        manifest,
        section: 'emoji',
        subcategory: '',
      );
      expect(emoji.single.assetPath, 'assets/assets/emoji/smile.svg');
      expect(emoji.single.layerKind, 'design_pack_emoji');
    });
  });

  group('DesignPackCatalog.ensureLoaded (bundled assets)', () {
    tearDown(() {
      DesignPackCatalog.instance.debugReset();
    });

    test('loads real borders / shapes / specialtext indexes', () async {
      final catalog = DesignPackCatalog.instance;
      await catalog.ensureLoaded();
      final borders = catalog.items(category: DesignPackCategory.borders);
      expect(borders, isNotEmpty);
      expect(borders.first.assetPath.startsWith('assets/assets/borders/'),
          isTrue);

      final shapeSubs = catalog.subcategories(DesignPackCategory.shapes);
      expect(shapeSubs, contains('basic'));
      final shapes = catalog.items(
        category: DesignPackCategory.shapes,
        subcategory: 'basic',
      );
      expect(shapes, isNotEmpty);
      expect(shapes.first.assetPath.contains('/shapes/basic/'), isTrue);
      expect(shapes.first.assetPath.contains(' '), isFalse);

      final specialSubs =
          catalog.subcategories(DesignPackCategory.specialtext);
      expect(specialSubs, contains('aaraab'));
      final special = catalog.items(
        category: DesignPackCategory.specialtext,
        subcategory: 'aaraab',
      );
      expect(special, isNotEmpty);
      expect(special.first.assetPath.contains('/specialtext/aaraab/'), isTrue);
      expect(special.first.assetPath.contains(' '), isFalse);
    });
  });
}
