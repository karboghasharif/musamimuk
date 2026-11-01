import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

String printSar(num amount) => 'SAR ${amount.toStringAsFixed(2)}';

String printLocalizedLabel(String? en, String? ar) {
  final code = AppLocalization.activeLanguageCode();
  if (code == 'ar' && (ar?.isNotEmpty ?? false)) return ar!;
  return en ?? '';
}

/// Brass stamp for shop/rider level (replaces Material [Chip]).
class PrintLevelBadge extends StatelessWidget {
  const PrintLevelBadge({super.key, this.label, this.labelAr});

  final String? label;
  final String? labelAr;

  @override
  Widget build(BuildContext context) {
    final text = printLocalizedLabel(label, labelAr);
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space3.h,
        vertical: 6.v,
      ),
      decoration: BoxDecoration(
        color: AppDs.atelierBrass.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        border: Border.all(color: AppDs.atelierBrass.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: AppTypography.caption(Theme.of(context)).copyWith(
          color: AppDs.atelierBrass,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Level hint + thin brass rail under the desk hero.
class PrintLevelRail extends StatelessWidget {
  const PrintLevelRail({super.key, this.progress});

  final PrintLevelProgress? progress;

  @override
  Widget build(BuildContext context) {
    final hint = progress?.hint?.trim();
    if (hint == null || hint.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: AppDs.space3.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3.v,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDs.radiusFull),
              gradient: LinearGradient(
                colors: [
                  AppDs.atelierBrass,
                  AppDs.atelierBrass.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          SizedBox(height: AppDs.space2.v),
          Text(
            hint,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiet metric cells separated by hairlines (not stacked SaaS cards).
class PrintMetricStrip extends StatelessWidget {
  const PrintMetricStrip({super.key, required this.items});

  final List<(String value, String label)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 36.v,
              color: AppDs.atelierHairline(0.14),
            ),
          Expanded(
            child: Column(
              children: [
                Text(
                  items[i].$1,
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20.fSize,
                  ),
                ),
                SizedBox(height: 2.v),
                Text(
                  items[i].$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    fontSize: 11.fSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Shop floor / rider dispatch identity plate.
class PrintDeskHero extends StatelessWidget {
  const PrintDeskHero({
    super.key,
    required this.name,
    required this.statusLabel,
    required this.statusActive,
    this.subtitle,
    this.levelLabel,
    this.levelLabelAr,
    this.levelProgress,
    this.metrics = const [],
    this.leadingIcon = Icons.storefront_outlined,
  });

  final String name;
  final String statusLabel;
  final bool statusActive;
  final String? subtitle;
  final String? levelLabel;
  final String? levelLabelAr;
  final PrintLevelProgress? levelProgress;
  final List<(String value, String label)> metrics;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    final statusColor =
        statusActive ? AppDs.atelierBrass : AppDs.textOnDarkSecondary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space4.v,
              AppDs.space4.h,
              AppDs.space3.v,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppDs.atelierBrass.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56.adaptSize,
                  height: 56.adaptSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDs.atelierInk.withValues(alpha: 0.65),
                    border: Border.all(color: AppDs.atelierBrass, width: 1.5),
                  ),
                  child: Text(
                    initial,
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.atelierBrass,
                      fontWeight: FontWeight.w800,
                      fontSize: 22.fSize,
                    ),
                  ),
                ),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppDs.sheetTitle(
                          theme,
                          color: AppDs.textOnDarkPrimary,
                        ),
                      ),
                      SizedBox(height: AppDs.space1.v),
                      Row(
                        children: [
                          Icon(leadingIcon, size: 14.adaptSize, color: statusColor),
                          SizedBox(width: 6.h),
                          Flexible(
                            child: Text(
                              statusLabel,
                              style: AppTypography.caption(theme).copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        SizedBox(height: AppDs.space1.v),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(theme).copyWith(
                            color: AppDs.textOnDarkSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: AppDs.space2.h),
                PrintLevelBadge(label: levelLabel, labelAr: levelLabelAr),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              0,
              AppDs.space4.h,
              AppDs.space4.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PrintLevelRail(progress: levelProgress),
                if (metrics.isNotEmpty) ...[
                  SizedBox(height: AppDs.space4.v),
                  PrintMetricStrip(items: metrics),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Directed empty state for queues / reviews (invitation, not a shrug).
class PrintEmptyWork extends StatelessWidget {
  const PrintEmptyWork({
    super.key,
    required this.icon,
    required this.title,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space4.h,
        vertical: AppDs.space6.v,
      ),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierHairline(0.1)),
      ),
      child: Column(
        children: [
          Container(
            width: 52.adaptSize,
            height: 52.adaptSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppDs.atelierBrass.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AppDs.atelierBrass, size: 26.adaptSize),
          ),
          SizedBox(height: AppDs.space3.v),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (body != null && body!.trim().isNotEmpty) ...[
            SizedBox(height: AppDs.space1.v),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.textOnDarkSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section title used above queues on desk homes.
class PrintSectionTitle extends StatelessWidget {
  const PrintSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppDs.sheetTitle(
        Theme.of(context),
        color: AppDs.textOnDarkPrimary,
      ).copyWith(fontSize: 18.fSize),
    );
  }
}

class PrintVerifiedReviewList extends StatelessWidget {
  const PrintVerifiedReviewList({super.key, required this.reviews});

  final List<PrintReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return PrintEmptyWork(
        icon: Icons.star_outline_rounded,
        title: 'msg_print_no_reviews'.tr,
        body: 'msg_print_reviews_empty_hint'.tr,
      );
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: reviews
          .map(
            (review) => Padding(
              padding: EdgeInsets.only(bottom: AppDs.space2.v),
              child: Container(
                padding: EdgeInsets.all(AppDs.space3.h),
                decoration: BoxDecoration(
                  color: AppDs.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppDs.radiusMd),
                  border: Border.all(color: AppDs.atelierHairline(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.overall.toStringAsFixed(1)} ★ · ${'lbl_print_verified_review'.tr}',
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.atelierBrass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: AppDs.space1.v),
                        child: Text(
                          review.comment!,
                          style: AppTypography.secondary(theme).copyWith(
                            color: AppDs.textOnDarkSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Rider online control — status plate instead of a bare SwitchListTile.
class PrintOnlineStatusTile extends StatelessWidget {
  const PrintOnlineStatusTile({
    super.key,
    required this.online,
    required this.onChanged,
    this.busy = false,
  });

  final bool online;
  final ValueChanged<bool>? onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = online ? AppDs.atelierBrass : AppDs.textOnDarkSecondary;
    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(
          color: online
              ? AppDs.atelierBrass.withValues(alpha: 0.45)
              : AppDs.atelierHairline(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48.adaptSize,
            height: 48.adaptSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
            ),
            child: Icon(
              online ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: color,
            ),
          ),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  online
                      ? 'lbl_print_online_active'.tr
                      : 'lbl_print_online_idle'.tr,
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.v),
                Text(
                  online
                      ? 'msg_print_online_active_hint'.tr
                      : 'msg_print_online_idle_hint'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            SizedBox(
              width: 22.adaptSize,
              height: 22.adaptSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: online,
              activeThumbColor: AppDs.atelierBrass,
              activeTrackColor: AppDs.atelierBrass.withValues(alpha: 0.35),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class PrintScaffold extends StatelessWidget {
  const PrintScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.showBack = true,
    this.drawer,
    this.leading,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? floatingActionButton;
  final bool showBack;
  final Widget? drawer;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final hasDrawer = drawer != null;
    return Scaffold(
      backgroundColor: AppDs.atelierInk,
      drawer: drawer,
      appBar: CustomAppBar(
        leading: leading ??
            (showBack
                ? AppbarLeadingImage(
                    imagePath: ImageConstant.imgArrowLeftPrimary,
                    onTap: () => Navigator.of(context).pop(),
                  )
                : hasDrawer
                    ? Builder(
                        builder: (ctx) => IconButton(
                          tooltip: MaterialLocalizations.of(ctx)
                              .openAppDrawerTooltip,
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: Icon(
                            Icons.menu_rounded,
                            color: AppDs.atelierBrass,
                            size: 24.adaptSize,
                          ),
                        ),
                      )
                    : const SizedBox(width: 48)),
        centerTitle: true,
        title: AppbarTitle(text: title),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottom,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Compact press-slip row for order queues (tap → full ticket).
class PrintOrderSlip extends StatelessWidget {
  const PrintOrderSlip({
    super.key,
    required this.order,
    required this.onTap,
    this.preview,
  });

  final PrintOrder order;
  final VoidCallback onTap;
  final String? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = order.status == 'quote';
    final customer = (order.customerName ?? '').trim();
    final design = (order.designName ?? '').trim();
    final subtitle = [
      if (customer.isNotEmpty) customer,
      if (design.isNotEmpty) design,
      if ((order.fulfillment ?? '').isNotEmpty)
        order.fulfillment == 'delivery'
            ? 'lbl_print_deliver_to_me'.tr
            : 'lbl_print_pick_up'.tr,
    ].join(' · ');
    final hint = (preview ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: urgent
                  ? AppDs.atelierBrass.withValues(alpha: 0.4)
                  : AppDs.atelierHairline(0.12),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3.h,
                  decoration: BoxDecoration(
                    color: urgent
                        ? AppDs.atelierBrass
                        : AppDs.atelierHairline(0.2),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(AppDs.radiusMd),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppDs.space3.h,
                      AppDs.space3.v,
                      AppDs.space2.h,
                      AppDs.space3.v,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#${order.number}',
                                    style: AppTypography.body(theme).copyWith(
                                      color: AppDs.atelierBrass,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20.fSize,
                                      height: 1,
                                    ),
                                  ),
                                  SizedBox(width: AppDs.space2.h),
                                  PrintStatusStamp(
                                    label:
                                        'lbl_print_status_${order.status}'.tr,
                                    urgent: urgent,
                                  ),
                                ],
                              ),
                              if (subtitle.isNotEmpty) ...[
                                SizedBox(height: AppDs.space1.v),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption(theme).copyWith(
                                    color: AppDs.textOnDarkPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (hint.isNotEmpty) ...[
                                SizedBox(height: 2.v),
                                Text(
                                  hint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption(theme).copyWith(
                                    color: AppDs.textOnDarkSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppDs.textOnDarkSecondary,
                          size: 22.adaptSize,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inbox row for an order conversation thread.
class PrintConversationSlip extends StatelessWidget {
  const PrintConversationSlip({
    super.key,
    required this.order,
    required this.onTap,
    this.peerName,
    this.threadLabel,
  });

  final PrintOrder order;
  final VoidCallback onTap;
  final String? peerName;
  final String? threadLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chats = order.messages
        .where(
          (m) => m.thread == 'customer_shop' && m.from != 'system',
        )
        .toList();
    final last = chats.isEmpty ? null : chats.last;
    final title = (peerName ?? '').trim().isNotEmpty
        ? peerName!.trim()
        : (order.customerName ?? order.shop?.name ?? '#${order.number}');
    final preview = (last?.body ?? '').trim().isNotEmpty
        ? last!.body.trim()
        : 'msg_print_chat_start'.tr;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(color: AppDs.atelierHairline(0.12)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space3.h,
              AppDs.space3.v,
              AppDs.space2.h,
              AppDs.space3.v,
            ),
            child: Row(
              children: [
                Container(
                  width: 44.adaptSize,
                  height: 44.adaptSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDs.atelierBrass.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppDs.atelierBrass.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    color: AppDs.atelierBrass,
                    size: 20.adaptSize,
                  ),
                ),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body(theme).copyWith(
                                color: AppDs.textOnDarkPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '#${order.number}',
                            style: AppTypography.caption(theme).copyWith(
                              color: AppDs.atelierBrass,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.v),
                      Text(
                        [
                          if ((threadLabel ?? '').isNotEmpty) threadLabel!,
                          'lbl_print_status_${order.status}'.tr,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(theme).copyWith(
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                      SizedBox(height: AppDs.space1.v),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(theme).copyWith(
                          color: AppDs.textOnDarkSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppDs.textOnDarkSecondary,
                  size: 22.adaptSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrintGoldButton extends StatelessWidget {
  const PrintGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppDs.printGold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: AppDs.printGold.withValues(alpha: 0.4),
        minimumSize: Size(double.infinity, AppDs.buttonHeight.v),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 22.adaptSize,
              height: 22.adaptSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.fSize,
              ),
            ),
    );
  }
}

/// Quiet outlined action for secondary print CTAs.
class PrintGhostButton extends StatelessWidget {
  const PrintGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: loading ? null : onPressed,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: 18.adaptSize, color: AppDs.atelierBrass),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppDs.textOnDarkPrimary,
        side: BorderSide(color: AppDs.atelierHairline(0.22)),
        minimumSize: Size(double.infinity, 44.v),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
        ),
      ),
    );
  }
}

/// Status stamp for a job ticket (not a Material Chip).
class PrintStatusStamp extends StatelessWidget {
  const PrintStatusStamp({
    super.key,
    required this.label,
    this.urgent = false,
  });

  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final color = urgent ? AppDs.atelierBrass : AppDs.textOnDarkSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space3.h,
        vertical: 6.v,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: AppTypography.caption(Theme.of(context)).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Compact fact pills for print size / qty / paper / ink.
class PrintSpecPills extends StatelessWidget {
  const PrintSpecPills({super.key, required this.spec});

  final PrintSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pills = <String>[
      'lbl_print_size_${spec.sizeId}'.tr,
      '${spec.quantity}',
      'lbl_print_paper_${spec.paper}'.tr,
      spec.sides == 2
          ? 'lbl_print_sides_double'.tr
          : 'lbl_print_sides_single'.tr,
      spec.color == 'bw'
          ? 'lbl_print_ink_bw'.tr
          : 'lbl_print_ink_color'.tr,
      ...spec.finishing.map((id) => 'lbl_print_finish_$id'.tr),
    ];
    return Wrap(
      spacing: AppDs.space2.h,
      runSpacing: AppDs.space2.v,
      children: [
        for (final pill in pills)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space3.h,
              vertical: 6.v,
            ),
            decoration: BoxDecoration(
              color: AppDs.atelierInk.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppDs.radiusSm),
              border: Border.all(color: AppDs.atelierHairline(0.12)),
            ),
            child: Text(
              pill,
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.textOnDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// Press-room job ticket shell — brass spine marks a new incoming request.
class PrintJobTicket extends StatelessWidget {
  const PrintJobTicket({
    super.key,
    required this.jobNumber,
    required this.statusLabel,
    required this.child,
    this.title,
    this.subtitle,
    this.urgent = false,
  });

  final int jobNumber;
  final String statusLabel;
  final String? title;
  final String? subtitle;
  final bool urgent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(
          color: urgent
              ? AppDs.atelierBrass.withValues(alpha: 0.45)
              : AppDs.atelierHairline(0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4.h,
              color: urgent
                  ? AppDs.atelierBrass
                  : AppDs.atelierHairline(0.18),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDs.space4.h,
                  AppDs.space4.v,
                  AppDs.space4.h,
                  AppDs.space4.v,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$jobNumber',
                                style: AppTypography.body(theme).copyWith(
                                  color: AppDs.atelierBrass,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 28.fSize,
                                  height: 1,
                                ),
                              ),
                              if (title != null && title!.trim().isNotEmpty) ...[
                                SizedBox(height: AppDs.space2.v),
                                Text(
                                  title!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.body(theme).copyWith(
                                    color: AppDs.textOnDarkPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (subtitle != null &&
                                  subtitle!.trim().isNotEmpty) ...[
                                SizedBox(height: 2.v),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption(theme).copyWith(
                                    color: AppDs.textOnDarkSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: AppDs.space2.h),
                        PrintStatusStamp(
                          label: statusLabel,
                          urgent: urgent,
                        ),
                      ],
                    ),
                    SizedBox(height: AppDs.space4.v),
                    child,
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

/// Live “new job” pulse on the shop desk — quieter than a solid gold bar.
class PrintNewJobBanner extends StatelessWidget {
  const PrintNewJobBanner({
    super.key,
    required this.jobNumber,
    required this.customerName,
    required this.onOpen,
    required this.onDismiss,
  });

  final int jobNumber;
  final String customerName;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDs.radiusLg),
            gradient: LinearGradient(
              colors: [
                AppDs.atelierBrass.withValues(alpha: 0.22),
                AppDs.surfaceRaised,
              ],
            ),
            border: Border.all(color: AppDs.atelierBrass.withValues(alpha: 0.55)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space3.v,
              AppDs.space2.h,
              AppDs.space3.v,
            ),
            child: Row(
              children: [
                Container(
                  width: 44.adaptSize,
                  height: 44.adaptSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDs.atelierBrass.withValues(alpha: 0.18),
                    border: Border.all(color: AppDs.atelierBrass),
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    color: AppDs.atelierBrass,
                    size: 22.adaptSize,
                  ),
                ),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'lbl_print_new_request'.tr,
                        style: AppTypography.caption(theme).copyWith(
                          color: AppDs.atelierBrass,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '#$jobNumber · $customerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(theme).copyWith(
                          color: AppDs.textOnDarkPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onOpen,
                  child: Text('lbl_print_open_request'.tr),
                ),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: AppDs.textOnDarkSecondary,
                    size: 20.adaptSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration printTicketField(String label) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
      filled: true,
      fillColor: AppDs.atelierInk.withValues(alpha: 0.55),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        borderSide: BorderSide(color: AppDs.atelierHairline(0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        borderSide: const BorderSide(color: AppDs.atelierBrass),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
      ),
    );

/// Job-ticket section: title + optional hint + body (no Material chip chrome).
class PrintTicketSection extends StatelessWidget {
  const PrintTicketSection({
    super.key,
    required this.title,
    required this.child,
    this.hint,
  });

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTypography.body(theme).copyWith(
            color: AppDs.textOnDarkPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16.fSize,
          ),
        ),
        if (hint != null && hint!.trim().isNotEmpty) ...[
          SizedBox(height: AppDs.space1.v),
          Text(
            hint!,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.35,
            ),
          ),
        ],
        SizedBox(height: AppDs.space3.v),
        child,
      ],
    );
  }
}

/// Relative paper silhouette for the size picker.
class PrintSizeTile extends StatelessWidget {
  const PrintSizeTile({
    super.key,
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.aspectW,
    required this.aspectH,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double aspectW;
  final double aspectH;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSide = 36.adaptSize;
    final scale = maxSide / (aspectW > aspectH ? aspectW : aspectH);
    final w = (aspectW * scale).clamp(10.0, maxSide);
    final h = (aspectH * scale).clamp(10.0, maxSide);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space2.h,
            vertical: AppDs.space3.v,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppDs.atelierBrass.withValues(alpha: 0.14)
                : AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: selected
                  ? AppDs.atelierBrass
                  : AppDs.atelierHairline(0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  color: selected
                      ? AppDs.atelierBrass.withValues(alpha: 0.85)
                      : AppDs.atelierHairline(0.18),
                  borderRadius: BorderRadius.circular(3),
                  border: id == 'custom'
                      ? Border.all(
                          color: selected
                              ? AppDs.atelierBrass
                              : AppDs.textOnDarkSecondary,
                          width: 1.2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        )
                      : null,
                ),
                child: id == 'custom'
                    ? Icon(
                        Icons.add,
                        size: 14.adaptSize,
                        color: selected
                            ? AppDs.atelierInk
                            : AppDs.textOnDarkSecondary,
                      )
                    : null,
              ),
              SizedBox(height: AppDs.space2.v),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(theme).copyWith(
                  color: selected
                      ? AppDs.atelierBrass
                      : AppDs.textOnDarkPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.fSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quantity plate: large count + stepper + quick presets (replaces slider).
class PrintQtyPlate extends StatelessWidget {
  const PrintQtyPlate({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 10,
    this.max = 2000,
    this.step = 10,
    this.presets = const [50, 100, 250, 500, 1000],
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final List<int> presets;

  void _bump(int delta) {
    final next = (value + delta).clamp(min, max);
    if (next != value) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap: value > min ? () => _bump(-step) : null,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$value',
                      style: AppTypography.body(theme).copyWith(
                        color: AppDs.atelierBrass,
                        fontWeight: FontWeight.w800,
                        fontSize: 36.fSize,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: AppDs.space1.v),
                    Text(
                      'lbl_print_copies'.tr,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap: value < max ? () => _bump(step) : null,
              ),
            ],
          ),
          SizedBox(height: AppDs.space4.v),
          Wrap(
            spacing: AppDs.space2.h,
            runSpacing: AppDs.space2.v,
            alignment: WrapAlignment.center,
            children: presets
                .map(
                  (p) => _PresetPill(
                    label: '$p',
                    selected: value == p,
                    onTap: () => onChanged(p.clamp(min, max)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: Container(
          width: AppDs.minTap.adaptSize,
          height: AppDs.minTap.adaptSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled
                ? AppDs.atelierBrass.withValues(alpha: 0.14)
                : AppDs.atelierHairline(0.06),
            border: Border.all(
              color: enabled
                  ? AppDs.atelierBrass.withValues(alpha: 0.55)
                  : AppDs.atelierHairline(0.1),
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? AppDs.atelierBrass : AppDs.textOnDarkDisabled,
            size: 22.adaptSize,
          ),
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  const _PresetPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: AppDs.space2.v,
          ),
          decoration: BoxDecoration(
            color: selected ? AppDs.atelierBrass : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDs.radiusFull),
            border: Border.all(
              color: selected
                  ? AppDs.atelierBrass
                  : AppDs.atelierHairline(0.16),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption(Theme.of(context)).copyWith(
              color: selected ? AppDs.atelierInk : AppDs.textOnDarkSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact selectable tile for paper / finishing (replaces ChoiceChip).
class PrintSelectTile extends StatelessWidget {
  const PrintSelectTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.multi = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: AppDs.space3.v,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppDs.atelierBrass.withValues(alpha: 0.16)
                : AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: selected
                  ? AppDs.atelierBrass
                  : AppDs.atelierHairline(0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16.adaptSize,
                  color: selected
                      ? AppDs.atelierBrass
                      : AppDs.textOnDarkSecondary,
                ),
                SizedBox(width: 6.h),
              ] else if (selected && multi) ...[
                Icon(
                  Icons.check,
                  size: 14.adaptSize,
                  color: AppDs.atelierBrass,
                ),
                SizedBox(width: 4.h),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.caption(theme).copyWith(
                    color: selected
                        ? AppDs.atelierBrass
                        : AppDs.textOnDarkPrimary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dual rail for exclusive choices (sides / ink) — replaces SwitchListTile.
class PrintChoiceRail extends StatelessWidget {
  const PrintChoiceRail({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<(String id, String label, IconData icon)> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppDs.space1.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Row(
        children: [
          for (final opt in options)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(opt.$1),
                  borderRadius: BorderRadius.circular(AppDs.radiusSm),
                  child: AnimatedContainer(
                    duration: AppDs.motionFast,
                    padding: EdgeInsets.symmetric(vertical: AppDs.space3.v),
                    decoration: BoxDecoration(
                      color: selectedId == opt.$1
                          ? AppDs.atelierBrass
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDs.radiusSm),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt.$3,
                          size: 20.adaptSize,
                          color: selectedId == opt.$1
                              ? AppDs.atelierInk
                              : AppDs.textOnDarkSecondary,
                        ),
                        SizedBox(height: 4.v),
                        Text(
                          opt.$2,
                          textAlign: TextAlign.center,
                          style: AppTypography.caption(
                            Theme.of(context),
                          ).copyWith(
                            color: selectedId == opt.$1
                                ? AppDs.atelierInk
                                : AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.fSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pickup vs delivery as equal cards (not chips).
class PrintFulfillmentCard extends StatelessWidget {
  const PrintFulfillmentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        child: AnimatedContainer(
          duration: AppDs.motionFast,
          padding: EdgeInsets.all(AppDs.space3.h),
          decoration: BoxDecoration(
            color: selected
                ? AppDs.atelierBrass.withValues(alpha: 0.14)
                : AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusLg),
            border: Border.all(
              color: selected
                  ? AppDs.atelierBrass
                  : AppDs.atelierHairline(0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected
                        ? AppDs.atelierBrass
                        : AppDs.textOnDarkSecondary,
                    size: 22.adaptSize,
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: AppDs.atelierBrass,
                      size: 18.adaptSize,
                    ),
                ],
              ),
              SizedBox(height: AppDs.space2.v),
              Text(
                title,
                style: AppTypography.body(theme).copyWith(
                  color: selected
                      ? AppDs.atelierBrass
                      : AppDs.textOnDarkPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.fSize,
                ),
              ),
              SizedBox(height: 2.v),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(theme).copyWith(
                  color: AppDs.textOnDarkSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky footer strip: live job line + CTA.
class PrintSpecFooter extends StatelessWidget {
  const PrintSpecFooter({
    super.key,
    required this.summary,
    required this.ctaLabel,
    required this.onPressed,
    this.loading = false,
  });

  final String summary;
  final String ctaLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        AppDs.space3.v,
        AppDs.space4.h,
        AppDs.space4.v + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppDs.atelierInk,
        border: Border(
          top: BorderSide(color: AppDs.atelierHairline(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: AppDs.space3.v),
          PrintGoldButton(
            label: ctaLabel,
            loading: loading,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
