import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import 'bloc/screen_2_new_design_bloc.dart';
import 'models/screen_2_new_design_model.dart';
import '../select_size_screen/data/size_presets.dart';
import '../select_size_screen/widgets/custom_size_selector.dart';
import '../select_size_screen/widgets/size_preset_card.dart';

class Screen2NewDesignScreen extends StatelessWidget {
  const Screen2NewDesignScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen2NewDesignBloc>(
      create: (context) => Screen2NewDesignBloc(
        Screen2NewDesignState(
          screen2NewDesignModelObj: const Screen2NewDesignModel(),
        ),
      )..add(Screen2NewDesignInitialEvent()),
      child: const Screen2NewDesignScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        backgroundColor: AppDs.surfaceBase,
        body: const _SelectSizeBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(
        imagePath: ImageConstant.imgArrowLeftPrimary,
        onTap: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: AppbarTitle(text: 'lbl_new_design'.tr),
    );
  }
}

class _SelectSizeBody extends StatefulWidget {
  const _SelectSizeBody();

  @override
  State<_SelectSizeBody> createState() => _SelectSizeBodyState();
}

class _SelectSizeBodyState extends State<_SelectSizeBody> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openEditor({
    required double width,
    required double height,
    required String unit,
    required String presetName,
  }) {
    NavigatorService.pushNamed(
      AppRoutes.screen3AddNewScreen,
      arguments: {
        'width': width,
        'height': height,
        'unit': unit,
        'presetName': presetName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final presets = query.isEmpty
        ? kDesignSizePresets
        : kDesignSizePresets
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query) ||
                    p.category.toLowerCase().contains(query) ||
                    p.ratio.toLowerCase().contains(query),
              )
              .toList(growable: false);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppDs.space4.h,
            AppDs.space3.v,
            AppDs.space4.h,
            AppDs.space3.v,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppPageHeader(
                title: 'lbl_select_size'.tr,
                subtitle: 'msg_select_size_subtitle'.tr,
              ),
              SizedBox(height: AppDs.space4.v),
              CustomSizeSelector(
                initialWidth: 1080,
                initialHeight: 1080,
                initiallyExpanded: false,
                onCreate: ({required width, required height, required unit}) =>
                    _openEditor(
                      width: width,
                      height: height,
                      unit: unit,
                      presetName: 'lbl_custom_size'.tr,
                    ),
              ),
              SizedBox(height: AppDs.space5.v),
              AppSearchField(
                controller: _searchCtrl,
                hintText: 'lbl_search_presets'.tr,
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: AppDs.space4.v),
              AppSectionHeader(
                title: 'lbl_popular_sizes'.tr,
                subtitle: query.isEmpty
                    ? null
                    : '${presets.length} ${'lbl_results'.tr}',
              ),
            ]),
          ),
        ),
        if (presets.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              title: 'msg_no_size_presets'.tr,
              icon: Icons.search_off_rounded,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              0,
              AppDs.space4.h,
              AppDs.space8.v,
            ),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppDs.space3.h,
              crossAxisSpacing: AppDs.space3.h,
              childCount: presets.length,
              itemBuilder: (context, i) {
                final p = presets[i];
                return AppFadeIn(
                  delay: Duration(milliseconds: 24 * (i % 8)),
                  child: SizePresetCard(
                    preset: p,
                    denseOnDark: true,
                    onTap: () => _openEditor(
                      width: p.width,
                      height: p.height,
                      unit: 'px',
                      presetName: p.name,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
