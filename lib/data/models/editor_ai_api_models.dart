import 'dart:convert';
import 'dart:typed_data';

class AiMessage {
  const AiMessage({required this.role, required this.content});

  final String role;

  /// Plain text [String], or multimodal OpenAI parts ([List] of maps).
  final Object content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory AiMessage.system(String text) =>
      AiMessage(role: 'system', content: text);

  factory AiMessage.user(String text) => AiMessage(role: 'user', content: text);

  factory AiMessage.assistant(String text) =>
      AiMessage(role: 'assistant', content: text);

  /// ChatGPT vision-style user turn (one compressed data-URL image + prompt).
  factory AiMessage.userWithImage({
    required String text,
    required String imageDataUrl,
  }) {
    return AiMessage(
      role: 'user',
      content: [
        {'type': 'text', 'text': text},
        {
          'type': 'image_url',
          'image_url': {'url': imageDataUrl},
        },
      ],
    );
  }
}

class OpenAiEditorRequest {
  const OpenAiEditorRequest({required this.messages, this.responseFormat});

  final List<AiMessage> messages;
  final Map<String, dynamic>? responseFormat;

  Map<String, dynamic> toJson() => {
    'messages': messages.map((message) => message.toJson()).toList(),
    if (responseFormat != null) 'response_format': responseFormat,
  };
}

class OpenAiEditorResponse {
  const OpenAiEditorResponse({required this.content});

  final String content;

  factory OpenAiEditorResponse.fromJson(Map<String, dynamic> json) {
    final choices = json['choices'];
    final choice = choices is List && choices.isNotEmpty ? choices.first : null;
    final message = choice is Map ? choice['message'] : null;
    final content = message is Map ? message['content']?.toString() : null;
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('Missing AI editor response content');
    }
    return OpenAiEditorResponse(content: content);
  }
}

class OpenAiImageRequest {
  OpenAiImageRequest({
    required this.prompt,
    this.count = 1,
    this.size = '1024x1024',
    this.quality = 'medium',
    this.background = 'opaque',
  }) {
    if (!allowedSizes.contains(size)) {
      throw ArgumentError.value(size, 'size', 'Unsupported image size');
    }
    if (!allowedQualities.contains(quality)) {
      throw ArgumentError.value(
        quality,
        'quality',
        'Unsupported image quality',
      );
    }
    if (!allowedBackgrounds.contains(background)) {
      throw ArgumentError.value(
        background,
        'background',
        'Unsupported image background',
      );
    }
  }

  static const Set<String> allowedSizes = {'1024x1024', '1536x1024'};
  static const Set<String> allowedQualities = {'low', 'medium', 'high'};
  static const Set<String> allowedBackgrounds = {'opaque', 'transparent'};

  final String prompt;
  final int count;
  final String size;
  final String quality;
  final String background;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'n': count,
    'size': size,
    'quality': quality,
    'background': background,
  };
}

class GeneratedAiAsset {
  const GeneratedAiAsset({
    required this.id,
    this.url,
    this.base64Json,
    this.mimeType,
    this.width,
    this.height,
  });

  final String id;
  final String? url;
  final String? base64Json;
  final String? mimeType;
  final int? width;
  final int? height;

  Uint8List? decodeBytes() {
    final encoded = base64Json;
    if (encoded == null || encoded.isEmpty) return null;
    return base64Decode(encoded);
  }

  factory GeneratedAiAsset.fromJson(Map<String, dynamic> json) {
    final id = json['asset_id']?.toString() ?? json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const FormatException('Generated image asset_id is missing');
    }
    return GeneratedAiAsset(
      id: id,
      url: _nonEmptyString(json['url']),
      base64Json: _nonEmptyString(json['b64_json']),
      mimeType: _nonEmptyString(json['mime_type']),
      width: _nullableInt(json['width']),
      height: _nullableInt(json['height']),
    );
  }

  static String? _nonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class OpenAiImageResponse {
  const OpenAiImageResponse({required this.assets});

  final List<GeneratedAiAsset> assets;

  factory OpenAiImageResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is! List) {
      throw const FormatException('Generated image response data is missing');
    }
    final assets = raw
        .whereType<Map>()
        .map(
          (asset) =>
              GeneratedAiAsset.fromJson(Map<String, dynamic>.from(asset)),
        )
        .toList(growable: false);
    if (assets.isEmpty) {
      throw const FormatException('Generated image response is empty');
    }
    return OpenAiImageResponse(assets: assets);
  }
}

class GeminiEditorRequest {
  const GeminiEditorRequest({
    required this.contents,
    required this.generationConfig,
  });

  final List<Map<String, dynamic>> contents;
  final Map<String, dynamic> generationConfig;

  Map<String, dynamic> toJson() => {
    'contents': contents,
    'generationConfig': generationConfig,
  };
}

class GeminiEditorResponse {
  const GeminiEditorResponse({required this.content});

  final String content;

  factory GeminiEditorResponse.fromJson(Map<String, dynamic> json) {
    final candidates = json['candidates'];
    final candidate = candidates is List && candidates.isNotEmpty
        ? candidates.first
        : null;
    final contentMap = candidate is Map ? candidate['content'] : null;
    final parts = contentMap is Map ? contentMap['parts'] : null;
    final part = parts is List && parts.isNotEmpty ? parts.first : null;
    final text = part is Map ? part['text']?.toString() : null;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('Missing Gemini candidate content');
    }
    return GeminiEditorResponse(content: text);
  }
}
