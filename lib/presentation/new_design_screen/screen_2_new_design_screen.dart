import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
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
        backgroundColor: appTheme.blueGray90004,
        body: const _SelectSizeBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(imagePath: ImageConstant.imgArrowLeftPrimary),
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
    final theme = Theme.of(context);
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

    final gap = 12.h;

    // Use a single scrollable (slivers) to avoid nested scroll layout issues.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.h, 10.v, 16.h, 18.v),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 6.v),
              Text(
                'lbl_select_size'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.surface,
                ),
              ),
              SizedBox(height: 12.v),
              CustomSizeSelector(
                initialWidth: 500,
                initialHeight: 500,
                onCreate: ({required width, required height, required unit}) =>
                    _openEditor(
                      width: width,
                      height: height,
                      unit: unit,
                      presetName: 'lbl_custom_size'.tr,
                    ),
              ),
              SizedBox(height: 18.v),
              Divider(color: Colors.white.withValues(alpha: 0.15)),
              SizedBox(height: 12.v),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'lbl_search_presets'.tr,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow.withValues(
                    alpha: 0.4,
                  ),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.surface,
                  ),
                  prefixIconColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.7,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.adaptSize),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              SizedBox(height: 12.v),
              Text(
                'msg_choose_from_below'.tr,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.surface,
                ),
              ),
              SizedBox(height: 12.v),
            ]),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childCount: presets.length,
            itemBuilder: (context, i) {
              final p = presets[i];
              return SizePresetCard(
                preset: p,
                denseOnDark: true,
                onTap: () => _openEditor(
                  width: p.width,
                  height: p.height,
                  unit: 'px',
                  presetName: p.name,
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 18.v)),
      ],
    );
  }
}
