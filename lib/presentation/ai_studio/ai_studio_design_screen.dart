import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/config/editor_ai_config.dart';
import '../../core/utils/app_toast.dart';
import '../select_size_screen/data/size_presets.dart';
import '../select_size_screen/models/size_preset.dart';
import 'ai_studio_shared.dart';

/// Collect a ChatGPT design prompt + canvas size, then open the editor AI bar.
class AiStudioDesignScreen extends StatefulWidget {
  const AiStudioDesignScreen({super.key});

  static Widget builder(BuildContext context) => const AiStudioDesignScreen();

  @override
  State<AiStudioDesignScreen> createState() => _AiStudioDesignScreenState();
}

class _AiStudioDesignScreenState extends State<AiStudioDesignScreen> {
  final _promptCtrl = TextEditingController();
  late SizePreset _preset;

  static const _suggestions = <String>[
    'Create an editable LinkedIn banner with teal accents and a circular photo',
    'Design a bilingual Arabic/English bakery flyer with clear text layers',
    'Make a modern event poster with title, date, and icon rows',
    'Build a product promo card with headline, price, and CTA text',
  ];

  @override
  void initState() {
    super.initState();
    _preset = kDesignSizePresets.firstWhere(
      (p) => p.name.toLowerCase().contains('instagram'),
      orElse: () => kDesignSizePresets.first,
    );
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _openEditor() {
    var prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      prompt = _suggestions.first;
      _promptCtrl.text = prompt;
      showAppToast(
        'msg_ai_design_using_example'.tr,
        type: ToastificationType.info,
      );
    }
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: {
        'width': _preset.width,
        'height': _preset.height,
        'unit': 'px',
        'presetName': _preset.name,
        'aiMode': EditorAiGenerationMode.designComposition.name,
        'aiPrompt': prompt,
        'aiAutoSend': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: AiStudioChrome.appBar(context, 'lbl_ai_generate_designs'.tr),
        body: ListView(
          padding: EdgeInsets.all(AppDs.space4.h),
          children: [
            AiStudioChrome.poweredByChatGpt(context),
            SizedBox(height: AppDs.space3.v),
            AppText(
              'msg_ai_design_subtitle'.tr,
              variant: AppTextVariant.secondary,
            ),
            SizedBox(height: AppDs.space4.v),
            AiStudioPromptField(
              controller: _promptCtrl,
              hint: 'msg_ai_design_prompt_hint'.tr,
              minLines: 4,
              maxLines: 8,
            ),
            SizedBox(height: AppDs.space3.v),
            AiStudioChrome.suggestionChips(
              suggestions: _suggestions,
              onTap: (tip) {
                _promptCtrl.text = tip;
                setState(() {});
              },
            ),
            SizedBox(height: AppDs.space4.v),
            AppText('lbl_select_size'.tr, variant: AppTextVariant.title),
            SizedBox(height: AppDs.space2.v),
            ...kDesignSizePresets.take(8).map((preset) {
              final selected = _preset.name == preset.name &&
                  _preset.width == preset.width &&
                  _preset.height == preset.height;
              return Padding(
                padding: EdgeInsets.only(bottom: AppDs.space2.v),
                child: Material(
                  color: selected
                      ? AiStudioChrome.accent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius:
                      BorderRadius.circular(AppDs.radiusMd.adaptSize),
                  child: ListTile(
                    onTap: () => setState(() => _preset = preset),
                    title: Text(
                      preset.name,
                      style: const TextStyle(
                        color: AppDs.textOnDarkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${preset.width} × ${preset.height} · ${preset.category}',
                      style: const TextStyle(color: AppDs.textOnDarkSecondary),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AiStudioChrome.accent,
                          )
                        : null,
                  ),
                ),
              );
            }),
            SizedBox(height: AppDs.space4.v),
            AppPrimaryButton(
              label: 'lbl_ai_create_design'.tr,
              onPressed: _openEditor,
            ),
          ],
        ),
      ),
    );
  }
}
