import 'package:flutter/material.dart';

import '../utils/size_utils.dart';
import 'app_design_tokens.dart';

/// Pulsing placeholder block for skeleton loading states.
class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = 0.35 + (_pulse.value * 0.2);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: t),
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppDs.radiusMd),
          ),
        );
      },
    );
  }
}

/// Skeleton for a single contest list card.
class AppContestCardSkeleton extends StatelessWidget {
  const AppContestCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDs.cardDecoration(elevated: true),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeletonBox(
            height: 160.v,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: EdgeInsets.all(AppDs.space4.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(height: 18.v, width: double.infinity),
                SizedBox(height: AppDs.space2.v),
                AppSkeletonBox(height: 14.v, width: 140.h),
                SizedBox(height: AppDs.space3.v),
                Row(
                  children: [
                    AppSkeletonBox(height: 14.v, width: 80.h),
                    SizedBox(width: AppDs.space3.h),
                    AppSkeletonBox(height: 14.v, width: 80.h),
                  ],
                ),
                SizedBox(height: AppDs.space4.v),
                AppSkeletonBox(
                  height: AppDs.buttonHeight.v,
                  borderRadius: BorderRadius.circular(AppDs.radiusMd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton list for contest listing screen.
class AppContestListSkeleton extends StatelessWidget {
  const AppContestListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: AppDs.space4.v),
      itemBuilder: (_, _) => const AppContestCardSkeleton(),
    );
  }
}

/// Skeleton for contest detail screen.
class AppContestDetailSkeleton extends StatelessWidget {
  const AppContestDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        AppDs.space3.v,
        AppDs.space4.h,
        AppDs.space6.v,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeletonBox(
            height: 200.v,
            borderRadius: BorderRadius.circular(AppDs.radiusLg),
          ),
          SizedBox(height: AppDs.space6.v),
          AppSkeletonBox(height: 28.v, width: double.infinity),
          SizedBox(height: AppDs.space2.v),
          AppSkeletonBox(height: 16.v, width: 120.h),
          SizedBox(height: AppDs.space6.v),
          AppSkeletonBox(
            height: 88.v,
            borderRadius: BorderRadius.circular(AppDs.radiusLg),
          ),
          SizedBox(height: AppDs.space6.v),
          AppSkeletonBox(
            height: AppDs.buttonHeight.v,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
          ),
          SizedBox(height: AppDs.space4.v),
          Row(
            children: [
              Expanded(
                child: AppSkeletonBox(
                  height: 40.v,
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                ),
              ),
              SizedBox(width: AppDs.space2.h),
              Expanded(
                child: AppSkeletonBox(
                  height: 40.v,
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDs.space8.v),
          AppSkeletonBox(height: 20.v, width: 140.h),
          SizedBox(height: AppDs.space4.v),
          Row(
            children: [
              Expanded(child: AppSkeletonBox(height: 72.v)),
              SizedBox(width: AppDs.space3.h),
              Expanded(child: AppSkeletonBox(height: 72.v)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton list for contest feed (LinkedIn-style post cards).
class AppContestFeedSkeleton extends StatelessWidget {
  const AppContestFeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      itemCount: count,
      separatorBuilder: (_, _) => SizedBox(height: AppDs.space4.v),
      itemBuilder: (_, _) => Container(
        decoration: AppDs.cardDecoration(elevated: true),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(AppDs.space4.h),
              child: Row(
                children: [
                  AppSkeletonBox(
                    width: 48.adaptSize,
                    height: 48.adaptSize,
                    borderRadius:
                        BorderRadius.circular(AppDs.radiusFull.adaptSize),
                  ),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(height: 16.v, width: 140.h),
                        SizedBox(height: AppDs.space2.v),
                        AppSkeletonBox(height: 12.v, width: 80.h),
                        SizedBox(height: AppDs.space2.v),
                        AppSkeletonBox(height: 12.v, width: 180.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppSkeletonBox(
              height: 220.v,
              borderRadius: BorderRadius.zero,
            ),
            Padding(
              padding: EdgeInsets.all(AppDs.space4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(height: 14.v, width: 100.h),
                  SizedBox(height: AppDs.space3.v),
                  AppSkeletonBox(height: 14.v, width: double.infinity),
                  SizedBox(height: AppDs.space2.v),
                  AppSkeletonBox(height: 14.v, width: 220.h),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                0,
                AppDs.space4.h,
                AppDs.space3.v,
              ),
              child: Row(
                children: [
                  Expanded(child: AppSkeletonBox(height: 40.v)),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(child: AppSkeletonBox(height: 40.v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton grid for gallery / submissions.
class AppImageGridSkeleton extends StatelessWidget {
  const AppImageGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.all(AppDs.space4.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppDs.space3.h,
        mainAxisSpacing: AppDs.space3.v,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (_, _) => AppSkeletonBox(
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
      ),
    );
  }
}

/// 3-column grid skeleton (search results).
class AppSearchGridSkeleton extends StatelessWidget {
  const AppSearchGridSkeleton({super.key, this.count = 9});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDs.space2.h,
        mainAxisSpacing: AppDs.space2.v,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (_, _) => AppSkeletonBox(
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
      ),
    );
  }
}

/// Horizontal card strip skeleton.
class AppHorizontalListSkeleton extends StatelessWidget {
  const AppHorizontalListSkeleton({
    super.key,
    this.itemWidth = 120,
    this.itemHeight = 140,
    this.count = 4,
  });

  final double itemWidth;
  final double itemHeight;
  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight.v,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
        itemCount: count,
        separatorBuilder: (_, _) => SizedBox(width: AppDs.space3.h),
        itemBuilder: (_, _) => AppSkeletonBox(
          width: itemWidth.h,
          height: itemHeight.v,
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
        ),
      ),
    );
  }
}

/// Featured row (3 tiles) skeleton for online designs.
class AppFeaturedRowSkeleton extends StatelessWidget {
  const AppFeaturedRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppDs.space4.h),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: i < 2 ? AppDs.space2.h : 0,
              ),
              child: AppSkeletonBox(
                height: 157.v,
                borderRadius: BorderRadius.circular(AppDs.radiusSm),
              ),
            ),
          );
        }),
      ),
    );
  }
}
