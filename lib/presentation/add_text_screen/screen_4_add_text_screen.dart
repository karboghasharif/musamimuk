import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import 'bloc/screen_4_add_text_bloc.dart';
import 'models/add_text_input_language.dart';
import 'models/screen_4_add_text_model.dart';
import 'widgets/urdu_marks_strip.dart';

/// Maximum characters allowed in the Add Text field.
const int kAddTextMaxLength = 250;

Widget? _addTextHideCounter(
  BuildContext context, {
  required int currentLength,
  required int? maxLength,
  required bool isFocused,
}) => const SizedBox.shrink();

class Screen4AddTextScreen extends StatelessWidget {
  const Screen4AddTextScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<Screen4AddTextBloc>(
      create: (context) => Screen4AddTextBloc(
        Screen4AddTextState(
          screen4AddTextModelObj: const Screen4AddTextModel(),
        ),
      )..add(const Screen4AddTextInitialEvent()),
      child: const Screen4AddTextScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const _Screen4AddTextScaffold();
  }
}

class _Screen4AddTextScaffold extends StatefulWidget {
  const _Screen4AddTextScaffold();

  @override
  State<_Screen4AddTextScaffold> createState() =>
      _Screen4AddTextScaffoldState();
}

class _Screen4AddTextScaffoldState extends State<_Screen4AddTextScaffold> {
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechListening = false;
  bool _speechReady = false;

  @override
  void dispose() {
    _speech.stop();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeech(
    TextEditingController controller,
    AddTextInputLanguage language,
  ) async {
    if (_speechListening) {
      await _speech.stop();
      if (mounted) setState(() => _speechListening = false);
      return;
    }

    if (!_speechReady) {
      final ok = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _speechListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _speechListening = false);
        },
      );
      if (!ok) {
        if (mounted) {
          showAppToast(
            'msg_speech_not_available'.tr,
            type: ToastificationType.warning,
          );
        }
        return;
      }
      _speechReady = true;
    }

    if (!mounted) return;
    setState(() => _speechListening = true);

    final localeId = language == AddTextInputLanguage.urdu ? 'ur_IN' : 'en_US';

    try {
      await _speech.listen(
        localeId: localeId,
        onResult: (res) {
          controller.text = res.recognizedWords;
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        showAppToast('msg_speech_error'.tr, type: ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _speechListening = false);
    }
  }

  Future<void> _pasteAtCursor(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (mounted) {
        showAppToast('msg_paste_empty'.tr, type: ToastificationType.info);
      }
      return;
    }
    final value = controller.value;
    final sel = value.selection;
    final s = value.text;
    final next = !sel.isValid
        ? s + text
        : s.replaceRange(sel.start, sel.end, text);
    final off = !sel.isValid ? next.length : sel.start + text.length;
    controller.value = TextEditingValue(
      text: next.length > kAddTextMaxLength
          ? next.substring(0, kAddTextMaxLength)
          : next,
      selection: TextSelection.collapsed(
        offset: off > kAddTextMaxLength ? kAddTextMaxLength : off,
      ),
    );
    _focusNode.requestFocus();
  }

  void _clearField(TextEditingController controller) {
    controller.clear();
    _focusNode.requestFocus();
  }

  String _beautify(String raw, AddTextInputLanguage lang) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (lang == AddTextInputLanguage.english && s.isNotEmpty) {
      final chunks = s.split(RegExp(r'(?<=[.!?])\s+'));
      return chunks
          .map((p) {
            if (p.isEmpty) return p;
            return p[0].toUpperCase() + p.substring(1);
          })
          .join(' ');
    }
    return s;
  }

  Future<void> _translate(
    TextEditingController controller,
    AddTextInputLanguage language,
  ) async {
    final t = controller.text.trim();
    if (t.isEmpty) {
      showAppToast('msg_translate_empty'.tr, type: ToastificationType.warning);
      return;
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 14),
        receiveTimeout: const Duration(seconds: 14),
      ),
    );

    try {
      final pair = language == AddTextInputLanguage.urdu ? 'ur|en' : 'en|ur';
      final q = t.length > 450 ? t.substring(0, 450) : t;
      final r = await dio.get<Map<String, dynamic>>(
        'https://api.mymemory.translated.net/get',
        queryParameters: <String, dynamic>{'q': q, 'langpair': pair},
      );
      final data = r.data;
      final block = data?['responseData'];
      final translated = block is Map<String, dynamic>
          ? block['translatedText'] as String?
          : null;
      if (translated == null || translated.isEmpty) {
        throw StateError('empty translation');
      }
      var out = translated;
      if (out.length > kAddTextMaxLength) {
        out = out.substring(0, kAddTextMaxLength);
      }
      controller.text = out;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      if (mounted) {
        showAppToast('msg_translate_done'.tr);
      }
    } catch (_) {
      if (mounted) {
        showAppToast('msg_translate_failed'.tr, type: ToastificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFFFFFFF);
    const cardFill = Color(0xFFF3F4F6);
    const border = Color(0xFFE5E7EB);
    const muted = Color(0xFF6B7280);
    const titleColor = Color(0xFF111827);
    const ctaActive = Color(0xFF16A34A);
    const ctaDisabledFill = Color(0xFFE5E7EB);
    const ctaDisabledFg = Color(0xFF9CA3AF);

    return Scaffold(
      backgroundColor: pageBg,
      resizeToAvoidBottomInset: true,
      body: BlocBuilder<Screen4AddTextBloc, Screen4AddTextState>(
        builder: (context, state) {
          final controller = state.originalLanguageEditTextController;
          final lang = state.inputLanguage;
          final isUrdu = lang == AddTextInputLanguage.urdu;

          if (controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.h, 12.v, 20.h, 24.v),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  NavigatorService.pushNamed(
                                    AppRoutes.screen3AddNewScreen,
                                  );
                                }
                              },
                              icon: const Icon(Icons.close_rounded),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                              style: IconButton.styleFrom(
                                foregroundColor: titleColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.v),
                        Text(
                          isUrdu
                              ? 'lbl_add_text_title_urdu'.tr
                              : 'lbl_add_text_title_english'.tr,
                          style: TextStyle(
                            fontSize: 26.fSize,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 10.v),
                        Text(
                          'msg_add_text_helper'.tr,
                          style: TextStyle(
                            fontSize: 14.fSize,
                            height: 1.45,
                            color: muted,
                          ),
                        ),
                        SizedBox(height: 22.v),
                        _LanguageToggle(
                          language: lang,
                          onChanged: (v) => context
                              .read<Screen4AddTextBloc>()
                              .add(Screen4AddTextSetLanguageEvent(v)),
                        ),
                        SizedBox(height: 20.v),
                        Container(
                          padding: EdgeInsets.all(4.adaptSize),
                          decoration: BoxDecoration(
                            color: cardFill,
                            borderRadius: BorderRadius.circular(16.adaptSize),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              16.h,
                              14.v,
                              16.h,
                              12.v,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.adaptSize),
                              border: Border.all(color: border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: controller,
                                  focusNode: _focusNode,
                                  maxLines: 8,
                                  minLines: 5,
                                  maxLength: kAddTextMaxLength,
                                  textAlign: isUrdu
                                      ? TextAlign.right
                                      : TextAlign.left,
                                  textDirection: isUrdu
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  style: TextStyle(
                                    fontSize: 16.fSize,
                                    height: 1.45,
                                    color: titleColor,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: isUrdu
                                        ? 'msg_add_text_placeholder_ur'.tr
                                        : 'msg_add_text_placeholder_en'.tr,
                                    hintStyle: TextStyle(
                                      fontSize: 16.fSize,
                                      color: const Color(0xFF9CA3AF),
                                      height: 1.45,
                                    ),
                                    counterText: '',
                                  ),
                                  buildCounter: _addTextHideCounter,
                                ),
                                SizedBox(height: 8.v),
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller,
                                  builder: (context, value, _) {
                                    final len = value.text.length;
                                    return Align(
                                      alignment: isUrdu
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: Text(
                                        '$len/$kAddTextMaxLength',
                                        style: TextStyle(
                                          fontSize: 12.fSize,
                                          color: muted,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 18.v),
                        _ActionToolbarCard(
                          cardFill: cardFill,
                          border: border,
                          children: [
                            _ToolbarAction(
                              icon: Icons.mic_rounded,
                              label: 'lbl_toolbar_voice'.tr,
                              iconColor: _speechListening
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF374151),
                              onPressed: () => _toggleSpeech(controller, lang),
                              semanticLabel: 'lbl_toolbar_voice'.tr,
                            ),
                            _ToolbarAction(
                              icon: Icons.content_paste_rounded,
                              label: 'lbl_toolbar_paste'.tr,
                              onPressed: () => _pasteAtCursor(controller),
                              semanticLabel: 'lbl_toolbar_paste'.tr,
                            ),
                            _ToolbarAction(
                              icon: Icons.delete_outline_rounded,
                              label: 'lbl_toolbar_clear'.tr,
                              onPressed: () => _clearField(controller),
                              semanticLabel: 'lbl_toolbar_clear'.tr,
                            ),
                            _ToolbarAction(
                              icon: Icons.auto_fix_high_rounded,
                              label: 'lbl_toolbar_beautify'.tr,
                              onPressed: () {
                                final next = _beautify(controller.text, lang);
                                controller.value = TextEditingValue(
                                  text: next,
                                  selection: TextSelection.collapsed(
                                    offset: next.length,
                                  ),
                                );
                              },
                              semanticLabel: 'lbl_toolbar_beautify'.tr,
                            ),
                            _ToolbarAction(
                              icon: Icons.translate_rounded,
                              label: 'lbl_text_editor_translate'.tr,
                              onPressed: () => _translate(controller, lang),
                              semanticLabel: 'lbl_text_editor_translate'.tr,
                            ),
                          ],
                        ),
                        if (isUrdu) ...[
                          SizedBox(height: 20.v),
                          UrduMarksStrip(
                            controller: controller,
                            focusNode: _focusNode,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Material(
                color: pageBg,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.h, 12.v, 20.h, 16.v),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final hasText = value.text.trim().isNotEmpty;
                        return SizedBox(
                          width: double.infinity,
                          height: 54.v,
                          child: FilledButton(
                            onPressed: hasText
                                ? () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(
                                        context,
                                      ).pop(value.text.trim());
                                    } else {
                                      NavigatorService.pushNamed(
                                        AppRoutes.screen3AddNewScreen,
                                      );
                                    }
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              elevation: 0,
                              disabledBackgroundColor: ctaDisabledFill,
                              disabledForegroundColor: ctaDisabledFg,
                              backgroundColor: hasText
                                  ? ctaActive
                                  : ctaDisabledFill,
                              foregroundColor: hasText
                                  ? Colors.white
                                  : ctaDisabledFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  14.adaptSize,
                                ),
                              ),
                            ),
                            child: Text(
                              'lbl_add_text_to_design'.tr,
                              style: TextStyle(
                                fontSize: 16.fSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.language, required this.onChanged});

  final AddTextInputLanguage language;
  final ValueChanged<AddTextInputLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    const track = Color(0xFFF3F4F6);
    const border = Color(0xFFE5E7EB);

    return Container(
      padding: EdgeInsets.all(4.adaptSize),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14.adaptSize),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _LangSegment(
              label: 'lbl_english'.tr,
              selected: language == AddTextInputLanguage.english,
              onTap: () => onChanged(AddTextInputLanguage.english),
            ),
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: _LangSegment(
              label: 'lbl_urdu'.tr,
              selected: language == AddTextInputLanguage.urdu,
              onTap: () => onChanged(AddTextInputLanguage.urdu),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangSegment extends StatelessWidget {
  const _LangSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12.adaptSize),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        border: Border.all(
          color: selected
              ? primary.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.adaptSize),
          onTap: onTap,
          child: SizedBox(
            height: 48.v,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15.fSize,
                  fontWeight: FontWeight.w700,
                  color: selected ? primary : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionToolbarCard extends StatelessWidget {
  const _ActionToolbarCard({
    required this.children,
    required this.cardFill,
    required this.border,
  });

  final List<Widget> children;
  final Color cardFill;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.v, horizontal: 10.h),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(16.adaptSize),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: 6.h),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.semanticLabel,
    this.iconColor = const Color(0xFF374151),
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String semanticLabel;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.adaptSize),
          border: Border.all(color: const Color(0xFFE8EAED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12.adaptSize),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.adaptSize),
            onTap: onPressed,
            child: SizedBox(
              width: 72.h,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.v, horizontal: 4.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 24.adaptSize, color: iconColor),
                    SizedBox(height: 6.v),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.fSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
