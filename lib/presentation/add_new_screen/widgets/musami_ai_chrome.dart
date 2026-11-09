import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Shared visual language for editor AI surfaces (FAB, command bar, sheets).
///
/// Brand-aligned: dark atelier panels + yellow accent. Avoids neon/purple glow.
abstract final class MusamiAiChrome {
  static const Color panel = AppDs.surfaceRaised;
  static const Color panelDeep = AppDs.atelierInk;
  static const Color accent = AppDs.accentYellow;
  static const Color onAccent = AppDs.onAccent;
  static const Color hairline = Color(0x22FFFFFF);

  static List<BoxShadow> get softLift => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.28),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static BorderRadius get panelRadius =>
      BorderRadius.circular(AppDs.radiusLg);

  static BoxDecoration panelDecoration({bool elevated = true}) {
    return BoxDecoration(
      color: panel,
      borderRadius: panelRadius,
      border: Border.all(color: hairline),
      boxShadow: elevated ? softLift : null,
    );
  }

  static InputDecoration fieldDecoration({
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: panelDeep,
      hintText: hint,
      hintStyle: TextStyle(
        color: AppDs.textOnDarkSecondary.withValues(alpha: 0.85),
        fontSize: 14,
        height: 1.35,
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        borderSide: const BorderSide(color: hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
      suffixIcon: suffix,
    );
  }
}

/// Compact sheet title row used by AI bottom sheets.
class MusamiAiSheetHeader extends StatelessWidget {
  const MusamiAiSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppDs.radiusFull),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MusamiAiChrome.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppDs.radiusSm),
              ),
              child: Icon(icon, color: MusamiAiChrome.accent, size: 22),
            ),
            SizedBox(width: AppDs.space3.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDs.sheetTitle(theme, color: Colors.white),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: AppDs.space1.v),
                    Text(
                      subtitle!,
                      style: AppDs.sheetCaption(
                        theme,
                        color: AppDs.textOnDarkSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ],
    );
  }
}

/// Selectable mode / scale chip for AI panels.
class MusamiAiChoiceChip extends StatelessWidget {
  const MusamiAiChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? MusamiAiChrome.accent : Colors.white.withValues(alpha: 0.06);
    final fg = selected ? MusamiAiChrome.onAccent : AppDs.textOnDarkPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDs.radiusFull),
            border: Border.all(
              color: selected
                  ? MusamiAiChrome.accent
                  : MusamiAiChrome.hairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width primary AI action button (yellow).
class MusamiAiPrimaryButton extends StatelessWidget {
  const MusamiAiPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDs.buttonHeight,
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: MusamiAiChrome.accent,
          foregroundColor: MusamiAiChrome.onAccent,
          disabledBackgroundColor: MusamiAiChrome.accent.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: MusamiAiChrome.onAccent,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary ghost button for AI sheets.
class MusamiAiGhostButton extends StatelessWidget {
  const MusamiAiGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppDs.textOnDarkSecondary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        child: Text(label),
      ),
    );
  }
}
