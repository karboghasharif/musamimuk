import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

class PrintNoticesScreen extends StatefulWidget {
  const PrintNoticesScreen({super.key});

  static Widget builder(BuildContext context) => const PrintNoticesScreen();

  @override
  State<PrintNoticesScreen> createState() => _PrintNoticesScreenState();
}

class _PrintNoticesScreenState extends State<PrintNoticesScreen> {
  final _repo = PrintRepository();
  List<PrintNotice> _notices = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.notices();
    if (!mounted) return;
    if (result is PrintFailure<List<PrintNotice>>) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _notices = (result as PrintSuccess<List<PrintNotice>>).data;
      _loading = false;
    });
  }

  void _openHref(PrintNotice notice) {
    final href = notice.href ?? '';
    final orderMatch = RegExp(r'/print/orders/(\d+)').firstMatch(href);
    if (orderMatch != null) {
      NavigatorService.pushNamed(
        AppRoutes.printTrackingScreen,
        arguments: {'orderId': int.tryParse(orderMatch.group(1)!) ?? 0},
      );
      return;
    }
    if (href.contains('/print/rider')) {
      NavigatorService.pushNamed(AppRoutes.printRiderHomeScreen);
      return;
    }
    if (href.contains('/print/shop') || href.contains('/print/deliveries')) {
      NavigatorService.pushNamed(AppRoutes.printShopHomeScreen);
      return;
    }
    NavigatorService.pushNamed(AppRoutes.printOrdersScreen);
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_print_notices'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _error != null
                  ? ListView(
                      children: [
                        SizedBox(height: 80.v),
                        Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    )
                  : _notices.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 80.v),
                            Center(
                              child: Text(
                                'msg_print_notices_empty'.tr,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: EdgeInsets.all(16.h),
                          itemCount: _notices.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.v),
                          itemBuilder: (context, index) {
                            final notice = _notices[index];
                            return Material(
                              color: AppDs.surfaceRaised,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openHref(notice),
                                child: Padding(
                                  padding: EdgeInsets.all(14.h),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notice.title,
                                              style: TextStyle(
                                                color: notice.read
                                                    ? Colors.white70
                                                    : AppDs.printGold,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (!notice.read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppDs.printGold,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 6.v),
                                      Text(
                                        notice.body,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
