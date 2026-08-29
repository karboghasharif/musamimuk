import 'package:flutter/material.dart';

/// Writing actions offered inside the ProImageEditor text editor.
enum EditorAiTextWritingAction {
  generate,
  rewrite,
  fixSpelling,
  shorten,
  expand,
  translateArabic,
  translateEnglish,
  professionalTone,
  friendlyTone,
}

/// Resolved source span for an AI write request.
class EditorAiTextWriteSource {
  const EditorAiTextWriteSource({
    required this.text,
    required this.start,
    required this.end,
    required this.isPartialSelection,
  });

  final String text;
  final int start;
  final int end;
  final bool isPartialSelection;
}

/// Uses a non-empty selection when valid; otherwise the full controller text.
EditorAiTextWriteSource resolveAiTextWriteSource(TextEditingValue value) {
  final text = value.text;
  final selection = value.selection;
  if (selection.isValid &&
      !selection.isCollapsed &&
      selection.start >= 0 &&
      selection.end <= text.length &&
      selection.start < selection.end) {
    return EditorAiTextWriteSource(
      text: text.substring(selection.start, selection.end),
      start: selection.start,
      end: selection.end,
      isPartialSelection: true,
    );
  }
  return EditorAiTextWriteSource(
    text: text,
    start: 0,
    end: text.length,
    isPartialSelection: false,
  );
}

/// Replaces [start, end) with [result] while preserving a sensible selection.
TextEditingValue applyAiTextWriteResult({
  required TextEditingValue current,
  required String result,
  required int start,
  required int end,
  required bool isPartialSelection,
}) {
  final safeStart = start.clamp(0, current.text.length);
  final safeEnd = end.clamp(safeStart, current.text.length);
  final newText = current.text.replaceRange(safeStart, safeEnd, result);

  if (isPartialSelection) {
    return TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: safeStart,
        extentOffset: safeStart + result.length,
      ),
      composing: TextRange.empty,
    );
  }

  final previousCursor = current.selection.isValid
      ? current.selection.extentOffset
      : result.length;
  final cursor = previousCursor.clamp(0, result.length);
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: cursor),
    composing: TextRange.empty,
  );
}

/// Strips fences, quotes, and common wrapper phrasing so only plain text remains.
String sanitizeAiPlainText(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return text;

  if (text.startsWith('```')) {
    final firstNl = text.indexOf('\n');
    if (firstNl != -1) {
      text = text.substring(firstNl + 1);
    } else {
      text = text.replaceFirst(RegExp(r'^```\w*'), '');
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
  }

  // Strip a single wrapping quote pair when the whole payload is quoted.
  if ((text.startsWith('"') && text.endsWith('"')) ||
      (text.startsWith("'") && text.endsWith("'")) ||
      (text.startsWith('“') && text.endsWith('”')) ||
      (text.startsWith('«') && text.endsWith('»'))) {
    if (text.length >= 2) {
      text = text.substring(1, text.length - 1).trim();
    }
  }

  return text;
}

/// True when Arabic letters dominate Latin letters (for RTL/LTR chrome).
bool looksPrimarilyArabicScript(String text) {
  var arabic = 0;
  var latin = 0;
  for (final code in text.runes) {
    if ((code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFF)) {
      arabic++;
    } else if ((code >= 0x0041 && code <= 0x005A) ||
        (code >= 0x0061 && code <= 0x007A)) {
      latin++;
    }
  }
  if (arabic == 0 && latin == 0) return false;
  return arabic > latin;
}

String editorAiTextWritingSystemPrompt(EditorAiTextWritingAction action) {
  final actionLine = switch (action) {
    EditorAiTextWritingAction.generate =>
      'Generate clear design-ready text from the user prompt.',
    EditorAiTextWritingAction.rewrite =>
      'Rewrite the source text with clearer wording. Keep the same language and meaning.',
    EditorAiTextWritingAction.fixSpelling =>
      'Fix spelling and grammar only. Keep the same language, tone, and meaning.',
    EditorAiTextWritingAction.shorten =>
      'Shorten the source text. Keep the same language and core meaning.',
    EditorAiTextWritingAction.expand =>
      'Expand the source text with useful detail. Keep the same language and meaning.',
    EditorAiTextWritingAction.translateArabic =>
      'Translate the source text into Arabic.',
    EditorAiTextWritingAction.translateEnglish =>
      'Translate the source text into English.',
    EditorAiTextWritingAction.professionalTone =>
      'Rewrite in a professional tone. Keep the same language and meaning.',
    EditorAiTextWritingAction.friendlyTone =>
      'Rewrite in a friendly tone. Keep the same language and meaning.',
  };

  return '''
You are Musamimuk writing assistance for design text.
Task: $actionLine

Rules:
- Reply with plain text only.
- Do not return JSON, Markdown, bullet labels, code fences, quotes around the whole answer, or explanations.
- Preserve line breaks where they matter.
- Preserve meaning.
- Never translate brand names unless the user explicitly asks to translate them.
- Preserve the source language unless the task is an explicit translation.
- Support Arabic and English naturally.
''';
}

String editorAiTextWritingUserPrompt({
  required EditorAiTextWritingAction action,
  required String sourceText,
  String? generatePrompt,
}) {
  if (action == EditorAiTextWritingAction.generate) {
    return 'Prompt:\n${generatePrompt ?? ''}';
  }
  return 'Source text:\n$sourceText';
}
