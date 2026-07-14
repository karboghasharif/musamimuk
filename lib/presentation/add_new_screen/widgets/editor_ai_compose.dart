import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/config/ai_debug_config.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/design_compose_plan.dart';
import '../../../data/services/ai_design_compose_service.dart';
import '../../../data/services/ai_text_service.dart';
import 'design_compose_executor.dart';

/// Natural-language "add component to canvas" compose UI for the main editor.
class EditorAiCompose {
  EditorAiCompose({
    AiDesignComposeService? composeService,
    DesignComposeExecutor? executor,
  })  : _composeService = composeService ?? AiDesignComposeService(),
        _executor = executor ?? DesignComposeExecutor();

  final AiDesignComposeService _composeService;
  final DesignComposeExecutor _executor;

  Future<void> openCompose({
    required BuildContext context,
    required ProImageEditorState editor,
    String? initialPrompt,
  }) async {
    if (!AiDebugConfig.isConfigured) {
      showAppToast(
        'msg_ai_not_configured'.tr,
        type: ToastificationType.warning,
      );
      return;
    }
    if (!context.mounted) return;

    await showAppModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ComposeSheet(
        initialPrompt: initialPrompt,
        onPreview: (prompt) => _composeService.parseComponentPrompt(prompt),
        onExecute: (plan) => _executor.execute(
          context: ctx,
          editor: editor,
          plan: plan,
        ),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({
    required this.onPreview,
    required this.onExecute,
    this.initialPrompt,
  });

  final Future<DesignComposePlan> Function(String prompt) onPreview;
  final Future<ComposeExecuteResult> Function(DesignComposePlan plan) onExecute;
  final String? initialPrompt;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  late final TextEditingController _controller;
  DesignComposePlan? _plan;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runPreview() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
      _plan = null;
    });

    try {
      final plan = await widget.onPreview(prompt);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _busy = false;
      });
    } on AiTextException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message.isNotEmpty ? e.message : 'msg_ai_failed'.tr;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'msg_ai_failed'.tr;
      });
    }
  }

  Future<void> _runExecute() async {
    final plan = _plan;
    if (plan == null || _busy) return;

    if (!plan.isExecutable) {
      showAppToast('msg_ai_failed'.tr, type: ToastificationType.warning);
      return;
    }

    setState(() => _busy = true);

    final result = await widget.onExecute(plan);
    if (!mounted) return;

    setState(() => _busy = false);

    switch (result) {
      case ComposeExecuteSuccess(:final message):
        showAppToast(message, type: ToastificationType.success);
        Navigator.of(context).pop();
      case ComposeExecuteFailure(:final message):
        showAppToast(message, type: ToastificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AppDarkSheetTheme(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'lbl_ai_compose'.tr,
                style: AppDs.sheetTitle(
                  theme,
                  color: AppDs.textOnDarkPrimary,
                ),
              ),
              SizedBox(height: AppDs.space2.v),
              AppText(
                'msg_ai_compose_hint'.tr,
                variant: AppTextVariant.secondary,
              ),
              SizedBox(height: AppDs.space4.v),
              AppTextField(
                controller: _controller,
                hintText: 'msg_ai_compose_hint'.tr,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _runPreview(),
              ),
              if (_error != null) ...[
                SizedBox(height: AppDs.space2.v),
                AppText(
                  _error!,
                  variant: AppTextVariant.caption,
                ),
              ],
              if (_plan != null) ...[
                SizedBox(height: AppDs.space4.v),
                Container(
                  padding: EdgeInsets.all(AppDs.space3.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    ),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'msg_ai_compose_preview'.tr,
                        variant: AppTextVariant.caption,
                      ),
                      SizedBox(height: AppDs.space2.v),
                      AppText(
                        _plan!.summary,
                        variant: AppTextVariant.body,
                      ),
                      if (_plan!.action == DesignComposeAction.addAsset) ...[
                        SizedBox(height: AppDs.space1.v),
                        AppText(
                          '${_plan!.assetType ?? 'asset'} · ${_plan!.searchQuery ?? ''}',
                          variant: AppTextVariant.secondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: AppDs.space4.v),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _runPreview,
                      child: _busy && _plan == null
                          ? SizedBox(
                              height: 20.v,
                              width: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : Text('lbl_apply'.tr),
                    ),
                  ),
                  if (_plan != null) ...[
                    SizedBox(width: AppDs.space2.h),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'lbl_ai_compose_confirm'.tr,
                        onPressed: _busy ? null : _runExecute,
                        isLoading: _busy && _plan != null,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: AppDs.space2.v),
            ],
          ),
        ),
      ),
    );
  }
}
