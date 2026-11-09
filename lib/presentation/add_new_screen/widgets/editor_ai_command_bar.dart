import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/config/editor_ai_config.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/wallet_models.dart';
import '../../../data/services/editor_ai/editor_ai_message_base.dart';
import '../../../data/services/editor_ai/editor_ai_prompt_classifier.dart';
import '../../../data/services/editor_ai/editor_ai_provider_factory.dart';
import '../../ai_studio/ai_studio_shared.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/wallet_cost_guard.dart';
import '../bloc/add_new_bloc.dart';
import 'musami_ai_chrome.dart';

/// Command-bar overlay shown after the user picks an AI action from the FAB.
class MusamiEditorAiOverlay extends StatelessWidget {
  const MusamiEditorAiOverlay({
    super.key,
    required this.editorKey,
    required this.visible,
    required this.mode,
    required this.onClose,
    this.initialPrompt,
    this.autoSend = false,
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final bool visible;
  final EditorAiGenerationMode mode;
  final VoidCallback onClose;
  final String? initialPrompt;
  final bool autoSend;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final editor = editorKey?.currentState;
    if (editor == null) return const SizedBox.shrink();
    if (editor.isLayerBeingTransformed || editor.isSubEditorOpen) {
      return const SizedBox.shrink();
    }

    // Size to the bar only — a full-screen Material absorbs canvas taps and
    // makes newly added stickers look "unselectable".
    return EditorAiCommandBar(
      key: ValueKey('${mode.name}|${initialPrompt ?? ''}|$autoSend'),
      editor: editor,
      initialMode: mode,
      initialPrompt: initialPrompt,
      autoSend: autoSend,
      onClose: onClose,
      bottomInset: 0,
    );
  }
}

/// Expandable FAB (`flutter_expandable_fab`) — opens AI Text / Sticker / BG bar.
class MusamiEditorAiExpandableFab extends StatelessWidget {
  const MusamiEditorAiExpandableFab({
    super.key,
    required this.fabKey,
    required this.onOpenMode,
  });

  final GlobalKey<ExpandableFabState> fabKey;
  final ValueChanged<EditorAiGenerationMode> onOpenMode;

  void _select(EditorAiGenerationMode mode) {
    final state = fabKey.currentState;
    if (state != null && state.isOpen) state.toggle();
    onOpenMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    const supportImages = true;

    return ExpandableFab(
      key: fabKey,
      type: ExpandableFabType.up,
      distance: 76,
      duration: AppDs.motionFast,
      childrenAnimation: ExpandableFabAnimation.none,
      // No dim overlay — its full-screen Container expands the FAB slot and
      // steals canvas hit-testing even after the menu closes.
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.auto_awesome_rounded),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: MusamiAiChrome.onAccent,
        backgroundColor: MusamiAiChrome.accent,
        shape: const CircleBorder(),
      ),
      closeButtonBuilder: DefaultFloatingActionButtonBuilder(
        child: const Icon(Icons.close_rounded),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: AppDs.textOnDarkPrimary,
        backgroundColor: MusamiAiChrome.panel,
        shape: const CircleBorder(),
      ),
      children: [
        _AiFabLabeledAction(
          heroTag: 'musami_ai_text',
          label: 'Text',
          tooltip: 'AI text commands',
          icon: Icons.description_outlined,
          onPressed: () => _select(EditorAiGenerationMode.text),
        ),
        if (supportImages)
          _AiFabLabeledAction(
            heroTag: 'musami_ai_design',
            label: 'Design',
            tooltip: 'Generate fully editable design',
            icon: Icons.dashboard_customize_outlined,
            onPressed: () => _select(EditorAiGenerationMode.designComposition),
          ),
        if (supportImages)
          _AiFabLabeledAction(
            heroTag: 'musami_ai_sticker',
            label: 'Sticker',
            tooltip: 'Generate sticker (GPT Image)',
            icon: Icons.sticky_note_2_outlined,
            onPressed: () => _select(EditorAiGenerationMode.sticker),
          ),
        if (supportImages)
          _AiFabLabeledAction(
            heroTag: 'musami_ai_background',
            label: 'Background',
            tooltip: 'Replace background (GPT Image)',
            icon: Icons.wallpaper_outlined,
            onPressed: () => _select(EditorAiGenerationMode.background),
          ),
      ],
    );
  }
}

/// Labeled speed-dial child: name chip left of the circular FAB.
class _AiFabLabeledAction extends StatelessWidget {
  const _AiFabLabeledAction({
    required this.heroTag,
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String heroTag;
  final String label;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: MusamiAiChrome.panel,
          elevation: 3,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(AppDs.radiusFull),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppDs.radiusFull),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppDs.textOnDarkPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: heroTag,
          tooltip: tooltip,
          backgroundColor: MusamiAiChrome.panelDeep,
          foregroundColor: MusamiAiChrome.accent,
          elevation: 3,
          onPressed: onPressed,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}

/// Floating AI command bar for the design editor.
class EditorAiCommandBar extends StatefulWidget {
  const EditorAiCommandBar({
    super.key,
    required this.editor,
    this.bottomInset = 96,
    this.initialMode = EditorAiGenerationMode.text,
    this.initialPrompt,
    this.autoSend = false,
    this.onClose,
  });

  final ProImageEditorState editor;

  /// Space reserved above the app's custom bottom tool row.
  final double bottomInset;

  final EditorAiGenerationMode initialMode;
  final String? initialPrompt;
  final bool autoSend;
  final VoidCallback? onClose;

  @override
  State<EditorAiCommandBar> createState() => _EditorAiCommandBarState();
}

class _EditorAiCommandBarState extends State<EditorAiCommandBar> {
  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  final _isProcessing = ValueNotifier(false);
  final _alignTop = ValueNotifier(false);
  late final ValueNotifier<EditorAiGenerationMode> _mode;

  late EditorAiProviderKind _providerKind;
  EditorAiMessageBase? _provider;

  static const _anim = AppDs.motionFast;

  @override
  void initState() {
    super.initState();
    _mode = ValueNotifier(widget.initialMode);
    _providerKind = EditorAiProviderFactory.defaultProvider();
    final seed = widget.initialPrompt?.trim();
    if (seed != null && seed.isNotEmpty) {
      _inputCtrl.text = seed;
    }
    _rebuildProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.autoSend && _inputCtrl.text.trim().isNotEmpty) {
        _send();
      } else {
        _inputFocus.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuildProvider();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    _isProcessing.dispose();
    _alignTop.dispose();
    _mode.dispose();
    super.dispose();
  }

  void _rebuildProvider() {
    _provider = EditorAiProviderFactory.create(
      context: context,
      provider: _providerKind,
    );
  }

  Future<void> _prepareEditableDesignCanvas(
    ProImageEditorState editor,
    String prompt,
  ) async {
    if (editor.activeLayers.isNotEmpty) return;

    final normalizedPrompt = prompt.toLowerCase();
    final Size? preset = normalizedPrompt.contains('linkedin')
        ? const Size(1584, 396)
        : normalizedPrompt.contains('banner')
        ? const Size(1600, 600)
        : null;
    if (preset == null) return;

    final before = editor.sizesManager.decodedImageSize;
    final currentAspect = before.height > 0
        ? before.width / before.height
        : 0.0;
    final targetAspect = preset.width / preset.height;
    if ((currentAspect - targetAspect).abs() / targetAspect < 0.1) return;

    final bloc = context.read<AddNewBloc>();
    bloc.add(ApplyCustomSizeEvent(width: preset.width, height: preset.height));
    await bloc.stream.firstWhere(
      (state) =>
          state.selectedwidth == preset.width &&
          state.selectedheight == preset.height,
    );
    await editor.decodeImage();
  }

  Future<void> _send() async {
    final command = _inputCtrl.text.trim();
    if (_isProcessing.value) {
      debugPrint('⚠️ AI send ignored — already processing');
      return;
    }
    if (command.isEmpty) {
      showAppToast('Enter an AI command first', type: ToastificationType.info);
      return;
    }

    if (!SessionManager.instance.requireAuthenticated()) return;

    if (_provider == null) {
      showAppToast(
        'AI tools are temporarily unavailable.',
        type: ToastificationType.warning,
      );
      return;
    }

    var mode = _mode.value;
    final buildEditableDesign =
        mode == EditorAiGenerationMode.designComposition ||
        isEditableDesignPrompt(command);
    final standaloneImage = looksLikeStandaloneImagePrompt(command);
    final explicitBackground = looksLikeBackgroundImagePrompt(command);
    if (buildEditableDesign && _provider!.isImageGenerationSupported) {
      mode = EditorAiGenerationMode.designComposition;
      _mode.value = mode;
      showAppToast(
        'Building editable design layers…',
        type: ToastificationType.info,
      );
    } else if (buildEditableDesign) {
      showAppToast(
        'Editable designs with generated images need OpenAI.',
        type: ToastificationType.warning,
      );
      return;
    } else if (_provider!.isImageGenerationSupported && standaloneImage) {
      mode = explicitBackground
          ? EditorAiGenerationMode.background
          : EditorAiGenerationMode.sticker;
      _mode.value = mode;
      showAppToast(
        explicitBackground
            ? 'Generating canvas background…'
            : 'Generating selectable image…',
        type: ToastificationType.info,
      );
    } else if (!_provider!.isImageGenerationSupported && standaloneImage) {
      showAppToast(
        'Image generation needs OpenAI. Switch provider, then retry.',
        type: ToastificationType.warning,
      );
      return;
    }

    final featureKey = _walletFeatureFor(mode);
    final allowed = await ensureCanSpendCoins(
      context: context,
      feature: featureKey,
    );
    if (!allowed || !mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();
    _isProcessing.value = true;
    final editor = widget.editor;

    try {
      if (mode == EditorAiGenerationMode.designComposition) {
        await _prepareEditableDesignCanvas(editor, command);
        if (!mounted) return;
      }
      var ok = false;
      switch (mode) {
        case EditorAiGenerationMode.text:
          ok = await _provider!.sendCommand(editor, command);
          if (ok && mounted) {
            showAppToast('AI edit applied', type: ToastificationType.success);
          }
        case EditorAiGenerationMode.designComposition:
          ok = await _provider!.sendDesignCompositionRequest(editor, command);
          if (ok && mounted) {
            widget.onClose?.call();
            showAppToast(
              'Editable design added to canvas',
              type: ToastificationType.success,
            );
          }
        case EditorAiGenerationMode.sticker:
          ok = await _provider!.sendImageGenerationRequest(
            editor,
            command,
            asBackground: false,
          );
          if (ok && mounted) {
            // Close first so the bar cannot block sticker selection.
            widget.onClose?.call();
            showAppToast(
              'Sticker added to canvas',
              type: ToastificationType.success,
            );
          }
        case EditorAiGenerationMode.background:
          ok = await _provider!.sendImageGenerationRequest(
            editor,
            command,
            asBackground: true,
          );
          if (ok && mounted) {
            showAppToast(
              'Background updated',
              type: ToastificationType.success,
            );
            widget.onClose?.call();
          }
      }
      if (ok && mounted) {
        _inputCtrl.clear();
        // Server is source of truth — refresh balance after a spend.
        context.read<WalletBloc>().add(const WalletRefreshEvent());
      }
    } finally {
      if (mounted) _isProcessing.value = false;
    }
  }

  String _walletFeatureFor(EditorAiGenerationMode mode) {
    final usesImages = mode == EditorAiGenerationMode.sticker ||
        mode == EditorAiGenerationMode.background ||
        mode == EditorAiGenerationMode.designComposition;
    if (usesImages && _providerKind == EditorAiProviderKind.openAi) {
      return WalletFeatureCost.aiOpenaiImages;
    }
    if (_providerKind == EditorAiProviderKind.gemini) {
      return WalletFeatureCost.aiGeminiEditor;
    }
    if (_providerKind == EditorAiProviderKind.grok) {
      return WalletFeatureCost.aiGrokEditor;
    }
    return WalletFeatureCost.aiOpenaiEditor;
  }

  Future<void> _pickExample() async {
    final result = await showAppModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AppDarkSheetTheme(
        child: _EditorAiExampleCommandsSheet(),
      ),
    );
    if (result == null || !mounted) return;
    _mode.value = EditorAiGenerationMode.text;
    _inputCtrl.text = result;
    await _send();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPad =
        math.max(0.0, widget.bottomInset) +
        math.max(0.0, keyboard - widget.bottomInset);
    final imageOk = _provider?.isImageGenerationSupported ?? false;

    return ValueListenableBuilder<bool>(
      valueListenable: _alignTop,
      builder: (_, alignTop, _) {
        // width/heightFactor keep Align sized to the bar (not the full screen).
        return Align(
          alignment: alignTop ? Alignment.topCenter : Alignment.bottomCenter,
          widthFactor: 1,
          heightFactor: 1,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 72 + bottomPad),
            child: Material(
              type: MaterialType.transparency,
              child: AnimatedContainer(
                duration: _anim,
                curve: Curves.easeOutCubic,
                decoration: MusamiAiChrome.panelDecoration(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildToolbar(imageOk: imageOk),
                    if (imageOk) ...[
                      const SizedBox(height: 10),
                      _buildModeChips(),
                    ],
                    const SizedBox(height: 10),
                    _buildInput(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolbar({required bool imageOk}) {
    return Row(
      children: [
        if (widget.onClose != null)
          _toolbarIcon(
            tooltip: 'Close AI bar',
            icon: Icons.close_rounded,
            onPressed: widget.onClose,
          ),
        _toolbarIcon(
          tooltip: 'Example commands',
          icon: Icons.lightbulb_outline_rounded,
          onPressed: _pickExample,
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: MusamiAiChrome.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppDs.radiusFull),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: MusamiAiChrome.accent,
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                'AI',
                style: TextStyle(
                  color: MusamiAiChrome.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _providerMenu(),
        _coinCostBadge(),
        ValueListenableBuilder<bool>(
          valueListenable: _alignTop,
          builder: (_, alignTop, _) {
            return _toolbarIcon(
              tooltip: 'Move bar',
              icon: Icons.swap_vert_rounded,
              onPressed: () => _alignTop.value = !alignTop,
              selected: alignTop,
            );
          },
        ),
      ],
    );
  }

  Widget _toolbarIcon({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool selected = false,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 20,
        color: selected ? MusamiAiChrome.accent : AppDs.textOnDarkSecondary,
      ),
    );
  }

  Widget _buildModeChips() {
    return ValueListenableBuilder<EditorAiGenerationMode>(
      valueListenable: _mode,
      builder: (_, mode, _) {
        final items = <(EditorAiGenerationMode, String, IconData)>[
          (EditorAiGenerationMode.text, 'Text', Icons.description_outlined),
          (
            EditorAiGenerationMode.designComposition,
            'Design',
            Icons.dashboard_customize_outlined,
          ),
          (
            EditorAiGenerationMode.sticker,
            'Sticker',
            Icons.sticky_note_2_outlined,
          ),
          (
            EditorAiGenerationMode.background,
            'Background',
            Icons.wallpaper_outlined,
          ),
        ];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                MusamiAiChoiceChip(
                  label: items[i].$2,
                  icon: items[i].$3,
                  selected: mode == items[i].$1,
                  onTap: () => _mode.value = items[i].$1,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isProcessing,
      builder: (_, processing, _) {
        return ValueListenableBuilder<EditorAiGenerationMode>(
          valueListenable: _mode,
          builder: (_, mode, _) {
            return TextField(
              readOnly: processing,
              onEditingComplete: _send,
              controller: _inputCtrl,
              focusNode: _inputFocus,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(
                color: AppDs.textOnDarkPrimary,
                fontSize: 15,
                height: 1.35,
              ),
              decoration: MusamiAiChrome.fieldDecoration(
                hint: switch (mode) {
                  EditorAiGenerationMode.text =>
                    'Edit canvas — or ask to add an image…',
                  EditorAiGenerationMode.designComposition =>
                    'Describe an editable banner or template…',
                  EditorAiGenerationMode.sticker =>
                    'Describe a sticker to generate…',
                  EditorAiGenerationMode.background =>
                    'Describe a new background…',
                },
                suffix: processing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: MusamiAiChrome.accent,
                          ),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Send to AI',
                        onPressed: _send,
                        icon: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: MusamiAiChrome.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 18,
                            color: MusamiAiChrome.onAccent,
                          ),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _coinCostBadge() {
    return ValueListenableBuilder<EditorAiGenerationMode>(
      valueListenable: _mode,
      builder: (context, mode, _) {
        final feature = _walletFeatureFor(mode);
        return BlocBuilder<WalletBloc, WalletState>(
          buildWhen: (p, n) => p.costs != n.costs || p.balance != n.balance,
          builder: (context, state) {
            final cost = context.read<WalletBloc>().costFor(feature);
            if (cost == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                  border: Border.all(color: MusamiAiChrome.hairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 13,
                      color: MusamiAiChrome.accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$cost',
                      style: const TextStyle(
                        color: AppDs.textOnDarkPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _providerMenu() {
    return AiStudioProviderPicker(
      value: _providerKind,
      onChanged: (kind) {
        setState(() {
          _providerKind = kind;
          _rebuildProvider();
          final imageOk = _provider?.isImageGenerationSupported ?? false;
          if (!imageOk &&
              (_mode.value == EditorAiGenerationMode.sticker ||
                  _mode.value == EditorAiGenerationMode.background ||
                  _mode.value == EditorAiGenerationMode.designComposition)) {
            _mode.value = EditorAiGenerationMode.text;
          }
        });
      },
    );
  }
}

class _EditorAiExampleCommandsSheet extends StatelessWidget {
  const _EditorAiExampleCommandsSheet();

  static const _commands = [
    'Create an editable LinkedIn banner with separate text, photos, icons, and teal shapes',
    'Add a red arrow pointing to the center',
    'Add text Hello World in white at the top',
    'Increase brightness a bit',
    'Add a light blur',
    'Add a happy emoji in the top-right corner',
    'Draw a dashed line across the bottom',
    'Add a red circle in the center',
    'Flip the image horizontally',
    'Rotate the image 90 degrees clockwise',
    'Apply a warm color filter',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.72;
    return AppSheetPagePadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MusamiAiSheetHeader(
              title: 'Example commands',
              subtitle: 'Tap one to run it instantly',
              icon: Icons.lightbulb_outline_rounded,
              trailing: IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ),
            SizedBox(height: AppDs.space3.v),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _commands.length,
                separatorBuilder: (_, _) => SizedBox(height: AppDs.space2.v),
                itemBuilder: (_, index) {
                  final command = _commands[index];
                  return Material(
                    color: MusamiAiChrome.panelDeep,
                    borderRadius: BorderRadius.circular(AppDs.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      onTap: () => Navigator.pop(context, command),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                command,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppDs.textOnDarkPrimary,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.north_east_rounded,
                              size: 18,
                              color: MusamiAiChrome.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
