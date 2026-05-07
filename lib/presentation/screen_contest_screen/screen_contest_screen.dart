import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../data/models/contest_item.dart';
import '../../data/repositories/contest_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_contest_bloc.dart';
import 'models/certificatedesign_item_model.dart';
import 'models/screen_contest_model.dart';
import 'widgets/certificatedesign_item_widget.dart';
import '../screen_contesttwo_screen/models/contest_detail_args.dart';

class ScreenContestScreen extends StatelessWidget {
  const ScreenContestScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<ScreenContestBloc>(
      create: (context) => ScreenContestBloc(
        ScreenContestState(
          screenContestModelObj: ScreenContestModel(),
        ),
        repository: ContestRepository.instance,
      )..add(ScreenContestInitialEvent()),
      child: const ScreenContestScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(
            horizontal: 25.h,
            vertical: 29.v,
          ),
          child: Column(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgCupStarSvgrepoComBlueGray70002,
                height: 69.adaptSize,
                width: 69.adaptSize,
              ),
              SizedBox(height: 32.v),
              Text(
                "lbl_contest".tr,
                style: theme.textTheme.headlineMedium,
              ),
              SizedBox(height: 1.v),
              SizedBox(
                width: 243.h,
                child: Text(
                  "msg_take_part_in_the".tr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.bodyMedium15.copyWith(
                    height: 1.29,
                  ),
                ),
              ),
              SizedBox(height: 49.v),
              _buildCertificateDesign(context)
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contestSlivers(
    BuildContext context,
    List<CertificatedesignItemModel> items,
    String sectionTitle,
  ) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(bottom: 16.v, top: 8.v),
          child: Text(
            sectionTitle,
            style: theme.textTheme.titleMedium,
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final model = items[index];
            final contestId = int.tryParse(model.id ?? '');
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 23.v : 0,
              ),
              child: CertificatedesignItemWidget(
                model,
                onTap: contestId == null
                    ? null
                    : () {
                        ContestItem? contest;
                        if (model.contestJson != null) {
                          try {
                            contest =
                                ContestItem.fromJson(model.contestJson!);
                          } catch (_) {
                            contest = null;
                          }
                        }
                        NavigatorService.pushNamed(
                          AppRoutes.screenContesttwoScreen,
                          arguments: ContestDetailArgs(
                            contestId: contestId,
                            contest: contest,
                          ),
                        );
                      },
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    ];
  }

  /// Section Widget
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        margin: EdgeInsets.fromLTRB(30.h, 20.v, 377.h, 19.v),
      ),
    );
  }

  /// Section Widget
  Widget _buildCertificateDesign(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 1.h),
        child: BlocBuilder<ScreenContestBloc, ScreenContestState>(
          builder: (context, state) {
            Future<void> onRefresh() async {
              final bloc = context.read<ScreenContestBloc>();
              bloc.add(ScreenContestLoadEvent(forceRefresh: true));
              await bloc.stream.firstWhere((s) => !s.isLoading);
            }

            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 200.v,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.h),
                          child: Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final modelObj = state.screenContestModelObj;
            final open = modelObj?.openContestItemList ?? const [];
            final closed = modelObj?.closedContestItemList ?? const [];
            if (open.isEmpty && closed.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 200.v,
                      child: Center(
                        child: Text(
                          'msg_no_contests'.tr,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  if (open.isNotEmpty)
                    ..._contestSlivers(context, open, 'lbl_open_contests'.tr),
                  if (closed.isNotEmpty)
                    ..._contestSlivers(
                      context,
                      closed,
                      'lbl_closed_contests'.tr,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
