import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import 'print_ui.dart';

/// Rider layout tokens — same atelier print theme as shop mode.
abstract final class RiderDs {
  static const Color accent = AppDs.atelierBrass;
  static const Color accentSoft = AppDs.printGold;
  static const Color canvas = AppDs.atelierInk;
  static const Color panel = AppDs.surfaceRaised;
  static const Color fare = AppDs.atelierBrass;
}

/// Full-width on-air control — the first thing a rider looks for.
class RiderSignalStrip extends StatelessWidget {
  const RiderSignalStrip({
    super.key,
    required this.online,
    required this.busy,
    required this.onChanged,
    this.name,
    this.plate,
    this.district,
  });

  final bool online;
  final bool busy;
  final ValueChanged<bool>? onChanged;
  final String? name;
  final String? plate;
  final String? district;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signal = online ? RiderDs.accent : AppDs.textOnDarkSecondary;
    final meta = [
      if ((plate ?? '').trim().isNotEmpty) plate!.trim(),
      if ((district ?? '').trim().isNotEmpty) district!.trim(),
    ].join('  ·  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy || onChanged == null ? null : () => onChanged!(!online),
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            color: RiderDs.panel,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(
              color: online
                  ? RiderDs.accent.withValues(alpha: 0.55)
                  : AppDs.atelierHairline(0.12),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space4.v,
              AppDs.space3.h,
              AppDs.space4.v,
            ),
            child: Row(
              children: [
                _SignalLamp(active: online, pulsing: online && !busy),
                SizedBox(width: AppDs.space3.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        online
                            ? 'lbl_print_rider_signal_live'.tr
                            : 'lbl_print_rider_signal_idle'.tr,
                        style: AppTypography.body(theme).copyWith(
                          color: signal,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 2.v),
                      Text(
                        online
                            ? 'lbl_print_online_active'.tr
                            : 'lbl_print_rider_tap_go_online'.tr,
                        style: AppTypography.caption(theme).copyWith(
                          color: AppDs.textOnDarkSecondary,
                          height: 1.3,
                        ),
                      ),
                      if ((name ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: AppDs.space2.v),
                        Text(
                          name!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(theme).copyWith(
                            color: AppDs.textOnDarkPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: signal,
                    ),
                  )
                else
                  Icon(
                    online ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
                    color: signal,
                    size: 42.adaptSize,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalLamp extends StatefulWidget {
  const _SignalLamp({required this.active, required this.pulsing});

  final bool active;
  final bool pulsing;

  @override
  State<_SignalLamp> createState() => _SignalLampState();
}

class _SignalLampState extends State<_SignalLamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SignalLamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.active ? RiderDs.accent : AppDs.textOnDarkSecondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = widget.pulsing ? _controller.value : 1.0;
        return Container(
          width: 14.adaptSize,
          height: 14.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: base.withValues(alpha: 0.4 + 0.6 * t),
            border: Border.all(
              color: base.withValues(alpha: 0.85),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal route progress for an in-progress delivery.
class RiderRouteRail extends StatelessWidget {
  const RiderRouteRail({super.key, required this.status});

  final String status;

  static const _steps = [
    ('assigned', 'lbl_print_rider_step_accept'),
    ('going_to_shop', 'lbl_print_rider_step_shop'),
    ('picked_up', 'lbl_print_rider_step_pickup'),
    ('on_route', 'lbl_print_rider_step_route'),
    ('delivered', 'lbl_print_rider_step_drop'),
  ];

  int get _index {
    switch (status) {
      case 'requested':
        return -1;
      case 'assigned':
        return 0;
      case 'going_to_shop':
        return 1;
      case 'picked_up':
        return 2;
      case 'on_route':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = _index;
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: EdgeInsets.symmetric(horizontal: 2.h),
                color: i <= current
                    ? RiderDs.accent.withValues(alpha: 0.7)
                    : AppDs.atelierHairline(0.14),
              ),
            ),
          Column(
            children: [
              Container(
                width: 10.adaptSize,
                height: 10.adaptSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current ? RiderDs.accent : RiderDs.panel,
                  border: Border.all(
                    color: i <= current
                        ? RiderDs.accent
                        : AppDs.atelierHairline(0.25),
                    width: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 4.v),
              Text(
                _steps[i].$2.tr,
                style: AppTypography.caption(theme).copyWith(
                  fontSize: 10.fSize,
                  color: i == current
                      ? RiderDs.accent
                      : AppDs.textOnDarkSecondary,
                  fontWeight:
                      i == current ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Compact strip: jobs · rating · completed — not a card grid.
class RiderStatLane extends StatelessWidget {
  const RiderStatLane({
    super.key,
    required this.jobs,
    required this.rating,
    required this.completed,
  });

  final int jobs;
  final double rating;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String value, String label) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.body(theme).copyWith(
                color: AppDs.textOnDarkPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 20.fSize,
              ),
            ),
            SizedBox(height: 2.v),
            Text(
              label,
              style: AppTypography.caption(theme).copyWith(
                color: AppDs.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space1.h),
      child: Row(
        children: [
          cell('$jobs', 'lbl_print_jobs'.tr),
          Container(
            width: 1,
            height: 28.v,
            color: AppDs.atelierHairline(0.12),
          ),
          SizedBox(width: AppDs.space3.h),
          cell(rating.toStringAsFixed(1), 'lbl_print_desk_rating'.tr),
          Container(
            width: 1,
            height: 28.v,
            color: AppDs.atelierHairline(0.12),
          ),
          SizedBox(width: AppDs.space3.h),
          cell('$completed', 'lbl_print_desk_done'.tr),
        ],
      ),
    );
  }
}

String? riderNextAction(PrintDeliveryInfo job) {
  switch (job.status) {
    case 'requested':
      return 'accept';
    case 'assigned':
      return 'going_to_shop';
    case 'going_to_shop':
      return job.arrivedShopAt == null ? 'arrive_shop' : 'pickup';
    case 'picked_up':
      return 'on_route';
    case 'on_route':
      return job.arrivedCustomerAt == null ? 'arrive_customer' : null;
    default:
      return null;
  }
}

bool riderJobIsActive(PrintDeliveryInfo job) {
  return !const {
    'requested',
    'delivered',
    'failed',
    'cancelled',
  }.contains(job.status);
}

/// Dominant board for the job the rider is currently running.
class RiderRunBoard extends StatelessWidget {
  const RiderRunBoard({
    super.key,
    required this.job,
    required this.busy,
    required this.onAction,
    this.pickupController,
    this.onChat,
    this.onReview,
  });

  final PrintDeliveryInfo job;
  final bool busy;
  final VoidCallback? onAction;
  final TextEditingController? pickupController;
  final VoidCallback? onChat;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = riderNextAction(job);
    final shop = (job.shopName ?? '').trim();
    final address = (job.address ?? '').trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RiderDs.panel,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(
          color: RiderDs.accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space3.v,
              AppDs.space4.h,
              AppDs.space3.v,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppDs.atelierHairline(0.1)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'lbl_print_rider_active_run'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: RiderDs.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'lbl_print_status_${job.status}'.tr,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(AppDs.space4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RiderRouteRail(status: job.status),
                SizedBox(height: AppDs.space4.v),
                _RouteEndpoint(
                  icon: Icons.storefront_outlined,
                  label: 'lbl_print_rider_step_shop'.tr,
                  value: shop.isEmpty ? '—' : shop,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 11.h),
                  child: Container(
                    width: 2,
                    height: 16.v,
                    color: RiderDs.accent.withValues(alpha: 0.35),
                  ),
                ),
                _RouteEndpoint(
                  icon: Icons.place_outlined,
                  label: 'lbl_print_delivery_address'.tr,
                  value: address.isEmpty ? '—' : address,
                ),
                SizedBox(height: AppDs.space3.v),
                Row(
                  children: [
                    Text(
                      printSar(job.expectedEarning),
                      style: AppTypography.body(theme).copyWith(
                        color: RiderDs.fare,
                        fontWeight: FontWeight.w800,
                        fontSize: 22.fSize,
                      ),
                    ),
                    SizedBox(width: AppDs.space2.h),
                    Text(
                      'lbl_print_expected_earning'.tr,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${job.distanceKm.toStringAsFixed(1)} km',
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (action == 'pickup' && pickupController != null) ...[
                  SizedBox(height: AppDs.space3.v),
                  TextField(
                    controller: pickupController,
                    style: const TextStyle(color: AppDs.textOnDarkPrimary),
                    decoration: printTicketField('lbl_print_pickup_code'.tr),
                  ),
                ],
                if (action != null) ...[
                  SizedBox(height: AppDs.space3.v),
                  _RiderActionButton(
                    label: 'lbl_print_rider_action_$action'.tr,
                    loading: busy,
                    emphasize: true,
                    onPressed: onAction,
                  ),
                ],
                if (onChat != null || onReview != null) ...[
                  SizedBox(height: AppDs.space2.v),
                  PrintTextActionRow(
                    actions: [
                      if (onChat != null)
                        ('lbl_print_rider_chat'.tr, onChat),
                      if (onReview != null)
                        ('lbl_print_review_customer'.tr, onReview),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.adaptSize, color: RiderDs.accent),
        SizedBox(width: AppDs.space2.h),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption(theme).copyWith(
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
              Text(
                value,
                style: AppTypography.body(theme).copyWith(
                  color: AppDs.textOnDarkPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Open call / queue slip — lean, tappable hierarchy.
class RiderDispatchSlip extends StatelessWidget {
  const RiderDispatchSlip({
    super.key,
    required this.job,
    required this.busy,
    required this.onAction,
    this.expanded = false,
    this.pickupController,
    this.onChat,
    this.onReview,
  });

  final PrintDeliveryInfo job;
  final bool busy;
  final VoidCallback? onAction;
  final bool expanded;
  final TextEditingController? pickupController;
  final VoidCallback? onChat;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = riderNextAction(job);
    final open = job.status == 'requested';
    final shop = (job.shopName ?? '').trim();
    final address = (job.address ?? '').trim();
    final area = (job.areaCode ?? '').trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(
          color: open
              ? RiderDs.fare.withValues(alpha: 0.45)
              : AppDs.atelierHairline(0.12),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4.h,
              decoration: BoxDecoration(
                color: open ? RiderDs.fare : RiderDs.accent.withValues(alpha: 0.5),
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
                  AppDs.space3.h,
                  AppDs.space3.v,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.isEmpty
                                ? '#${job.orderId ?? job.id}'
                                : shop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(theme).copyWith(
                              color: AppDs.textOnDarkPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          printSar(job.expectedEarning),
                          style: AppTypography.body(theme).copyWith(
                            color: RiderDs.fare,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.v),
                    Text(
                      [
                        'lbl_print_status_${job.status}'.tr,
                        if (area.isNotEmpty) area,
                        '${job.distanceKm.toStringAsFixed(1)} km',
                      ].join('  ·  '),
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                      ),
                    ),
                    if (address.isNotEmpty) ...[
                      SizedBox(height: AppDs.space2.v),
                      Text(
                        address,
                        maxLines: expanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.secondary(theme).copyWith(
                          color: AppDs.textOnDarkPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (expanded && !open) ...[
                      SizedBox(height: AppDs.space3.v),
                      RiderRouteRail(status: job.status),
                    ],
                    if (expanded &&
                        action == 'pickup' &&
                        pickupController != null) ...[
                      SizedBox(height: AppDs.space3.v),
                      TextField(
                        controller: pickupController,
                        style: const TextStyle(color: AppDs.textOnDarkPrimary),
                        decoration:
                            printTicketField('lbl_print_pickup_code'.tr),
                      ),
                    ],
                    if (action != null) ...[
                      SizedBox(height: AppDs.space3.v),
                      _RiderActionButton(
                        label: 'lbl_print_rider_action_$action'.tr,
                        loading: busy,
                        emphasize: open || expanded,
                        onPressed: onAction,
                      ),
                    ],
                    if (expanded && (onChat != null || onReview != null)) ...[
                      SizedBox(height: AppDs.space2.v),
                      PrintTextActionRow(
                        actions: [
                          if (onChat != null)
                            ('lbl_print_rider_chat'.tr, onChat),
                          if (onReview != null)
                            ('lbl_print_review_customer'.tr, onReview),
                        ],
                      ),
                    ],
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

class _RiderActionButton extends StatelessWidget {
  const _RiderActionButton({
    required this.label,
    required this.loading,
    required this.emphasize,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final bool emphasize;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Same gold CTA as shop / print flows.
    return PrintGoldButton(
      label: label,
      loading: loading,
      onPressed: onPressed,
    );
  }
}

/// Empty queue with a clear next action.
class RiderEmptyLane extends StatelessWidget {
  const RiderEmptyLane({
    super.key,
    required this.online,
    this.onGoOnline,
  });

  final bool online;
  final VoidCallback? onGoOnline;

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
        color: RiderDs.panel,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierHairline(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            online ? Icons.radar_outlined : Icons.power_settings_new_rounded,
            color: online ? RiderDs.accent : AppDs.textOnDarkSecondary,
            size: 36.adaptSize,
          ),
          SizedBox(height: AppDs.space3.v),
          Text(
            online
                ? 'msg_print_rider_jobs_empty'.tr
                : 'msg_print_rider_go_online_hint'.tr,
            textAlign: TextAlign.center,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (!online && onGoOnline != null) ...[
            SizedBox(height: AppDs.space4.v),
            _RiderActionButton(
              label: 'lbl_print_rider_go_online'.tr,
              loading: false,
              emphasize: true,
              onPressed: onGoOnline,
            ),
          ],
        ],
      ),
    );
  }
}

class RiderSectionLabel extends StatelessWidget {
  const RiderSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: AppTypography.caption(theme).copyWith(
        color: AppDs.textOnDarkSecondary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    );
  }
}
