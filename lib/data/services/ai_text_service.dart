import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/config/ai_debug_config.dart';

enum AiTextProvider { gemini, groq }

/// Debug client for Groq + Gemini text tasks (translate, rewrite, suggestions).
class AiTextService {
  AiTextService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 45),
              ),
            );

  final Dio _dio;

  static const String _groqChatUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel = 'llama-3.3-70b-versatile';

  /// `gemini-2.0-flash` may hit quota 0 on some accounts; `gemini-flash-latest` works.
  static const String _geminiModel = 'gemini-flash-latest';
  static String get _geminiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

  Future<String> translate({
    required String text,
    required String targetLang,
    String? sourceLang,
    bool withArabicTashkeela = false,
  }) async {
    final sourceRule = sourceLang != null && sourceLang.trim().isNotEmpty
        ? 'The source language is $sourceLang.'
        : 'Detect the source language automatically.';

    final tashkeelaRule = withArabicTashkeela
        ? '''
- Write Arabic with full tashkeela (harakat) on every word.
- Use fatha (َ), kasra (ِ), damma (ُ), sukun (ْ), shadda (ّ), and tanwin (ً ٍ ٌ) where appropriate.
- Do not omit vowel marks — output must be fully vocalized for correct pronunciation.
'''
        : '';

    final prompt = '''
$sourceRule
Translate the following text into $targetLang.
Rules:
- Return ONLY the translated text in the correct $targetLang script.
- No quotes, labels, markdown, or explanation.
- Preserve emojis and intentional line breaks when appropriate.
- Keep meaning natural for social/design captions.
$tashkeelaRule- Maximum ${text.length + 80} characters.

Text:
$text''';

    var result = await _geminiTranslate(
      system:
          'You are a professional multilingual translator for design and social media copy. Output only the translation.',
      user: prompt,
    );

    if (withArabicTashkeela && !hasArabicTashkeela(result)) {
      result = await applyArabicTashkeela(result);
    }
    return result;
  }

  /// Adds harakat/tashkeela to unvocalized Arabic (e.g. after offline fallback).
  Future<String> applyArabicTashkeela(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;

    final prompt = '''
Add full Arabic tashkeela (harakat) to every word in the text below.
Rules:
- Use fatha (َ), kasra (ِ), damma (ُ), sukun (ْ), shadda (ّ), tanwin (ً ٍ ٌ), and maddah (ٓ) where appropriate.
- Return ONLY the fully vocalized Arabic text.
- Do not change words, meaning, or word order.
- No quotes, labels, or explanation.
- Maximum ${trimmed.length + 120} characters.

Text:
$trimmed''';

    return _geminiTranslate(
      system:
          'You are an expert in Arabic orthography and tashkeela for social media and design copy. Output only vocalized Arabic.',
      user: prompt,
    );
  }

  /// True if the string contains common Arabic harakat marks.
  static bool hasArabicTashkeela(String text) {
    const marks = r'[\u064B-\u065F\u0670\u06D6-\u06ED]';
    return RegExp(marks).hasMatch(text);
  }

  /// Translation uses Gemini only — no Groq fallback.
  Future<String> _geminiTranslate({
    required String system,
    required String user,
  }) async {
    if (!AiDebugConfig.hasGemini) {
      throw AiTextException('Gemini API key is not configured.');
    }
    try {
      return await _geminiComplete(system: system, user: user);
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorMessage(e, AiTextProvider.gemini)
          : e.toString();
      throw AiTextException(msg);
    }
  }

  Future<String> beautify({
    required String text,
    required String languageLabel,
  }) async {
    final prompt = '''
Improve this $languageLabel design caption for clarity and polish.
Rules:
- Fix grammar, spacing, and punctuation.
- Keep the same language ($languageLabel).
- Do not add new ideas — only refine wording.
- Return ONLY the improved text.
- Maximum 250 characters.

Text:
$text''';
    return _complete(
      system: 'You are a copy editor for short design text.',
      user: prompt,
      prefer: AiTextProvider.groq,
    );
  }

  Future<List<String>> captionSuggestions({
    required String languageLabel,
    String? seed,
    String? theme,
  }) async {
    final seedText = (seed != null && seed.trim().isNotEmpty)
        ? seed.trim()
        : 'none';
    final themeText = (theme != null && theme.trim().isNotEmpty)
        ? theme.trim()
        : 'general';

    final prompt = '''
Generate exactly 6 short caption ideas for a design.

Language: $languageLabel
Theme: $themeText
User hint: $seedText

Rules:
- Each caption max 60 characters.
- Write in native $languageLabel script only (Urdu in Urdu script, not Roman Urdu).
- Suitable for overlay text on posters, flyers, and social graphics.
- Culturally appropriate for South Asian and Muslim audiences.
- Mix styles: headline, CTA, emotional, minimal.
- Return ONLY a JSON array of 6 strings.
Example: ["Flash Sale 50% Off!","Shop Now — Limited Time"]
''';

    final raw = await _complete(
      system:
          'You are a creative copywriter for Musamimuk, a graphic design app. Output valid JSON only.',
      user: prompt,
      prefer: AiTextProvider.groq,
      jsonMode: true,
    );

    return _parseSuggestionList(raw);
  }

  Future<String> shorten({
    required String text,
    required String languageLabel,
  }) async {
    final prompt = '''
Shorten this design caption without losing the main message.
Language: $languageLabel
Target max length: 250 characters (strict).
Text: $text
Rules: Return ONLY shortened text. No explanation.
''';
    return _complete(
      system: 'You are a copy editor for short design text. Return only the shortened text.',
      user: prompt,
      prefer: AiTextProvider.groq,
    );
  }

  Future<String> makePunchy({
    required String text,
    required String languageLabel,
  }) async {
    final prompt = '''
Make this caption more punchy and action-oriented for a poster/social design.
Language: $languageLabel
Max 250 characters.
Text: $text
Rules: Add urgency/CTA if natural. Same language. Return ONLY improved text.
''';
    return _complete(
      system:
          'You are a marketing copywriter for visual design text. Return only the improved text.',
      user: prompt,
      prefer: AiTextProvider.groq,
    );
  }

  Future<String> _complete({
    required String system,
    required String user,
    required AiTextProvider prefer,
    bool jsonMode = false,
  }) async {
    final errors = <String>[];

    final order = prefer == AiTextProvider.gemini
        ? [AiTextProvider.gemini, AiTextProvider.groq]
        : [AiTextProvider.groq, AiTextProvider.gemini];

    for (final provider in order) {
      try {
        switch (provider) {
          case AiTextProvider.gemini:
            if (!AiDebugConfig.hasGemini) continue;
            return await _geminiComplete(
              system: system,
              user: user,
              jsonMode: jsonMode,
            );
          case AiTextProvider.groq:
            if (!AiDebugConfig.hasGroq) continue;
            return await _groqComplete(system: system, user: user);
        }
      } catch (e) {
        final msg = e is DioException
            ? _dioErrorMessage(e, provider)
            : e.toString();
        errors.add('${provider.name}: $msg');
      }
    }

    if (!AiDebugConfig.isConfigured) {
      throw AiTextException('AI keys are not configured.');
    }
    throw AiTextException(errors.join(' | '));
  }

  /// Public entry for JSON / structured Groq tasks (design assistant, etc.).
  Future<String> completeRaw({
    required String system,
    required String user,
    required AiTextProvider prefer,
    bool jsonMode = false,
  }) {
    return _complete(
      system: system,
      user: user,
      prefer: prefer,
      jsonMode: jsonMode,
    );
  }

  Future<String> _groqComplete({
    required String system,
    required String user,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _groqChatUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AiDebugConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: <String, dynamic>{
        'model': _groqModel,
        'temperature': 0.4,
        'max_tokens': 512,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      },
    );

    final data = response.data;
    final content = data?['choices']?[0]?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw AiTextException('Groq returned an empty response.');
    }
    return content.trim();
  }

  Future<String> _geminiComplete({
    required String system,
    required String user,
    bool jsonMode = false,
  }) async {
    final generationConfig = <String, dynamic>{
      'temperature': 0.4,
      'maxOutputTokens': 512,
      if (jsonMode) 'responseMimeType': 'application/json',
    };

    final response = await _dio.post<Map<String, dynamic>>(
      _geminiUrl,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': AiDebugConfig.geminiApiKey,
        },
      ),
      data: <String, dynamic>{
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': user},
            ],
          },
        ],
        'generationConfig': generationConfig,
      },
    );

    final data = response.data;
    final parts = data?['candidates']?[0]?['content']?['parts'];
    if (parts is! List || parts.isEmpty) {
      throw AiTextException('Gemini returned an empty response.');
    }
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw AiTextException('Gemini returned an empty response.');
    }
    return text;
  }

  String _dioErrorMessage(DioException e, AiTextProvider provider) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      final message = err['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return e.message ?? 'Network error (${provider.name})';
  }

  List<String> _parseSuggestionList(String raw) {
    final trimmed = raw.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .take(6)
            .toList();
      }
    } catch (_) {}

    return trimmed
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.replaceAll(RegExp(r'^[\d\.\-\*\s]+'), '').trim())
        .where((s) => s.isNotEmpty)
        .take(6)
        .toList();
  }
}

class AiTextException implements Exception {
  AiTextException(this.message);
  final String message;

  @override
  String toString() => message;
}
