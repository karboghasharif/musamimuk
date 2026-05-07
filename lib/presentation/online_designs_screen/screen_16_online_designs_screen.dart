import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../data/models/media_item.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/design_preview_sheet.dart';
import 'bloc/screen_16_online_designs_bloc.dart';
import 'models/listsection_item_model.dart';
import 'models/rectanglelistsection_item_model.dart';
import 'models/screen_16_online_designs_model.dart';
import 'widgets/listsection_item_widget.dart';
import 'widgets/rectanglelistsection_item_widget.dart';

class Screen16OnlineDesignsScreen extends StatelessWidget {
  const Screen16OnlineDesignsScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<Screen16OnlineDesignsBloc>(
      create: (context) => Screen16OnlineDesignsBloc(
        Screen16OnlineDesignsState(
          screen16OnlineDesignsModelObj: Screen16OnlineDesignsModel(),
        ),
      )..add(Screen16OnlineDesignsInitialEvent()),
      child: const Screen16OnlineDesignsScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: _buildAppBar(context),
        body: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 22.h, right: 23.h),
                        child:
                            BlocSelector<
                              Screen16OnlineDesignsBloc,
                              Screen16OnlineDesignsState,
                              TextEditingController?
                            >(
                              selector: (state) => state.searchController,
                              builder: (context, searchController) {
                                return CustomSearchView(
                                  controller: searchController,
                                  hintText: "msg_search_online_t".tr,
                                  onChanged: (value) {
                                    context.read<Screen16OnlineDesignsBloc>().add(
                                      Screen16OnlineDesignsSearchChangedEvent(
                                        value,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                      ),
                      SizedBox(height: 16.v),
                      _buildSocialMediaSection(context),
                      SizedBox(height: 30.v),
                      Container(
                        margin: EdgeInsets.only(right: 2.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.h,
                          vertical: 29.v,
                        ),
                        decoration: AppDecoration.fillBluegray90005.copyWith(
                          borderRadius: BorderRadiusStyle.circleBorder44,
                        ),
                        child:
                            BlocBuilder<
                              Screen16OnlineDesignsBloc,
                              Screen16OnlineDesignsState
                            >(
                              builder: (context, state) {
                                if (state.isLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (state.errorMessage != null) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.h,
                                      vertical: 40.v,
                                    ),
                                    child: Center(
                                      child: Text(
                                        state.errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  );
                                }
                                final model =
                                    state.screen16OnlineDesignsModelObj;
                                final forYou = state.selectedCategoryId == null;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: 9.v),
                                    _buildImageSection(context),
                                    SizedBox(height: 17.v),
                                    if (forYou)
                                      ..._buildForYouGroupedSections(
                                        context,
                                        model,
                                      )
                                    else ...[
                                      ..._buildCategoryFilterHeading(
                                        state.categoryOptions,
                                        state.selectedCategoryId,
                                      ),
                                      _buildRectangleListSection(context),
                                      SizedBox(height: 17.v),
                                      _buildListSection(context),
                                    ],
                                    SizedBox(height: 32.v),
                                  ],
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: AppbarLeadingImage(imagePath: ImageConstant.imgArrowLeftPrimary),
    );
  }

  /// Icons for category slots (Business → bag, Premium → bookmark, Islamic → mosque, Social → info).
  static final List<String> _categoryFilterSlotIcons = [
    ImageConstant.imgBagSvgrepoCom,
    ImageConstant.imgBookmarkSquare,
    ImageConstant.imgMosqueSvgrepoCom,
    ImageConstant.imgInfo,
  ];

  Widget _buildSocialMediaSection(BuildContext context) {
    return BlocBuilder<Screen16OnlineDesignsBloc, Screen16OnlineDesignsState>(
      buildWhen: (prev, curr) =>
          prev.categoryOptions != curr.categoryOptions ||
          prev.selectedCategoryId != curr.selectedCategoryId ||
          prev.isLoading != curr.isLoading,
      builder: (context, state) {
        final cats = state.categoryOptions;
        final primary = theme.colorScheme.primary;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryQuickTile(
                context,
                bagImage: ImageConstant.imgHome,
                label: "lbl_for_you".tr,
                isSelected: state.selectedCategoryId == null,
                enabled: !state.isLoading,
                iconColor: primary,
                onTap: () {
                  context.read<Screen16OnlineDesignsBloc>().add(
                    Screen16OnlineDesignsCategoryChangedEvent(null),
                  );
                },
              ),
              for (var i = 0; i < cats.length; i++) ...[
                SizedBox(width: i == 0 ? 19.h : 14.h),
                _buildCategoryQuickTile(
                  context,
                  bagImage:
                      _categoryFilterSlotIcons[i %
                          _categoryFilterSlotIcons.length],
                  label: cats[i].name,
                  isSelected: false,
                  category: cats[i],
                  selectedId: state.selectedCategoryId,
                  enabled: !state.isLoading,
                  iconColor: primary,
                  onTap: state.isLoading
                      ? null
                      : () {
                          context.read<Screen16OnlineDesignsBloc>().add(
                            Screen16OnlineDesignsCategoryChangedEvent(
                              cats[i].id,
                            ),
                          );
                        },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Rounded dark tile + primary-tinted icon + label (matches reference filter row).
  Widget _buildCategoryQuickTile(
    BuildContext context, {
    required String bagImage,
    required String label,
    required bool isSelected,
    required bool enabled,
    VoidCallback? onTap,
    MediaCategoryRef? category,
    int? selectedId,
    Color? iconColor,
  }) {
    final selected = category != null ? selectedId == category.id : isSelected;
    final canTap = enabled && onTap != null;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(15.h),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 51.v,
                width: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 13.h, vertical: 10.v),
                decoration: AppDecoration.fillGray800.copyWith(
                  borderRadius: BorderRadiusStyle.roundedBorder15,
                  border: selected
                      ? Border.all(color: primary, width: 2)
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: CustomImageView(
                  imagePath: bagImage,
                  height: 29.adaptSize,
                  width: 29.adaptSize,
                  alignment: Alignment.center,
                  color: iconColor,
                ),
              ),
              SizedBox(height: 9.v),
              SizedBox(
                width: 72.h,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 1.0,
                    ),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _fallbackFeatured = [
    ImageConstant.imgRectangle5579,
    ImageConstant.imgRectangle5577,
    ImageConstant.imgRectangle5578,
  ];

  /// Title above the strips when a single category filter is selected (not "For you").
  List<Widget> _buildCategoryFilterHeading(
    List<MediaCategoryRef> options,
    int? selectedId,
  ) {
    if (selectedId == null) return const [];
    String title = '';
    for (final c in options) {
      if (c.id == selectedId) {
        title = c.name;
        break;
      }
    }
    if (title.isEmpty) return const [];
    return [
      Padding(
        padding: EdgeInsets.only(left: 9.h, right: 9.h),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style:
                theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ) ??
                theme.textTheme.bodyLarge,
          ),
        ),
      ),
      SizedBox(height: 10.v),
    ];
  }

  /// When "For you" is selected: category heading + horizontal row per category.
  List<Widget> _buildForYouGroupedSections(
    BuildContext context,
    Screen16OnlineDesignsModel? model,
  ) {
    final groups = model?.forYouGroupedSections ?? const [];
    if (groups.isEmpty) {
      return const [];
    }
    final out = <Widget>[];
    for (final g in groups) {
      out.add(
        Padding(
          padding: EdgeInsets.only(left: 9.h, right: 9.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              g.categoryHeading,
              style:
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ) ??
                  theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
      out.add(SizedBox(height: 10.v));
      out.add(
        SizedBox(
          height: 110.v,
          child: ListView.separated(
            padding: EdgeInsets.only(left: 9.h),
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => SizedBox(width: 18.h),
            itemCount: g.items.length,
            itemBuilder: (context, index) {
              return RectanglelistsectionItemWidget(g.items[index]);
            },
          ),
        ),
      );
      out.add(SizedBox(height: 17.v));
    }
    return out;
  }

  Widget _buildImageSection(BuildContext context) {
    return BlocSelector<
      Screen16OnlineDesignsBloc,
      Screen16OnlineDesignsState,
      Screen16OnlineDesignsModel?
    >(
      selector: (state) => state.screen16OnlineDesignsModelObj,
      builder: (context, model) {
        final urls = model?.featuredImageUrls ?? const <String>[];
        final tiles = model?.featuredTiles ?? const [];
        final w = <double>[114.h, 113.h, 114.h];
        return Padding(
          padding: EdgeInsets.only(left: 9.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final url = i < urls.length ? urls[i] : null;
              final tile = i < tiles.length ? tiles[i] : null;
              final fallback = _fallbackFeatured[i];
              final path =
                  url != null && url.isNotEmpty ? url : fallback;
              final canPreviewNetwork =
                  url != null && url.trim().isNotEmpty;
              if (tile != null &&
                  (tile.rectangle ?? '').trim().isNotEmpty &&
                  canPreviewNetwork) {
                return RectanglelistsectionItemWidget(
                  tile,
                  cellWidth: w[i],
                  imageHeight: 157.v,
                );
              }
              final child = CustomImageView(
                imagePath: path,
                height: 157.v,
                width: w[i],
                radius: BorderRadius.circular(6.h),
              );
              if (!canPreviewNetwork) {
                return child;
              }
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showDesignPreviewSheet(
                      context,
                      imageRef: url.trim(),
                      title: "lbl_online_designs".tr,
                    );
                  },
                  borderRadius: BorderRadius.circular(6.h),
                  child: child,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRectangleListSection(BuildContext context) {
    return SizedBox(
      height: 110.v,
      child:
          BlocSelector<
            Screen16OnlineDesignsBloc,
            Screen16OnlineDesignsState,
            Screen16OnlineDesignsModel?
          >(
            selector: (state) => state.screen16OnlineDesignsModelObj,
            builder: (context, screen16OnlineDesignsModelObj) {
              return ListView.separated(
                padding: EdgeInsets.only(left: 9.h),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) {
                  return SizedBox(width: 18.h);
                },
                itemCount:
                    screen16OnlineDesignsModelObj
                        ?.rectanglelistsectionItemList
                        .length ??
                    0,
                itemBuilder: (context, index) {
                  RectanglelistsectionItemModel model =
                      screen16OnlineDesignsModelObj
                          ?.rectanglelistsectionItemList[index] ??
                      RectanglelistsectionItemModel();
                  return RectanglelistsectionItemWidget(model);
                },
              );
            },
          ),
    );
  }

  Widget _buildListSection(BuildContext context) {
    return SizedBox(
      height: 110.v,
      child:
          BlocSelector<
            Screen16OnlineDesignsBloc,
            Screen16OnlineDesignsState,
            Screen16OnlineDesignsModel?
          >(
            selector: (state) => state.screen16OnlineDesignsModelObj,
            builder: (context, screen16OnlineDesignsModelObj) {
              return ListView.separated(
                padding: EdgeInsets.only(left: 9.h),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (context, index) {
                  return SizedBox(width: 18.h);
                },
                itemCount:
                    screen16OnlineDesignsModelObj?.listsectionItemList.length ??
                    0,
                itemBuilder: (context, index) {
                  ListsectionItemModel model =
                      screen16OnlineDesignsModelObj
                          ?.listsectionItemList[index] ??
                      ListsectionItemModel();
                  return ListsectionItemWidget(model);
                },
              );
            },
          ),
    );
  }
}
