import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/presentation/add_new_screen/utils/musami_layer_clipboard.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

WidgetLayer _imageLayer() {
  return WidgetLayer(
    widget: const SizedBox(width: 200, height: 100),
    width: 200,
    scale: 1.5,
    rotation: 0.3,
    flipX: true,
    offset: const Offset(100, 100),
    meta: <String, dynamic>{
      'musamiLayerKind': 'gallery',
      'musamiAspect': 0.5,
      'musamiImageAspect': 0.75,
    },
  );
}

TextLayer _textLayer() {
  return TextLayer(
    text: 'Hello',
    offset: const Offset(40, 60),
    scale: 2,
    fontScale: 1.2,
    meta: <String, dynamic>{'musami_text_outline_w': 3.0},
  );
}

void main() {
  setUp(MusamiLayerClipboard.instance.clear);

  group('musamiCloneLayer', () {
    test('gives the copy a new identity but the same visual state', () {
      final source = _imageLayer();
      final copy = musamiCloneLayer(source, nudge: const Offset(20, 20));

      expect(copy, isA<WidgetLayer>());
      copy as WidgetLayer;
      expect(copy.id, isNot(source.id));
      expect(copy.key, isNot(same(source.key)));
      expect(copy.offset, const Offset(120, 120));
      expect(copy.width, source.width);
      expect(copy.scale, source.scale);
      expect(copy.rotation, source.rotation);
      expect(copy.flipX, source.flipX);
      expect(copy.flipY, source.flipY);
    });

    test('does not share the meta map with the source', () {
      final source = _imageLayer();
      final copy = musamiCloneLayer(source)!;

      copy.meta!['musamiAspect'] = 9.0;

      expect(source.meta!['musamiAspect'], 0.5);
      expect(copy.meta!['musamiImageAspect'], 0.75);
    });

    test('copies every styling field of a text layer', () {
      final source = _textLayer();
      final copy = musamiCloneLayer(source, nudge: const Offset(12, 12));

      expect(copy, isA<TextLayer>());
      copy as TextLayer;
      expect(copy.text, 'Hello');
      expect(copy.offset, const Offset(52, 72));
      expect(copy.fontScale, source.fontScale);
      expect(copy.scale, source.scale);
      expect(copy.meta!['musami_text_outline_w'], 3.0);
      expect(copy.id, isNot(source.id));
    });
  });

  group('MusamiLayerClipboard', () {
    test('starts empty', () {
      expect(MusamiLayerClipboard.instance.hasContent, isFalse);
      expect(MusamiLayerClipboard.instance.read(), isNull);
    });

    test('stores a detached copy, so later edits do not leak in', () {
      final source = _imageLayer();
      MusamiLayerClipboard.instance.copy(source);

      source.meta!['musamiAspect'] = 4.0;
      source.offset = const Offset(999, 999);

      final pasted = MusamiLayerClipboard.instance.read()!;
      expect(pasted.meta!['musamiAspect'], 0.5);
      expect(pasted.offset, const Offset(120, 120));
    });

    test('every paste yields an independent layer', () {
      MusamiLayerClipboard.instance.copy(_imageLayer());

      final first = MusamiLayerClipboard.instance.read()!;
      final second = MusamiLayerClipboard.instance.read()!;

      expect(first.id, isNot(second.id));
      expect(identical(first.meta, second.meta), isFalse);
      // Both are nudged off the original, not off each other.
      expect(first.offset, second.offset);
    });

    test('clear empties the clipboard', () {
      MusamiLayerClipboard.instance.copy(_textLayer());
      expect(MusamiLayerClipboard.instance.hasContent, isTrue);

      MusamiLayerClipboard.instance.clear();
      expect(MusamiLayerClipboard.instance.hasContent, isFalse);
    });
  });
}
