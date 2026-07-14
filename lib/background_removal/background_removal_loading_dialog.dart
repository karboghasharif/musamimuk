import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:musamimuk/background_removal/background_removal_controller.dart';
import 'package:musamimuk/background_removal/background_removal_state.dart';
import 'package:musamimuk/core/app_export.dart';

/// Polished, non-dismissible overlay while AI background removal runs.
class BackgroundRemovalLoadingDialog extends StatefulWidget {
  const BackgroundRemovalLoadingDialog({
    super.key,
    this.previewBytes,
    this.controller,
  });

  final Uint8List? previewBytes;
  final BackgroundRemovalController? controller;

  static void show(
    BuildContext context, {
    Uint8List? previewBytes,
    BackgroundRemovalController? controller,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      useRootNavigator: true,
      builder: (_) => BackgroundRemovalLoadingDialog(
        previewBytes: previewBytes,
        controller: controller,
      ),
    );
  }

  static void hide(BuildContext context) {
    if (!context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  State<BackgroundRemovalLoadingDialog> createState() =>
      _BackgroundRemovalLoadingDialogState();
}

class _BackgroundRemovalLoadingDialogState
    extends State<BackgroundRemovalLoadingDialog>
    with SingleTickerProviderStateMixin {
  static const _statusKeys = <String>[
    'msg_bg_removal_step_upload',
    'msg_bg_removal_step_analyze',
    'msg_bg_removal_step_finalize',
  ];

  late final AnimationController _pulseController;
  Timer? _statusTimer;
  Timer? _progressTimer;
  int _statusIndex = 0;
  double _displayProgress = 0.08;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _statusIndex = (_statusIndex + 1) % _statusKeys.length);
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (!mounted || _displayProgress >= 0.92) return;
      setState(() {
        final delta = (0.92 - _displayProgress) * 0.06;
        _displayProgress = (_displayProgress + delta).clamp(0.08, 0.92);
      });
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _progressTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get _activeStep {
    if (_displayProgress >= 0.75) return 2;
    if (_displayProgress >= 0.35) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildCard(context);

    if (widget.controller == null) return content;

    return ListenableBuilder(
      listenable: widget.controller!,
      builder: (context, _) {
        final state = widget.controller!.state;
        if (state.status == BackgroundRemovalStatus.validating) {
          return _buildCard(context, statusOverride: 'msg_bg_removal_step_upload'.tr);
        }
        return _buildCard(
          context,
          statusOverride: _statusKeys[_statusIndex].tr,
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, {String? statusOverride}) {
    final cs = Theme.of(context).colorScheme;
    final progressLabel = '${(_displayProgress * 100).round()}%';

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppDs.surfaceElevated,
            borderRadius: BorderRadius.circular(AppDs.radiusXl.adaptSize),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space5.h,
              AppDs.space5.v,
              AppDs.space5.h,
              AppDs.space6.v,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAiBadge(cs),
                SizedBox(height: AppDs.space5.v),
                _buildPreview(cs),
                SizedBox(height: AppDs.space5.v),
                Text(
                  'msg_removing_background'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.title(Theme.of(context)).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  'msg_bg_removal_loading_hint'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary(Theme.of(context)).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: AppDs.space5.v),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
                  child: LinearProgressIndicator(
                    minHeight: 6.v,
                    value: _displayProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: cs.primary,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    progressLabel,
                    style: AppTypography.caption(Theme.of(context)).copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
                _buildStepRow(cs),
                SizedBox(height: AppDs.space4.v),
                AnimatedSwitcher(
                  duration: AppDs.motionNormal,
                  child: Text(
                    statusOverride ?? _statusKeys[_statusIndex].tr,
                    key: ValueKey<String>(statusOverride ?? '$_statusIndex'),
                    textAlign: TextAlign.center,
                    style: AppTypography.body(Theme.of(context)).copyWith(
                      color: AppDs.textOnDarkPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: AppDs.space3.v),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16.adaptSize,
                      color: AppDs.textOnDarkDisabled,
                    ),
                    SizedBox(width: AppDs.space2.h),
                    Flexible(
                      child: Text(
                        'msg_bg_removal_keep_open'.tr,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption(Theme.of(context)).copyWith(
                          color: AppDs.textOnDarkDisabled,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBadge(ColorScheme cs) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDs.space4.h,
          vertical: AppDs.space2.v,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.22),
              cs.primary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
          border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high_rounded,
              size: 18.adaptSize,
              color: cs.primary,
            ),
            SizedBox(width: AppDs.space2.h),
            Text(
              'msg_bg_removal_processing_badge'.tr,
              style: AppTypography.caption(Theme.of(context)).copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ColorScheme cs) {
    final bytes = widget.previewBytes;
    return AspectRatio(
      aspectRatio: 1.35,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _TransparencyCheckerboard()),
              if (bytes != null)
                Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                )
              else
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40.adaptSize,
                    color: AppDs.textOnDarkDisabled,
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: AppDs.space3.h,
                bottom: AppDs.space3.v,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDs.space2.h,
                    vertical: AppDs.space1.v,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
                  ),
                  child: Text(
                    'msg_bg_removal_preview_label'.tr,
                    style: AppTypography.caption(Theme.of(context)).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(ColorScheme cs) {
    final steps = <String>[
      'msg_bg_removal_step_short_upload'.tr,
      'msg_bg_removal_step_short_analyze'.tr,
      'msg_bg_removal_step_short_done'.tr,
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = index ~/ 2;
          final done = _activeStep > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: done
                  ? cs.primary.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = _activeStep == stepIndex;
        final isDone = _activeStep > stepIndex;

        return Column(
          children: [
            AnimatedContainer(
              duration: AppDs.motionNormal,
              width: 28.adaptSize,
              height: 28.adaptSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone || isActive
                    ? cs.primary.withValues(alpha: isActive ? 0.18 : 0.28)
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: isDone || isActive
                      ? cs.primary
                      : Colors.white.withValues(alpha: 0.18),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle,
                size: isDone ? 16.adaptSize : 8.adaptSize,
                color: isDone || isActive
                    ? cs.primary
                    : AppDs.textOnDarkDisabled,
              ),
            ),
            SizedBox(height: AppDs.space1.v),
            Text(
              steps[stepIndex],
              style: AppTypography.caption(Theme.of(context)).copyWith(
                color: isDone || isActive
                    ? AppDs.textOnDarkPrimary
                    : AppDs.textOnDarkDisabled,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11.fSize,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TransparencyCheckerboard extends CustomPainter {
  const _TransparencyCheckerboard();

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 12.0;
    final white = Paint()..color = const Color(0xFF2A2A2A);
    final gray = Paint()..color = const Color(0xFF1A1A1A);
    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final isLight = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? white : gray,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
