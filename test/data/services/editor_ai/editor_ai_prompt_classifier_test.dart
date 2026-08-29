import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/services/editor_ai/editor_ai_prompt_classifier.dart';

void main() {
  group('AI prompt classification', () {
    test('routes detailed templates to editable design generation', () {
      const prompt =
          'A professional LinkedIn banner template with a modern layout, '
          'text placeholders, a photo, and icons arranged on the right side.';

      expect(isEditableDesignPrompt(prompt), isTrue);
      expect(looksLikeStandaloneImagePrompt(prompt), isTrue);
    });

    test('routes a single requested subject to sticker generation', () {
      const prompt = 'Add a burger image to the canvas';

      expect(isEditableDesignPrompt(prompt), isFalse);
      expect(looksLikeStandaloneImagePrompt(prompt), isTrue);
      expect(looksLikeBackgroundImagePrompt(prompt), isFalse);
    });

    test('recognizes an explicit canvas background request', () {
      const prompt = 'Generate a city photo as the canvas background';

      expect(looksLikeStandaloneImagePrompt(prompt), isTrue);
      expect(looksLikeBackgroundImagePrompt(prompt), isTrue);
    });

    test('does not classify long text by length alone', () {
      final prompt = List.filled(
        30,
        'Make the selected heading slightly darker and move it left.',
      ).join(' ');

      expect(isEditableDesignPrompt(prompt), isFalse);
      expect(looksLikeStandaloneImagePrompt(prompt), isFalse);
    });
  });
}
