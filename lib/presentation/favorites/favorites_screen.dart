import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/media_item.dart';
import '../../data/repositories/design_interaction_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/design_preview_sheet.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  static Widget builder(BuildContext context) {
    return const FavoritesScreen();
  }

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final DesignInteractionRepository _repo = DesignInteractionRepository();
  List<MediaItem> _items = const [];
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
        _error = 'Please sign in to view favorites.';
      });
      return;
    }
    final result = await _repo.favorites();
    if (!mounted) return;
    if (result is FavoriteDesignsFailure) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    setState(() {
      _items = (result as FavoriteDesignsSuccess).items;
      _loading = false;
    });
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
          title: AppbarTitle(text: 'lbl_favorites'.tr),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: AppImageGridSkeleton());
    if (_error != null) {
      return Center(
        child: AppErrorState(message: _error!, onRetry: _load),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: AppEmptyState(
          title: 'lbl_favorites'.tr,
          message: 'msg_no_favorites'.tr,
          icon: Icons.favorite_border,
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: EdgeInsets.all(AppDs.space4.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppDs.space2.h,
          mainAxisSpacing: AppDs.space2.v,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return InkWell(
            onTap: () => showDesignPreviewSheet(
              context,
              imageRef: item.fileUrl,
              designId: item.id,
              title: item.name,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
              child: CustomImageView(
                imagePath: item.fileUrl,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
