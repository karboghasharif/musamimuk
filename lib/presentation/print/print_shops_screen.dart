import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../core/network/authenticated_image.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_location_picker.dart';
import 'print_ui.dart';

/// Designer nearest-shops browser (25 km). Opened from home center FAB.
class PrintShopsScreen extends StatefulWidget {
  const PrintShopsScreen({super.key, this.orderId = 0, this.request});

  final int orderId;
  final Map<String, dynamic>? request;

  static const nearestRadiusKm = 25.0;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args.cast<String, dynamic>() : <String, dynamic>{};
    final request = map['designId'] != null ? map : null;
    return PrintShopsScreen(
      orderId: apiParseInt(map['orderId']),
      request: request,
    );
  }

  @override
  State<PrintShopsScreen> createState() => _PrintShopsScreenState();
}

class _PrintShopsScreenState extends State<PrintShopsScreen> {
  final _repo = PrintRepository();
  final _search = TextEditingController();
  List<PrintShopSummary> _shops = const [];
  bool _loading = true;
  bool _locating = true;
  bool _openNow = true;
  String _sort = 'trusted';
  String? _error;
  double _lat = kPrintMapFallback.latitude;
  double _lng = kPrintMapFallback.longitude;

  static const _sortOptions = <(String, IconData)>[
    ('trusted', Icons.verified_user_rounded),
    ('fastest', Icons.timer_outlined),
    ('price', Icons.payments_outlined),
    ('distance', Icons.place_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _locating = true;
      _loading = true;
      _error = null;
    });
    final gps = await printAcquireGps();
    if (!mounted) return;
    if (gps != null) {
      _lat = gps.lat;
      _lng = gps.lng;
    }
    setState(() => _locating = false);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.searchShops(
      lat: _lat,
      lng: _lng,
      distance: PrintShopsScreen.nearestRadiusKm,
      openNow: _openNow,
      q: _search.text,
      sort: _sort,
    );
    if (!mounted) return;
    if (result is PrintFailure<List<PrintShopSummary>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _shops = (result as PrintSuccess<List<PrintShopSummary>>).data;
      _loading = false;
    });
  }

  void _openShop(PrintShopSummary shop) {
    NavigatorService.pushNamed(
      AppRoutes.printShopProfileScreen,
      arguments: {
        'shopId': shop.id,
        'orderId': widget.orderId,
        if (widget.request != null) 'request': widget.request,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_print_nearest_shops'.tr,
      actions: [
        IconButton(
          onPressed: _loading || _locating ? null : _bootstrap,
          tooltip: 'lbl_print_use_current_location'.tr,
          icon: const Icon(Icons.my_location_rounded, color: AppDs.printGold),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'lbl_print_search_shops_hint'.tr,
                      hintStyle: const TextStyle(
                        color: AppDs.textOnDarkSecondary,
                      ),
                      filled: true,
                      fillColor: AppDs.surfaceRaised,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.h,
                        vertical: 12.v,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppDs.printGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppDs.printGold,
                          width: 1.2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                SizedBox(width: 10.h),
                _OpenNowPill(
                  active: _openNow,
                  onTap: () {
                    setState(() => _openNow = !_openNow);
                    _load();
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 12.v),
          SizedBox(
            height: 40.v,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.h),
              itemCount: _sortOptions.length,
              separatorBuilder: (_, _) => SizedBox(width: 8.h),
              itemBuilder: (context, index) {
                final (sort, icon) = _sortOptions[index];
                final selected = _sort == sort;
                return Material(
                  color: selected ? AppDs.printGold : AppDs.surfaceRaised,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      if (_sort == sort) return;
                      setState(() => _sort = sort);
                      _load();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.h,
                        vertical: 8.v,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: selected ? Colors.black : AppDs.printGold,
                          ),
                          SizedBox(width: 6.h),
                          Text(
                            'lbl_print_sort_$sort'.tr,
                            style: TextStyle(
                              color: selected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.fSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.v),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading || _locating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppDs.printGold),
            SizedBox(height: 12.v),
            Text(
              _locating
                  ? 'msg_print_locating'.tr
                  : 'lbl_print_nearest_shops'.tr,
              style: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 12.v),
              TextButton(
                onPressed: _load,
                child: Text('lbl_retry'.tr),
              ),
            ],
          ),
        ),
      );
    }
    if (_shops.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: Text(
            'msg_print_no_shops_nearby'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppDs.printGold,
      onRefresh: _bootstrap,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 24.v),
        itemCount: _shops.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.v),
        itemBuilder: (context, index) {
          return _NearestShopCard(
            shop: _shops[index],
            onTap: () => _openShop(_shops[index]),
          );
        },
      ),
    );
  }
}

class _OpenNowPill extends StatelessWidget {
  const _OpenNowPill({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppDs.printGold : AppDs.surfaceRaised,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12.v),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: active ? Colors.black : const Color(0xFF4CAF50),
              ),
              SizedBox(width: 6.h),
              Text(
                'lbl_print_open_now'.tr,
                style: TextStyle(
                  color: active ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
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

class _NearestShopCard extends StatelessWidget {
  const _NearestShopCard({required this.shop, required this.onTap});

  final PrintShopSummary shop;
  final VoidCallback onTap;

  static final _ordersFmt = NumberFormat.decimalPattern();

  String get _distanceLabel {
    final km = shop.distanceKm;
    if (km == null) return '—';
    return '${km.toStringAsFixed(1)} KM';
  }

  String get _distanceInline {
    final km = shop.distanceKm;
    if (km == null) return '';
    return '${km.toStringAsFixed(1)} km';
  }

  String get _initial {
    final name = shop.name.trim();
    if (name.isEmpty) return 'P';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  IconData _serviceIcon(String service) {
    final s = service.toLowerCase();
    if (s.contains('card') || s.contains('business')) {
      return Icons.badge_outlined;
    }
    if (s.contains('banner') || s.contains('poster')) {
      return Icons.flag_outlined;
    }
    if (s.contains('sticker') || s.contains('label')) {
      return Icons.sticky_note_2_outlined;
    }
    if (s.contains('pack') || s.contains('box')) {
      return Icons.inventory_2_outlined;
    }
    if (s.contains('book') || s.contains('magazine')) {
      return Icons.menu_book_outlined;
    }
    return Icons.print_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final levelText = printLocalizedLabel(shop.levelLabel, shop.levelLabelAr);
    final locationBits = [
      if ((shop.district ?? '').trim().isNotEmpty) shop.district!.trim(),
      if (_distanceInline.isNotEmpty) _distanceInline,
    ].join(' · ');
    final services = shop.services.take(4).toList();
    final portfolio = shop.portfolio.take(4).toList();

    return Material(
      color: AppDs.surfaceRaised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48.adaptSize,
                    height: 48.adaptSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppDs.printGold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppDs.printGold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: AppDs.printGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.fSize,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.fSize,
                                ),
                              ),
                            ),
                            if (shop.verified) ...[
                              SizedBox(width: 4.h),
                              Icon(
                                Icons.verified_rounded,
                                color: AppDs.printGold,
                                size: 16.adaptSize,
                              ),
                            ],
                          ],
                        ),
                        if (locationBits.isNotEmpty) ...[
                          SizedBox(height: 4.v),
                          Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 13.adaptSize,
                                color: AppDs.textOnDarkSecondary,
                              ),
                              SizedBox(width: 3.h),
                              Expanded(
                                child: Text(
                                  locationBits,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppDs.textOnDarkSecondary,
                                    fontSize: 12.fSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Container(
                    constraints: BoxConstraints(minWidth: 56.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.h,
                      vertical: 8.v,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _distanceLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.fSize,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.v),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 15.adaptSize,
                    color: AppDs.printGold,
                  ),
                  SizedBox(width: 5.h),
                  Expanded(
                    child: Text(
                      levelText.isNotEmpty
                          ? 'Level ${shop.level} / $levelText'
                          : 'Level ${shop.level}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.fSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.v),
              Row(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    size: 15.adaptSize,
                    color: AppDs.printGold,
                  ),
                  SizedBox(width: 5.h),
                  Expanded(
                    child: Text(
                      'msg_print_orders_completed'.tr.replaceAll(
                        '{count}',
                        _ordersFmt.format(shop.completedOrders),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.fSize,
                      ),
                    ),
                  ),
                ],
              ),
              if (services.isNotEmpty) ...[
                SizedBox(height: 10.v),
                Wrap(
                  spacing: 6.h,
                  runSpacing: 6.v,
                  children: [
                    for (final service in services)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.h,
                          vertical: 6.v,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppDs.printGold.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _serviceIcon(service),
                              size: 13,
                              color: AppDs.printGold,
                            ),
                            SizedBox(width: 4.h),
                            Text(
                              service,
                              style: TextStyle(
                                color: AppDs.printGold,
                                fontSize: 11.fSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              if (portfolio.isNotEmpty) ...[
                SizedBox(height: 12.v),
                Text(
                  'lbl_print_portfolio'.tr.toUpperCase(),
                  style: TextStyle(
                    color: AppDs.textOnDarkSecondary,
                    fontSize: 10.fSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 8.v),
                SizedBox(
                  height: 64.v,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: portfolio.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8.h),
                    itemBuilder: (context, index) {
                      final item = portfolio[index];
                      final url = item.imageUrl?.trim() ?? '';
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 72.h,
                          height: 64.v,
                          child: url.isEmpty
                              ? Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Colors.white38,
                                  ),
                                )
                              : Image(
                                  image: musamiAuthenticatedNetworkImage(url),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
