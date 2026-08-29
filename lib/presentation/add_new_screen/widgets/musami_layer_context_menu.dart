import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_design_tokens.dart';

/// Gap between the anchor (the button that opened the menu) and the panel.
const double _kAnchorGap = 8;

/// Margin kept between the panel and the screen edges / safe area.
const double _kViewportMargin = 12;

const double _kMenuWidth = 292;
const double _kSubmenuWidth = 236;
const double _kRowHeight = 46;

/// A single tappable row of the layer context menu.
class MusamiContextMenuItem {
  const MusamiContextMenuItem({
    required this.icon,
    required this.label,
    this.shortcut,
    this.onSelected,
    this.submenu,
    this.enabled = true,
    this.destructive = false,
  }) : assert(
         onSelected == null || submenu == null,
         'A row either runs an action or opens a submenu, not both.',
       );

  final IconData icon;
  final String label;

  /// Trailing hint such as `⌘C` or `DELETE`. Purely informational on mobile.
  final String? shortcut;

  /// Runs after the menu has closed, so the action may safely open a dialog or
  /// sheet. Must not capture the menu's own [BuildContext].
  final VoidCallback? onSelected;

  /// When set, the row shows a chevron and opens a nested menu instead of
  /// running an action.
  final List<MusamiContextMenuSection> Function()? submenu;

  final bool enabled;

  /// Renders the row in the theme's error colour (used by Delete).
  final bool destructive;

  bool get isInteractive => enabled && (onSelected != null || submenu != null);
}

/// A group of rows separated from its neighbours by a divider.
class MusamiContextMenuSection {
  const MusamiContextMenuSection(this.items);

  final List<MusamiContextMenuItem> items;
}

/// Global bounds of the widget owning [context], used to anchor the menu.
Rect? musamiAnchorRectFromContext(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  final topLeft = box.localToGlobal(Offset.zero);
  return topLeft & box.size;
}

/// Opens the Canva-style contextual menu anchored to [anchorRect].
///
/// Returns `true` when a row ran an action, so a parent menu can close itself
/// after one of its submenu rows was used.
///
/// Implemented as a [PopupRoute] rather than a raw [OverlayEntry]: the route is
/// owned by the navigator, so it can never be orphaned, is disposed with the
/// screen, and gets barrier dismissal for free.
Future<bool?> showMusamiLayerContextMenu({
  required BuildContext context,
  required Rect anchorRect,
  required List<MusamiContextMenuSection> sections,
  double width = _kMenuWidth,
  bool isSubmenu = false,
}) {
  // Only one menu at a time: when a popup is already up, the caller's route is
  // no longer the top one. Derived from the navigator, so there is no global
  // flag that can get stuck after a dispose.
  if (!isSubmenu && !(ModalRoute.of(context)?.isCurrent ?? true)) {
    return Future<bool?>.value();
  }
  return Navigator.of(context, rootNavigator: true).push<bool>(
    _MusamiContextMenuRoute(
      anchorRect: anchorRect,
      sections: sections,
      width: width,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

class _MusamiContextMenuRoute extends PopupRoute<bool> {
  _MusamiContextMenuRoute({
    required this.anchorRect,
    required this.sections,
    required this.width,
    required this.barrierLabel,
  });

  final Rect anchorRect;
  final List<MusamiContextMenuSection> sections;
  final double width;

  @override
  final String barrierLabel;

  /// Transparent but present: tapping anywhere outside the panel pops the
  /// route, which is the outside-tap dismissal.
  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => AppDs.tapFade;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    return CustomSingleChildLayout(
      delegate: _MusamiContextMenuLayout(
        anchorRect: anchorRect,
        viewportPadding: media.padding + media.viewInsets,
        preferredWidth: width,
      ),
      child: _MusamiContextMenuPanel(sections: sections),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );
  }
}

/// Places the panel next to the anchor and keeps it fully on screen.
class _MusamiContextMenuLayout extends SingleChildLayoutDelegate {
  _MusamiContextMenuLayout({
    required this.anchorRect,
    required this.viewportPadding,
    required this.preferredWidth,
  });

  final Rect anchorRect;
  final EdgeInsets viewportPadding;
  final double preferredWidth;

  EdgeInsets _margins() {
    return EdgeInsets.fromLTRB(
      viewportPadding.left + _kViewportMargin,
      viewportPadding.top + _kViewportMargin,
      viewportPadding.right + _kViewportMargin,
      viewportPadding.bottom + _kViewportMargin,
    );
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final margins = _margins();
    final availableWidth = math.max(
      160.0,
      constraints.maxWidth - margins.horizontal,
    );
    final availableHeight = math.max(
      120.0,
      constraints.maxHeight - margins.vertical,
    );
    return BoxConstraints(
      minWidth: math.min(preferredWidth, availableWidth),
      maxWidth: math.min(preferredWidth, availableWidth),
      maxHeight: availableHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final margins = _margins();

    // The editor toolbars live at the bottom, so opening upwards is the natural
    // direction; fall back to below the anchor when there is no room above.
    final spaceAbove = anchorRect.top - margins.top - _kAnchorGap;
    final spaceBelow =
        size.height - anchorRect.bottom - margins.bottom - _kAnchorGap;

    double dy;
    if (childSize.height <= spaceAbove) {
      dy = anchorRect.top - _kAnchorGap - childSize.height;
    } else if (childSize.height <= spaceBelow) {
      dy = anchorRect.bottom + _kAnchorGap;
    } else {
      // Neither side fits: pin to the roomier side; the panel scrolls.
      dy = spaceAbove >= spaceBelow
          ? margins.top
          : size.height - margins.bottom - childSize.height;
    }

    var dx = anchorRect.center.dx - childSize.width / 2;
    final maxDx = math.max(
      margins.left,
      size.width - margins.right - childSize.width,
    );
    final maxDy = math.max(
      margins.top,
      size.height - margins.bottom - childSize.height,
    );
    dx = dx.clamp(margins.left, maxDx);
    dy = dy.clamp(margins.top, maxDy);
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_MusamiContextMenuLayout oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        viewportPadding != oldDelegate.viewportPadding ||
        preferredWidth != oldDelegate.preferredWidth;
  }
}

class _MusamiContextMenuPanel extends StatelessWidget {
  const _MusamiContextMenuPanel({required this.sections});

  final List<MusamiContextMenuSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final populated = sections
        .where((section) => section.items.isNotEmpty)
        .toList(growable: false);

    final children = <Widget>[];
    for (var i = 0; i < populated.length; i++) {
      if (i > 0) {
        children.add(
          Divider(
            height: 9,
            thickness: 1,
            indent: AppDs.space3,
            endIndent: AppDs.space3,
            color: AppDs.textOnDarkPrimary.withValues(alpha: 0.10),
          ),
        );
      }
      children.addAll(
        populated[i].items.map((item) => _MusamiContextMenuRow(item: item)),
      );
    }

    return Material(
      color: AppDs.surfaceRaised,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppDs.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(
          iconTheme: IconThemeData(color: AppDs.textOnDarkPrimary),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppDs.space1),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _MusamiContextMenuRow extends StatelessWidget {
  const _MusamiContextMenuRow({required this.item});

  final MusamiContextMenuItem item;

  Future<void> _handleTap(BuildContext context) async {
    final navigator = Navigator.of(context);

    final submenu = item.submenu;
    if (submenu != null) {
      final anchor = musamiAnchorRectFromContext(context);
      if (anchor == null) return;
      final handled = await showMusamiLayerContextMenu(
        context: context,
        anchorRect: anchor,
        sections: submenu(),
        width: _kSubmenuWidth,
        isSubmenu: true,
      );
      if (handled == true && navigator.canPop()) navigator.pop(true);
      return;
    }

    navigator.pop(true);
    // Run after the pop so the action is free to push its own dialog/sheet.
    final action = item.onSelected;
    if (action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = item.isInteractive;

    final Color foreground;
    if (!enabled) {
      foreground = AppDs.textOnDarkDisabled;
    } else if (item.destructive) {
      foreground = theme.colorScheme.error;
    } else {
      foreground = AppDs.textOnDarkPrimary;
    }

    return InkWell(
      onTap: enabled ? () => _handleTap(context) : null,
      hoverColor: AppDs.textOnDarkPrimary.withValues(alpha: 0.06),
      child: Container(
        constraints: const BoxConstraints(minHeight: _kRowHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDs.space4,
          vertical: AppDs.space2,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: AppDs.iconSm, color: foreground),
            const SizedBox(width: AppDs.space3),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      color: foreground,
                      fontSize: AppDs.fontSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (item.shortcut != null) ...[
              const SizedBox(width: AppDs.space2),
              _ShortcutChip(label: item.shortcut!, enabled: enabled),
            ],
            if (item.submenu != null) ...[
              const SizedBox(width: AppDs.space2),
              Icon(
                Icons.chevron_right_rounded,
                size: AppDs.iconSm,
                color: foreground,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppDs.textOnDarkSecondary
        : AppDs.textOnDarkDisabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppDs.textOnDarkPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppDs.radiusSm - 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: AppDs.labelMin - 1,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
