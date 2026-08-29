// import 'package:flutter/material.dart';

// import '../../core/app_export.dart';
// import '../color_wheel_page/screen_11_color_wheel_page.dart';
// import 'bloc/screen_11_color_wheel_tab_container_bloc.dart';
// import 'models/screen_11_color_wheel_tab_container_model.dart';

// class Screen11ColorWheelTabContainerScreen extends StatefulWidget {
//   const Screen11ColorWheelTabContainerScreen({super.key});
//   @override
//   Screen11ColorWheelTabContainerScreenState createState() =>
//       Screen11ColorWheelTabContainerScreenState();
//   static Widget builder(BuildContext context) {
//     return BlocProvider<Screen11ColorWheelTabContainerBloc>(
//       create:
//           (context) => Screen11ColorWheelTabContainerBloc(
//             Screen11ColorWheelTabContainerState(
//               screen11ColorWheelTabContainerModelObj:
//                   const Screen11ColorWheelTabContainerModel(),
//             ),
//           )..add(Screen11ColorWheelTabContainerInitialEvent()),
//       child: const Screen11ColorWheelTabContainerScreen(),
//     );
//   }
// }

// class Screen11ColorWheelTabContainerScreenState
//     extends State<Screen11ColorWheelTabContainerScreen>
//     with TickerProviderStateMixin {
//   late TabController tabviewController;
//   @override
//   void initState() {
//     super.initState();
//     tabviewController = TabController(length: 5, vsync: this);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<
//       Screen11ColorWheelTabContainerBloc,
//       Screen11ColorWheelTabContainerState
//     >(
//       builder: (context, state) {
//         return SafeArea(
//           child: Scaffold(
//             body: SizedBox(
//               width: double.maxFinite,
//               child: Column(
//                 children: [
//                   SizedBox(height: 43.v),
//                   Column(
//                     children: [
//                       _buildRowView(context),
//                       SizedBox(height: 2.v),
//                       Align(
//                         alignment: Alignment.centerLeft,
//                         child: Container(
//                           height: 3.v,
//                           width: 19.h,
//                           margin: EdgeInsets.only(left: 28.h),
//                           decoration: BoxDecoration(
//                             color: theme.colorScheme.primary,
//                             borderRadius: BorderRadius.circular(1.h),
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 2.v),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: Padding(
//                           padding: EdgeInsets.only(right: 26.h),
//                           child: Text(
//                             "lbl_save".tr,
//                             style: CustomTextStyles.bodySmall10,
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: 81.v),
//                       SizedBox(
//                         height: 523.v,
//                         width: double.maxFinite,
//                         child: Stack(
//                           alignment: Alignment.bottomCenter,
//                           children: [
//                             Align(
//                               alignment: Alignment.topCenter,
//                               child: Container(
//                                 height: 409.adaptSize,
//                                 width: 409.adaptSize,
//                                 decoration: BoxDecoration(
//                                   color: appTheme.red70001,
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: appTheme.black900.withOpacity(
//                                         0.25,
//                                       ),
//                                       spreadRadius: 2.h,
//                                       blurRadius: 2.h,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             _buildTabView(context),
//                             _buildColumnViewSix(context),
//                           ],
//                         ),
//                       ),
//                       _buildTabBarView(context),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildRowView(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 28.h),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Container(
//             height: 3.v,
//             width: 30.h,
//             margin: EdgeInsets.only(top: 11.v, bottom: 5.v),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary,
//               borderRadius: BorderRadius.circular(1.h),
//             ),
//           ),
//           CustomImageView(
//             imagePath: ImageConstant.imgReply,
//             height: 19.adaptSize,
//             width: 19.adaptSize,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTabView(BuildContext context) {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         margin: EdgeInsets.only(left: 22.h, right: 14.h),
//         decoration: AppDecoration.fillPrimary.copyWith(
//           borderRadius: BorderRadiusStyle.roundedBorder33,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: EdgeInsets.only(right: 16.h),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     height: 35.adaptSize,
//                     width: 35.adaptSize,
//                     decoration: BoxDecoration(
//                       color: appTheme.red70001,
//                       borderRadius: BorderRadius.circular(17.h),
//                       border: Border.all(color: appTheme.gray50002, width: 1.h),
//                     ),
//                   ),
//                   const Spacer(flex: 50),
//                   Padding(
//                     padding: EdgeInsets.only(bottom: 3.v),
//                     child: Text(
//                       "lbl_hex".tr,
//                       style: CustomTextStyles.titleLargeBluegray90004,
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.only(left: 10.h, top: 7.v, bottom: 7.v),
//                     padding: EdgeInsets.symmetric(vertical: 1.v),
//                     decoration: AppDecoration.fillAmberA.copyWith(
//                       borderRadius: BorderRadiusStyle.roundedBorder4,
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CustomImageView(
//                           imagePath: ImageConstant.imgArrowUp,
//                           height: 8.adaptSize,
//                           width: 8.adaptSize,
//                         ),
//                         SizedBox(height: 1.v),
//                         SizedBox(width: 26.h, child: const Divider()),
//                         SizedBox(height: 1.v),
//                         CustomImageView(
//                           imagePath: ImageConstant.imgCheckmarkGray80003,
//                           height: 8.adaptSize,
//                           width: 8.adaptSize,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Spacer(flex: 50),
//                   CustomImageView(
//                     imagePath: ImageConstant.imgArrowRight,
//                     height: 9.adaptSize,
//                     width: 9.adaptSize,
//                     margin: EdgeInsets.symmetric(vertical: 13.v),
//                     onTap: () {
//                       onTapImgArrowrightone(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 213.v),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   margin: EdgeInsets.symmetric(vertical: 3.v),
//                   padding: EdgeInsets.all(1.h),
//                   decoration: AppDecoration.gradientRedAToRedA.copyWith(
//                     borderRadius: BorderRadiusStyle.roundedBorder7,
//                   ),
//                   child: Container(
//                     height: 14.adaptSize,
//                     width: 14.adaptSize,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(7.h),
//                       border: Border.all(
//                         color: theme.colorScheme.onPrimaryContainer.withOpacity(
//                           1,
//                         ),
//                         width: 1.h,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Container(
//                   width: 80.h,
//                   margin: EdgeInsets.only(left: 8.h),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 11.h,
//                     vertical: 1.v,
//                   ),
//                   decoration: AppDecoration.outlineGray.copyWith(
//                     borderRadius: BorderRadiusStyle.roundedBorder7,
//                   ),
//                   child: Text(
//                     "lbl_f83e64".tr,
//                     style: CustomTextStyles.bodySmallGray50001,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 5.v),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   height: 16.v,
//                   width: 303.h,
//                   margin: EdgeInsets.symmetric(vertical: 3.v),
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       CustomImageView(
//                         imagePath: ImageConstant.imgRectangle5507,
//                         height: 16.v,
//                         width: 303.h,
//                         radius: BorderRadius.circular(8.h),
//                         alignment: Alignment.center,
//                       ),
//                       Align(
//                         alignment: Alignment.center,
//                         child: Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 59.h,
//                             vertical: 1.v,
//                           ),
//                           decoration: AppDecoration.gradientRedAToRedA40001
//                               .copyWith(
//                                 borderRadius: BorderRadiusStyle.roundedBorder7,
//                               ),
//                           child: Container(
//                             height: 14.adaptSize,
//                             width: 14.adaptSize,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(7.h),
//                               border: Border.all(
//                                 color: theme.colorScheme.onPrimaryContainer
//                                     .withOpacity(1),
//                                 width: 1.h,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   width: 80.h,
//                   margin: EdgeInsets.only(left: 8.h),
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 30.h,
//                     vertical: 1.v,
//                   ),
//                   decoration: AppDecoration.outlineGray.copyWith(
//                     borderRadius: BorderRadiusStyle.roundedBorder7,
//                   ),
//                   child: Text(
//                     "lbl_75".tr,
//                     style: CustomTextStyles.bodySmallGray50001,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 24.v),
//             SizedBox(
//               height: 66.v,
//               width: 320.h,
//               child: TabBar(
//                 controller: tabviewController,
//                 labelPadding: EdgeInsets.zero,
//                 labelColor: theme.colorScheme.primary,
//                 labelStyle: TextStyle(
//                   fontSize: 8.fSize,
//                   fontFamily: 'Poppins',
//                   fontWeight: FontWeight.w400,
//                 ),
//                 unselectedLabelColor: appTheme.blueGray90004,
//                 unselectedLabelStyle: TextStyle(
//                   fontSize: 8.fSize,
//                   fontFamily: 'Poppins',
//                   fontWeight: FontWeight.w400,
//                 ),
//                 indicatorPadding: EdgeInsets.all(0.5.h),
//                 indicator: BoxDecoration(
//                   color: appTheme.blueGray90004,
//                   borderRadius: BorderRadius.circular(10.h),
//                 ),
//                 tabs: [
//                   Tab(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 16.h,
//                         vertical: 10.v,
//                       ),
//                       decoration: AppDecoration.fillYellow.copyWith(
//                         borderRadius: BorderRadiusStyle.roundedBorder10,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CustomImageView(
//                             imagePath: ImageConstant.imgColorPickerSvgrepoCom,
//                             height: 26.adaptSize,
//                             width: 26.adaptSize,
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 5.v, bottom: 1.v),
//                             child: Text("lbl_picker".tr),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Tab(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 17.h,
//                         vertical: 10.v,
//                       ),
//                       decoration: AppDecoration.fillBluegray90004.copyWith(
//                         borderRadius: BorderRadiusStyle.roundedBorder10,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           CustomImageView(
//                             imagePath: ImageConstant.imgColorWheelBlaPrimary,
//                             height: 22.adaptSize,
//                             width: 22.adaptSize,
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 9.v),
//                             child: Text("lbl_wheel".tr),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Tab(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 14.h,
//                         vertical: 9.v,
//                       ),
//                       decoration: AppDecoration.fillYellow.copyWith(
//                         borderRadius: BorderRadiusStyle.roundedBorder10,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           CustomImageView(
//                             imagePath: ImageConstant.imgColorSwatchSvgrepoCom,
//                             height: 24.adaptSize,
//                             width: 24.adaptSize,
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 9.v, bottom: 1.v),
//                             child: Text("lbl_swatch".tr),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Tab(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 8.h,
//                         vertical: 9.v,
//                       ),
//                       decoration: AppDecoration.fillYellow.copyWith(
//                         borderRadius: BorderRadiusStyle.roundedBorder10,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           CustomImageView(
//                             imagePath: ImageConstant.imgOpacitySvgrepoCom,
//                             height: 26.adaptSize,
//                             width: 26.adaptSize,
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 10.v),
//                             child: Text("lbl_transparency".tr),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Tab(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 10.h,
//                         vertical: 3.v,
//                       ),
//                       decoration: AppDecoration.fillYellow.copyWith(
//                         borderRadius: BorderRadiusStyle.roundedBorder10,
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           CustomImageView(
//                             imagePath: ImageConstant.imgRecentSvgrepoCom,
//                             height: 38.adaptSize,
//                             width: 38.adaptSize,
//                           ),
//                           Padding(
//                             padding: EdgeInsets.only(top: 1.v, bottom: 7.v),
//                             child: Text("lbl_recent".tr),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildColumnViewSix(BuildContext context) {
//     return Align(
//       alignment: Alignment.bottomCenter,
//       child: Container(
//         margin: EdgeInsets.only(bottom: 150.v),
//         padding: EdgeInsets.symmetric(horizontal: 106.h, vertical: 59.v),
//         decoration: AppDecoration.gradientBlackToRedA,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             SizedBox(height: 60.v),
//             Container(
//               height: 13.adaptSize,
//               width: 13.adaptSize,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(6.h),
//                 border: Border.all(
//                   color: theme.colorScheme.onPrimaryContainer.withOpacity(1),
//                   width: 1.h,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTabBarView(BuildContext context) {
//     return SizedBox(
//       height: 237.v,
//       child: TabBarView(
//         controller: tabviewController,
//         children: [
//           Screen11ColorWheelPage.builder(context),
//           Screen11ColorWheelPage.builder(context),
//           Screen11ColorWheelPage.builder(context),
//           Screen11ColorWheelPage.builder(context),
//           Screen11ColorWheelPage.builder(context),
//         ],
//       ),
//     );
//   }

//   onTapImgArrowrightone(BuildContext context) {
//     NavigatorService.pushNamed(
//       AppRoutes.screen9BackgroundColorTabContainerScreen,
//     );
//   }
// }
