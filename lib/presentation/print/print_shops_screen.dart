import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/network/api_utils.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

class PrintShopsScreen extends StatefulWidget {
  const PrintShopsScreen({super.key, this.orderId = 0, this.request});

  final int orderId;
  final Map<String, dynamic>? request;

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
  static const _jeddahLat = 21.54;
  static const _jeddahLng = 39.17;

  final _repo = PrintRepository();
  final _search = TextEditingController();
  List<PrintShopSummary> _shops = const [];
  bool _loading = true;
  bool _mapView = false;
  bool _openNow = false;
  bool _minRating4 = false;
  String _sort = 'trusted';
  int? _minLevel;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.searchShops(
      lat: _jeddahLat,
      lng: _jeddahLng,
      openNow: _openNow,
      rating: _minRating4 ? 4 : null,
      q: _search.text,
      sort: _sort,
      level: _minLevel,
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
      title: 'lbl_print_shops'.tr,
      actions: [
        IconButton(
          onPressed: () => setState(() => _mapView = !_mapView),
          icon: Icon(
            _mapView ? Icons.list : Icons.map_outlined,
            color: AppDs.printGold,
          ),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 0),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'lbl_print_search_shops'.tr,
                hintStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
                filled: true,
                fillColor: AppDs.surfaceRaised,
                prefixIcon: const Icon(Icons.search, color: AppDs.printGold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          SwitchListTile(
            title: Text(
              'lbl_print_open_now'.tr,
              style: const TextStyle(color: Colors.white),
            ),
            value: _openNow,
            onChanged: (v) {
              setState(() => _openNow = v);
              _load();
            },
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12.h),
            child: Row(
              children: [
                for (final sort in [
                  'trusted',
                  'fastest',
                  'price',
                  'distance',
                  'level',
                ])
                  Padding(
                    padding: EdgeInsets.only(right: 8.h),
                    child: ChoiceChip(
                      label: Text('lbl_print_sort_$sort'.tr),
                      selected: _sort == sort,
                      selectedColor: AppDs.printGold,
                      labelStyle: TextStyle(
                        color: _sort == sort ? Colors.black : Colors.white,
                      ),
                      onSelected: (_) {
                        setState(() => _sort = sort);
                        _load();
                      },
                    ),
                  ),
                for (final level in [2, 3, 4, 5])
                  Padding(
                    padding: EdgeInsets.only(right: 8.h),
                    child: FilterChip(
                      label: Text('lbl_print_level_$level'.tr),
                      selected: _minLevel == level,
                      selectedColor: AppDs.printGold,
                      labelStyle: TextStyle(
                        color: _minLevel == level ? Colors.black : Colors.white,
                      ),
                      onSelected: (selected) {
                        setState(() => _minLevel = selected ? level : null);
                        _load();
                      },
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(right: 8.h),
                  child: FilterChip(
                    label: Text('lbl_print_filter_rating'.tr),
                    selected: _minRating4,
                    selectedColor: AppDs.printGold,
                    labelStyle: TextStyle(
                      color: _minRating4 ? Colors.black : Colors.white,
                    ),
                    onSelected: (selected) {
                      setState(() => _minRating4 = selected);
                      _load();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white70)),
      );
    }
    if (_shops.isEmpty) {
      return Center(
        child: Text(
          'msg_print_no_shops'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    if (_mapView) {
      return _MapCanvas(shops: _shops, onTap: _openShop);
    }
    return ListView.separated(
      padding: EdgeInsets.all(16.h),
      itemCount: _shops.length,
      separatorBuilder: (_, __) => SizedBox(height: 10.v),
      itemBuilder: (context, index) {
        final shop = _shops[index];
        return ListTile(
          onTap: () => _openShop(shop),
          tileColor: AppDs.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            shop.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            [
              if (shop.verified) 'lbl_print_verified'.tr,
              printLocalizedLabel(shop.levelLabel, shop.levelLabelAr),
              shop.district ?? '',
              if (shop.distanceKm != null)
                '${shop.distanceKm!.toStringAsFixed(1)} km',
              printSar(shop.startingPrice),
            ].where((e) => e.isNotEmpty).join(' · '),
            style: const TextStyle(color: AppDs.textOnDarkSecondary),
          ),
          trailing: shop.verified
              ? const Icon(Icons.verified, color: AppDs.printGold)
              : null,
        );
      },
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({required this.shops, required this.onTap});

  final List<PrintShopSummary> shops;
  final ValueChanged<PrintShopSummary> onTap;

  @override
  Widget build(BuildContext context) {
    const minLat = 21.46;
    const maxLat = 21.58;
    const minLng = 39.14;
    const maxLng = 39.21;
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A2F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'Jeddah',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
                      fontSize: 42.fSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...shops.where((s) => s.lat != null && s.lng != null).map((shop) {
                  final x =
                      ((shop.lng! - minLng) / (maxLng - minLng)).clamp(0.08, 0.92) *
                      constraints.maxWidth;
                  final y =
                      (1 - ((shop.lat! - minLat) / (maxLat - minLat)).clamp(0.08, 0.92)) *
                      constraints.maxHeight;
                  return Positioned(
                    left: x - 18,
                    top: y - 18,
                    child: GestureDetector(
                      onTap: () => onTap(shop),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: shop.verified ? AppDs.printGold : Colors.white,
                            size: 32,
                          ),
                          Text(
                            shop.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
