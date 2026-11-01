import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../../presentation/contest/contest_navigation.dart';
import '../../presentation/print/print_live.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const NotificationsScreen();
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationItem> _items = const [];
  bool _loading = true;
  String? _error;
  VoidCallback? _stopLive;

  @override
  void initState() {
    super.initState();
    _stopLive = PrintLive.instance.listenNotifications(_loadQuiet);
    _load();
  }

  @override
  void dispose() {
    _stopLive?.call();
    super.dispose();
  }

  Future<void> _loadQuiet() async {
    if (!mounted || _loading) return;
    final result = await _repo.list(perPage: 30);
    if (!mounted || result is! NotificationsSuccess) return;
    setState(() => _items = result.items);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    if (!PrefUtils().isLoggedIn()) {
      setState(() {
        _loading = false;
        _error = 'Please sign in to view notifications.';
      });
      return;
    }
    final result = await _repo.list(perPage: 30);
    if (!mounted) return;
    if (result is NotificationsFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _items = (result as NotificationsSuccess).items;
      _loading = false;
    });
  }

  Future<void> _onTap(NotificationItem item) async {
    if (!item.isRead && item.id.isNotEmpty) {
      await _repo.markRead(item.id);
    }
    if (!mounted) return;
    final href = item.href ?? '';
    final orderMatch = RegExp(r'/print/orders/(\d+)').firstMatch(href);
    final orderId = int.tryParse(orderMatch?.group(1) ?? '') ??
        int.tryParse(item.data['order_id']?.toString() ?? '');
    if (orderId != null && orderId > 0) {
      NavigatorService.pushNamed(
        AppRoutes.printTrackingScreen,
        arguments: {'orderId': orderId},
      );
      _load();
      return;
    }
    if (href.contains('/print/rider')) {
      NavigatorService.pushNamed(AppRoutes.printRiderHomeScreen);
      _load();
      return;
    }
    if (href.contains('/print') || item.data['type']?.toString() == 'print') {
      NavigatorService.pushNamed(AppRoutes.printNoticesScreen);
      _load();
      return;
    }
    ContestNavigation.openFromNotificationData(item.data);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
            onTap: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: AppbarTitle(text: 'lbl_notifications'.tr),
          actions: [
            if (_items.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _repo.markAllRead();
                  if (mounted) _load();
                },
                child: Text('lbl_mark_all_read'.tr),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView.separated(
        padding: EdgeInsets.all(AppDs.space4.h),
        itemCount: 5,
        separatorBuilder: (_, _) => SizedBox(height: AppDs.space3.v),
        itemBuilder: (_, _) => AppSkeletonBox(
          height: 72.v,
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'lbl_notifications'.tr,
          message: 'msg_no_notifications'.tr,
          icon: Icons.notifications_none_outlined,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.all(AppDs.space4.h),
        itemCount: _items.length,
        separatorBuilder: (_, _) => SizedBox(height: AppDs.space3.v),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _NotificationTile(
            item: item,
            onTap: () => _onTap(item),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isNotEmpty
        ? item.title
        : 'lbl_notifications'.tr;
    final body = item.body;
    return Material(
      color: item.isRead
          ? appTheme.blueGray90001
          : theme.colorScheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
        child: Padding(
          padding: EdgeInsets.all(AppDs.space4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.title(theme)),
              if (body.isNotEmpty) ...[
                SizedBox(height: AppDs.space1.v),
                Text(body, style: AppTypography.secondary(theme), maxLines: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
