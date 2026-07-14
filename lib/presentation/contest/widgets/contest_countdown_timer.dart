import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/contest_countdown.dart';

/// Live countdown driven by API [ContestCountdown.remainingSeconds].
class ContestCountdownTimer extends StatefulWidget {
  const ContestCountdownTimer({
    super.key,
    required this.countdown,
    this.textStyle,
    this.labelStyle,
    this.compact = false,
    this.hero = false,
  });

  final ContestCountdown? countdown;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final bool compact;
  final bool hero;

  @override
  State<ContestCountdownTimer> createState() => _ContestCountdownTimerState();
}

class _ContestCountdownTimerState extends State<ContestCountdownTimer> {
  Timer? _timer;
  int? _secondsLeft;

  @override
  void initState() {
    super.initState();
    _syncFromApi();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft != null && _secondsLeft! > 0) {
          _secondsLeft = _secondsLeft! - 1;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant ContestCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countdown != widget.countdown) {
      _syncFromApi();
    }
  }

  void _syncFromApi() {
    _secondsLeft = widget.countdown?.secondsRemainingAt(DateTime.now());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _fallbackLabel => 'Time remaining';

  @override
  Widget build(BuildContext context) {
    final cd = widget.countdown;
    if (cd == null) return const SizedBox.shrink();
    final label = cd.label?.trim();
    final seconds = _secondsLeft;
    if (seconds == null) return const SizedBox.shrink();

    final timeText = formatContestCountdown(seconds);
    final timeStyle = widget.textStyle ?? AppTypography.countdown(theme);
    final labelStyle =
        widget.labelStyle ?? AppTypography.countdownLabel(theme);
    final caption = (label != null && label.isNotEmpty) ? label : _fallbackLabel;

    if (widget.compact) {
      return Row(
        children: [
          Icon(
            Icons.timer_outlined,
            size: AppDs.iconSm.adaptSize,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: AppDs.space2.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeText, style: timeStyle.copyWith(fontSize: AppDs.fontTitle.fSize)),
                Text(caption, style: labelStyle),
              ],
            ),
          ),
        ],
      );
    }

    if (widget.hero) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            timeText,
            textAlign: TextAlign.center,
            style: timeStyle,
          ),
          SizedBox(height: AppDs.space1.v),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeText, style: timeStyle),
        SizedBox(height: AppDs.space1.v),
        Text(caption, style: labelStyle),
      ],
    );
  }
}
