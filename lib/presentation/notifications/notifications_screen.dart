import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../../presentation/contest/contest_navigation.dart';
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
    if (!item.isRead) {
      await _repo.markRead(item.id);
    }
    if (!mounted) return;
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

  String get _title {
    final data = item.data;
    return data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString()
        : (item.type ?? 'lbl_notifications'.tr);
  }

  String get _body {
    final data = item.data;
    return data['message']?.toString().trim().isNotEmpty == true
        ? data['message'].toString()
        : (data['body']?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
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
              Text(_title, style: AppTypography.title(theme)),
              if (_body.isNotEmpty) ...[
                SizedBox(height: AppDs.space1.v),
                Text(_body, style: AppTypography.secondary(theme), maxLines: 3),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
