import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:toastification/toastification.dart';

import '../../../core/config/editor_ai_config.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/wallet_models.dart';
import '../../../data/services/editor_ai/editor_ai_message_base.dart';
import '../../../data/services/editor_ai/editor_ai_prompt_classifier.dart';
import '../../../data/services/editor_ai/editor_ai_provider_factory.dart';
import '../../wallet/bloc/wallet_bloc.dart';
import '../../wallet/wallet_cost_guard.dart';
import '../bloc/add_new_bloc.dart';

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const supportImages = true;

    return ExpandableFab(
      key: fabKey,
      type: ExpandableFabType.up,
      distance: 72,
      duration: const Duration(milliseconds: 220),
      childrenAnimation: ExpandableFabAnimation.none,
      // No dim overlay — its full-screen Container expands the FAB slot and
      // steals canvas hit-testing even after the menu closes.
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(Icons.auto_awesome),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: primary,
        shape: const CircleBorder(),
      ),
      closeButtonBuilder: DefaultFloatingActionButtonBuilder(
        child: const Icon(Icons.close),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF3A3A3E),
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

  static const _chrome = Color(0xFF28282C);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: _chrome,
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FloatingActionButton.small(
          heroTag: heroTag,
          tooltip: tooltip,
          backgroundColor: _chrome,
          foregroundColor: Colors.white,
          onPressed: onPressed,
          child: Icon(icon),
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

  static const _anim = Duration(milliseconds: 220);
  static const _chrome = Color(0xFF28282C);

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
    return WalletFeatureCost.aiOpenaiEditor;
  }

  Future<void> _pickExample() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _EditorAiExampleCommandsSheet(),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final isNarrow = constraints.maxWidth < 560;
                      final input = _buildInput();
                      final actions = _buildActionRow();
                      if (isNarrow) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [actions, const SizedBox(height: 7), input],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: input),
                          const SizedBox(width: 12),
                          actions,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
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
            return DecoratedBox(
              decoration: BoxDecoration(boxShadow: kElevationToShadow[6]),
              child: TextField(
                readOnly: processing,
                onEditingComplete: _send,
                controller: _inputCtrl,
                focusNode: _inputFocus,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _chrome,
                  border: const OutlineInputBorder(),
                  hintText: switch (mode) {
                    EditorAiGenerationMode.text =>
                      'Edit canvas (text/arrow/blur) — or “add burger image”',
                    EditorAiGenerationMode.designComposition =>
                      'Describe a fully editable banner or template…',
                    EditorAiGenerationMode.sticker =>
                      'Describe an image sticker to generate (GPT Image)…',
                    EditorAiGenerationMode.background =>
                      'Describe a new background image (GPT Image)…',
                  },
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: processing
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          )
                        : IconButton(
                            tooltip: 'Send to AI',
                            icon: const Icon(Icons.send, color: Colors.white70),
                            onPressed: _send,
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

  Widget _buildActionRow() {
    final imageOk = _provider?.isImageGenerationSupported ?? false;

    return Container(
      decoration: const ShapeDecoration(
        shadows: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        color: _chrome,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close AI bar',
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: widget.onClose,
            ),
          IconButton(
            tooltip: 'Example commands',
            icon: const Icon(Icons.info_outline, color: Colors.white70),
            onPressed: _pickExample,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.auto_awesome, color: Color(0xFF10A37F), size: 20),
          ),
          _coinCostBadge(),
          if (imageOk) _modeMenu(),
          ValueListenableBuilder<bool>(
            valueListenable: _alignTop,
            builder: (_, alignTop, _) {
              return IconButton(
                tooltip: 'Move bar',
                icon: AnimatedRotation(
                  duration: _anim,
                  turns: alignTop ? 0.5 : 0,
                  child: const Icon(Icons.arrow_upward, color: Colors.white70),
                ),
                onPressed: () => _alignTop.value = !_alignTop.value,
              );
            },
          ),
        ],
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$cost',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _modeMenu() {
    return ValueListenableBuilder<EditorAiGenerationMode>(
      valueListenable: _mode,
      builder: (_, mode, _) {
        return PopupMenuButton<EditorAiGenerationMode>(
          tooltip: 'Generation mode',
          initialValue: mode,
          onSelected: (v) => _mode.value = v,
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: EditorAiGenerationMode.text,
              child: Text('Text commands'),
            ),
            PopupMenuItem(
              value: EditorAiGenerationMode.designComposition,
              child: Text('Generate editable design'),
            ),
            PopupMenuItem(
              value: EditorAiGenerationMode.sticker,
              child: Text('Generate sticker (GPT Image)'),
            ),
            PopupMenuItem(
              value: EditorAiGenerationMode.background,
              child: Text('Replace background (GPT Image)'),
            ),
          ],
          child: Icon(
            switch (mode) {
              EditorAiGenerationMode.text => Icons.description_outlined,
              EditorAiGenerationMode.designComposition =>
                Icons.dashboard_customize_outlined,
              EditorAiGenerationMode.sticker => Icons.sticky_note_2_outlined,
              EditorAiGenerationMode.background => Icons.wallpaper_outlined,
            },
            color: Colors.white70,
            size: 20,
          ),
        );
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
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Example commands',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              shrinkWrap: true,
              itemCount: _commands.length,
              itemBuilder: (_, index) {
                final command = _commands[index];
                return ListTile(
                  title: Text(command),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, command),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
