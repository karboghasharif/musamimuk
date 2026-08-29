import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/editor_ai_api_models.dart';
import '../../data/models/wallet_models.dart';
import '../../data/services/editor_ai/editor_ai_api_service.dart';
import 'ai_studio_image_screen.dart';
import 'ai_studio_shared.dart';

class _ChatTurn {
  const _ChatTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Multi-turn ChatGPT assistant for design help and copy ideas.
class AiStudioChatScreen extends StatefulWidget {
  const AiStudioChatScreen({super.key});

  static Widget builder(BuildContext context) => const AiStudioChatScreen();

  @override
  State<AiStudioChatScreen> createState() => _AiStudioChatScreenState();
}

class _AiStudioChatScreenState extends State<AiStudioChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _api = EditorAiApiService();
  final _turns = <_ChatTurn>[];
  final _history = <AiMessage>[
    AiMessage.system(
      'You are Musamimuk AI Studio, a friendly ChatGPT design assistant. '
      'Help with design ideas, Arabic/English copy, layouts, and brand tone. '
      'Keep answers concise and practical. Do not invent that you can edit the '
      'user canvas directly — suggest clear next steps instead.',
    ),
  ];
  bool _busy = false;

  static const _suggestions = <String>[
    'Suggest a slogan for a Saudi coffee brand',
    'Write Arabic Instagram caption for a bakery',
    'Color palette ideas for a luxury real-estate flyer',
    'Headline options for a LinkedIn banner',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _busy) return;
    if (!await AiStudioChrome.guardOpenAiEditor(context)) return;

    setState(() {
      _busy = true;
      _turns.add(_ChatTurn(isUser: true, text: text));
      _history.add(AiMessage.user(text));
      _inputCtrl.clear();
    });
    _scrollToEnd();

    try {
      final response = await _api.sendOpenAiEditor(
        OpenAiEditorRequest(messages: List<AiMessage>.from(_history)),
      );
      if (!mounted) return;
      AiStudioChrome.applyWallet(context, _api);
      final reply = response.content.trim();
      setState(() {
        _turns.add(_ChatTurn(isUser: false, text: reply));
        _history.add(AiMessage.assistant(reply));
      });
      _scrollToEnd();
    } catch (error) {
      if (mounted) {
        setState(() {
          _history.removeLast();
          _turns.removeLast();
        });
        AiStudioChrome.toastAiError(error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 80,
        duration: AppDs.motionNormal,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: AiStudioChrome.appBar(context, 'lbl_ai_chat'.tr),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space3.v,
                AppDs.space4.h,
                AppDs.space2.v,
              ),
              child: Row(
                children: [
                  AiStudioChrome.poweredByChatGpt(context),
                  const Spacer(),
                  BlocBuilderCoinHint(feature: WalletFeatureCost.aiOpenaiEditor),
                ],
              ),
            ),
            if (_turns.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(
                      'msg_ai_chat_subtitle'.tr,
                      variant: AppTextVariant.secondary,
                    ),
                    SizedBox(height: AppDs.space3.v),
                    AiStudioChrome.suggestionChips(
                      suggestions: _suggestions,
                      onTap: (tip) => _send(tip),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.all(AppDs.space4.h),
                itemCount: _turns.length + (_busy ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_busy && index == _turns.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(top: AppDs.space2.v),
                        child: const AppLoadingBlock(),
                      ),
                    );
                  }
                  final turn = _turns[index];
                  return _Bubble(turn: turn);
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDs.space4.h,
                  AppDs.space2.v,
                  AppDs.space4.h,
                  AppDs.space3.v,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AiStudioPromptField(
                        controller: _inputCtrl,
                        hint: 'msg_ai_chat_hint'.tr,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: _busy ? null : () => _send(),
                      ),
                    ),
                    SizedBox(width: AppDs.space2.h),
                    IconButton.filled(
                      onPressed: _busy ? null : () => _send(),
                      style: IconButton.styleFrom(
                        backgroundColor: AiStudioChrome.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AiStudioChrome.accent.withValues(alpha: 0.35),
                      ),
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final _ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    final bg = turn.isUser
        ? AiStudioChrome.accent.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.07);
    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDs.space2.v),
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space3.h,
          vertical: AppDs.space2.v + 2,
        ),
        constraints: BoxConstraints(maxWidth: 0.82 * MediaQuery.sizeOf(context).width),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        ),
        child: SelectableText(
          turn.text,
          style: TextStyle(
            color: AppDs.textOnDarkPrimary,
            fontSize: 14.fSize,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
