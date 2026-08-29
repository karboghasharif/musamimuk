// import 'package:flutter/material.dart';
// import '../../core/app_export.dart';
// import '../../widgets/app_bar/appbar_leading_image.dart';
// import '../../widgets/app_bar/custom_app_bar.dart';
// import '../../widgets/custom_pin_code_text_field.dart';
// import 'bloc/screen_5_add_shape_bloc.dart';
// import 'models/screen_5_add_shape_model.dart';

// class Screen5AddShapeScreen extends StatelessWidget {
//   const Screen5AddShapeScreen({super.key});
//   static Widget builder(BuildContext context) {
//     return BlocProvider<Screen5AddShapeBloc>(
//       create: (context) => Screen5AddShapeBloc(Screen5AddShapeState(
//         screen5AddShapeModelObj: const Screen5AddShapeModel(),
//       ))
//         ..add(Screen5AddShapeInitialEvent()),
//       child: const Screen5AddShapeScreen(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: AppDs.surfaceBase,
//         resizeToAvoidBottomInset: false,
//         appBar: _buildAppBar(context),
//         body: SingleChildScrollView(
//           padding: EdgeInsets.fromLTRB(
//             AppDs.space4.h,
//             AppDs.space3.v,
//             AppDs.space4.h,
//             AppDs.space4.v,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               AppPageHeader(
//                 title: 'lbl_shapes'.tr,
//                 subtitle: 'msg_screen_5_add_shape'.tr,
//               ),
//               SizedBox(height: AppDs.space4.v),
//               BlocSelector<Screen5AddShapeBloc, Screen5AddShapeState,
//                   TextEditingController?>(
//                 selector: (state) => state.searchController,
//                 builder: (context, searchController) {
//                   return AppSearchField(
//                     controller: searchController,
//                     hintText: 'lbl_search'.tr,
//                   );
//                 },
//               ),
//               SizedBox(height: AppDs.space4.v),
//               _buildStackHomeOne(context),
//               SizedBox(height: AppDs.space6.v),
//               _buildSectionHeader(
//                 context,
//                 badgeText: 'lbl_basic'.tr,
//                 seeAllText: 'lbl_see_all'.tr,
//               ),
//               SizedBox(height: AppDs.space4.v),
//               _buildRowView(context),
//               SizedBox(height: AppDs.space6.v),
//               _buildSectionHeader(
//                 context,
//                 badgeText: 'lbl_blob'.tr,
//                 seeAllText: 'lbl_see_all'.tr,
//               ),
//               SizedBox(height: AppDs.space4.v),
//               Padding(
//                 padding: EdgeInsets.only(left: AppDs.space2.h),
//                 child: BlocSelector<Screen5AddShapeBloc, Screen5AddShapeState,
//                     TextEditingController?>(
//                   selector: (state) => state.otpController,
//                   builder: (context, otpController) {
//                     return CustomPinCodeTextField(
//                       context: context,
//                       controller: otpController,
//                       onChanged: (value) {
//                         otpController?.text = value;
//                       },
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: AppDs.space6.v),
//               _buildSectionHeader(
//                 context,
//                 badgeText: 'lbl_badges'.tr,
//                 seeAllText: 'lbl_see_all'.tr,
//               ),
//               SizedBox(height: AppDs.space4.v),
//               _buildRowCloseOne(context),
//               SizedBox(height: AppDs.space6.v),
//               _buildSectionHeader(
//                 context,
//                 badgeText: 'msg_animals_stickers'.tr,
//                 seeAllText: 'lbl_see_all'.tr,
//               ),
//               SizedBox(height: AppDs.space4.v),
//               _buildRowFlamingoOne(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return CustomAppBar(
//       leading: AppbarLeadingImage(
//         imagePath: ImageConstant.imgArrowLeftPrimary,
//         margin: EdgeInsets.only(left: AppDs.space4.h),
//       ),
//     );
//   }

//   Widget _buildStackHomeOne(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           Container(
//             height: 43.v,
//             width: 48.h,
//             padding: EdgeInsets.symmetric(
//               horizontal: AppDs.space3.h,
//               vertical: AppDs.space2.v,
//             ),
//             decoration: AppDecoration.fillGray800.copyWith(
//               borderRadius: BorderRadiusStyle.roundedBorder15,
//             ),
//             child: CustomImageView(
//               imagePath: ImageConstant.imgHome,
//               height: AppDs.iconMd.adaptSize,
//               width: AppDs.iconMd.adaptSize,
//               alignment: Alignment.center,
//             ),
//           ),
//           SizedBox(width: AppDs.space4.h),
//           AppText('lbl_basic'.tr, variant: AppTextVariant.body),
//           SizedBox(width: AppDs.space4.h),
//           AppText('lbl_blob'.tr, variant: AppTextVariant.body),
//           SizedBox(width: AppDs.space4.h),
//           AppText('lbl_badges'.tr, variant: AppTextVariant.body),
//           SizedBox(width: AppDs.space4.h),
//           AppText('lbl_borders'.tr, variant: AppTextVariant.body),
//           SizedBox(width: AppDs.space4.h),
//           AppText('lbl_islamic'.tr, variant: AppTextVariant.body),
//         ],
//       ),
//     );
//   }

//   Widget _buildRowView(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           Container(
//             height: 90.v,
//             width: 104.h,
//             decoration: BoxDecoration(
//               color: appTheme.blueGray100,
//               borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
//             ),
//           ),
//           SizedBox(width: AppDs.space6.h),
//           Container(
//             height: 69.adaptSize,
//             width: 69.adaptSize,
//             decoration: BoxDecoration(
//               color: appTheme.blueGray100,
//               borderRadius: BorderRadius.circular(34.h),
//             ),
//           ),
//           SizedBox(width: AppDs.space6.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgRectangle5488,
//             height: 40.v,
//             width: 104.h,
//             radius: BorderRadius.circular(AppDs.radiusSm.h),
//           ),
//           SizedBox(width: AppDs.space6.h),
//           Container(
//             height: 63.adaptSize,
//             width: 63.adaptSize,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(31.h),
//               border: Border.all(
//                 color: appTheme.blueGray100,
//                 width: 3.h,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRowCloseOne(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           CustomImageView(
//             imagePath: ImageConstant.imgBadgesStarSvgrepoCom,
//             height: 60.adaptSize,
//             width: 60.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgClose,
//             height: 60.adaptSize,
//             width: 60.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgSignal,
//             height: 62.adaptSize,
//             width: 62.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgNameBadgeSvgrepoCom,
//             height: 64.adaptSize,
//             width: 64.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgSettings,
//             height: 64.adaptSize,
//             width: 64.adaptSize,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRowFlamingoOne(BuildContext context) {
//     return SingleChildScrollView(
//       scrollDirection: Axis.horizontal,
//       child: Row(
//         children: [
//           CustomImageView(
//             imagePath: ImageConstant.imgFlamingo1,
//             height: 64.adaptSize,
//             width: 64.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgTiger1,
//             height: 64.adaptSize,
//             width: 64.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgGiraffe1,
//             height: 62.adaptSize,
//             width: 62.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgElephant1,
//             height: 68.adaptSize,
//             width: 68.adaptSize,
//           ),
//           SizedBox(width: AppDs.space4.h),
//           CustomImageView(
//             imagePath: ImageConstant.imgGiraffe1,
//             height: 62.adaptSize,
//             width: 62.adaptSize,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeader(
//     BuildContext context, {
//     required String badgeText,
//     required String seeAllText,
//   }) {
//     return AppSectionHeader(
//       title: badgeText,
//       trailing: AppText(
//         seeAllText,
//         variant: AppTextVariant.accent,
//       ),
//     );
//   }
// }
