import 'dart:math' as math;

enum EditorAiCompositionElementType { text, image, icon, shape }

enum EditorAiCompositionClip { none, circle }

enum EditorAiCompositionShape { rectangle, circle, line }

class EditorAiComposition {
  EditorAiComposition({required this.elements});

  static const int maxElements = 40;
  static const int maxImageAssets = 4;

  final List<EditorAiCompositionElement> elements;

  factory EditorAiComposition.fromMap(Map<String, dynamic> map) {
    final rawElements = map['elements'];
    if (rawElements is! List || rawElements.isEmpty) {
      throw const FormatException('Composition has no elements');
    }
    if (rawElements.length > maxElements) {
      throw const FormatException('Composition has too many elements');
    }

    final elements = <EditorAiCompositionElement>[];
    for (var index = 0; index < rawElements.length; index++) {
      final raw = rawElements[index];
      if (raw is! Map) {
        throw FormatException('Element $index is not an object');
      }
      elements.add(
        EditorAiCompositionElement.fromMap(
          Map<String, dynamic>.from(raw),
          fallbackZIndex: index,
        ),
      );
    }

    final imagePrompts = <String, String>{};
    for (final element in elements.where(
      (element) => element.type == EditorAiCompositionElementType.image,
    )) {
      final previousPrompt = imagePrompts[element.assetId];
      if (previousPrompt != null && previousPrompt != element.imagePrompt) {
        throw FormatException(
          'Image asset ${element.assetId} has conflicting prompts',
        );
      }
      imagePrompts[element.assetId!] = element.imagePrompt!;
    }
    if (imagePrompts.length > maxImageAssets) {
      throw const FormatException('Composition requests too many images');
    }

    elements.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return EditorAiComposition(elements: List.unmodifiable(elements));
  }
}

class EditorAiCompositionElement {
  const EditorAiCompositionElement({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zIndex,
    this.text,
    this.fontSize,
    this.fontWeight,
    this.align,
    this.color,
    this.backgroundColor,
    this.assetId,
    this.imagePrompt,
    this.clip = EditorAiCompositionClip.none,
    this.icon,
    this.shape,
    this.strokeWidth,
    this.fill = true,
  });

  final EditorAiCompositionElementType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final int zIndex;

  final String? text;
  final double? fontSize;
  final int? fontWeight;
  final String? align;
  final int? color;
  final int? backgroundColor;

  final String? assetId;
  final String? imagePrompt;
  final EditorAiCompositionClip clip;

  final String? icon;

  final EditorAiCompositionShape? shape;
  final double? strokeWidth;
  final bool fill;

  factory EditorAiCompositionElement.fromMap(
    Map<String, dynamic> map, {
    required int fallbackZIndex,
  }) {
    final type = _parseType(map['type']);
    final x = _normalized(map['x'], 'x');
    final y = _normalized(map['y'], 'y');
    final width = _normalizedSize(map['width'], 'width');
    final height = _normalizedSize(map['height'], 'height');
    final zIndex = (map['zIndex'] as num?)?.toInt() ?? fallbackZIndex;
    final color = _parseColor(map['color'], fallback: 0xFF222222);
    final backgroundColor = _parseColor(
      map['backgroundColor'],
      fallback: 0x00000000,
    );

    switch (type) {
      case EditorAiCompositionElementType.text:
        final text = map['text']?.toString().trim() ?? '';
        if (text.isEmpty || text.length > 500) {
          throw const FormatException('Text element is empty or too long');
        }
        return EditorAiCompositionElement(
          type: type,
          x: x,
          y: y,
          width: width,
          height: height,
          zIndex: zIndex,
          text: text,
          fontSize: _range(
            map['fontSize'],
            fallback: 0.045,
            min: 0.012,
            max: 0.25,
          ),
          fontWeight: ((map['fontWeight'] as num?)?.toInt() ?? 400).clamp(
            100,
            900,
          ),
          align: _parseAlign(map['align']),
          color: color,
          backgroundColor: backgroundColor,
        );
      case EditorAiCompositionElementType.image:
        final assetId = map['assetId']?.toString().trim() ?? '';
        final prompt = map['prompt']?.toString().trim() ?? '';
        if (assetId.isEmpty || prompt.isEmpty || prompt.length > 1000) {
          throw const FormatException('Image element is missing asset details');
        }
        return EditorAiCompositionElement(
          type: type,
          x: x,
          y: y,
          width: width,
          height: height,
          zIndex: zIndex,
          assetId: assetId,
          imagePrompt: prompt,
          clip: map['clip']?.toString() == 'circle'
              ? EditorAiCompositionClip.circle
              : EditorAiCompositionClip.none,
        );
      case EditorAiCompositionElementType.icon:
        final icon = map['icon']?.toString().trim().toLowerCase() ?? '';
        if (!supportedEditorAiIcons.contains(icon)) {
          throw FormatException('Unsupported icon: $icon');
        }
        return EditorAiCompositionElement(
          type: type,
          x: x,
          y: y,
          width: width,
          height: height,
          zIndex: zIndex,
          icon: icon,
          color: color,
          backgroundColor: backgroundColor,
        );
      case EditorAiCompositionElementType.shape:
        final shape = _parseShape(map['shape']);
        return EditorAiCompositionElement(
          type: type,
          x: x,
          y: y,
          width: width,
          height: height,
          zIndex: zIndex,
          shape: shape,
          color: color,
          strokeWidth: _range(
            map['strokeWidth'],
            fallback: 0.006,
            min: 0.001,
            max: 0.1,
          ),
          fill: map['fill'] as bool? ?? shape != EditorAiCompositionShape.line,
        );
    }
  }

  static EditorAiCompositionElementType _parseType(dynamic raw) {
    return switch (raw?.toString()) {
      'text' => EditorAiCompositionElementType.text,
      'image' => EditorAiCompositionElementType.image,
      'icon' => EditorAiCompositionElementType.icon,
      'shape' => EditorAiCompositionElementType.shape,
      _ => throw FormatException('Unsupported element type: $raw'),
    };
  }

  static EditorAiCompositionShape _parseShape(dynamic raw) {
    return switch (raw?.toString()) {
      'rectangle' => EditorAiCompositionShape.rectangle,
      'circle' => EditorAiCompositionShape.circle,
      'line' => EditorAiCompositionShape.line,
      _ => throw FormatException('Unsupported shape: $raw'),
    };
  }

  static String _parseAlign(dynamic raw) {
    final value = raw?.toString();
    return value == 'center' || value == 'right' ? value! : 'left';
  }

  static double _normalized(dynamic raw, String field) {
    final value = (raw as num?)?.toDouble();
    if (value == null || !value.isFinite || value < 0 || value > 1) {
      throw FormatException('$field must be between 0 and 1');
    }
    return value;
  }

  static double _normalizedSize(dynamic raw, String field) {
    final value = _normalized(raw, field);
    if (value <= 0) throw FormatException('$field must be greater than zero');
    return value;
  }

  static double _range(
    dynamic raw, {
    required double fallback,
    required double min,
    required double max,
  }) {
    final value = (raw as num?)?.toDouble() ?? fallback;
    if (!value.isFinite) return fallback;
    return math.max(min, math.min(max, value));
  }

  static int _parseColor(dynamic raw, {required int fallback}) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final value = raw.replaceFirst('#', '');
      final parsed = int.tryParse(value, radix: 16);
      if (parsed != null) {
        return value.length <= 6 ? 0xFF000000 | parsed : parsed;
      }
    }
    return fallback;
  }
}

const Set<String> supportedEditorAiIcons = {
  'home',
  'email',
  'user',
  'phone',
  'location',
  'website',
  'calendar',
  'star',
  'check',
  'arrow',
};
