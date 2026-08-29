// import 'package:flutter/material.dart';
// import '../../core/app_export.dart';
// import 'bloc/app_navigation_bloc.dart';
// import 'models/app_navigation_model.dart';

// class AppNavigationScreen extends StatelessWidget {
//   const AppNavigationScreen({super.key});
//   static Widget builder(BuildContext context) {
//     return BlocProvider<AppNavigationBloc>(
//       create: (context) => AppNavigationBloc(AppNavigationState(
//         appNavigationModelObj: const AppNavigationModel(),
//       ))
//         ..add(AppNavigationInitialEvent()),
//       child: const AppNavigationScreen(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppNavigationBloc, AppNavigationState>(
//       builder: (context, state) {
//         return SafeArea(
//           child: Scaffold(
//             backgroundColor:
//                 theme.colorScheme.onPrimaryContainer.withOpacity(1),
//             body: SizedBox(
//               width: 375.h,
//               child: Column(
//                 children: [
//                   _buildAppNavigation(context),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Container(
//                         decoration: AppDecoration.fillOnPrimaryContainer,
//                         child: Column(
//                           children: [
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_twentythree".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screenTwentythreeScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "lbl_screen_0_login".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen0LoginScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_0_register".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen0RegisterScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "lbl_screen_1_home".tr,
//                               onTapScreenTitle: () =>
//                                   onTapScreenTitle(AppRoutes.screen1HomeScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_1_subcription".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen1SubcriptionScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_2_new_design".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen2NewDesignScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_3_add_new".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen3AddNewScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_4_add_text".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen4AddTextScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_5_add_shape".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen5AddShapeScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_6_add_png".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen6AddPngImagesScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_6_add_logos".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen6AddLogosScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_7_resize".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen7ResizePaperScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_8_transperant".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen8TransperantBgScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_9_background".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(AppRoutes
//                                   .screen9BackgroundColorTabContainerScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_10_color".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen10ColorPickerScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_11_color".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(AppRoutes
//                                   .screen11ColorWheelTabContainerScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_12_swatch".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen12SwatchTabContainerScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_contesttwo".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screenContestScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_contest".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screenContestScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_16_online".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen16OnlineDesignsScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_17_search".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen17SearchBarScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_18_my_designs".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen18MyDesignsScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_19_remove".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen19RemoveBackgroundScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_20_remove".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen20RemoveBackgroundScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_21_remove".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen21RemoveBackgroundScreen),
//                             ),
//                             _buildScreenTitle(
//                               context,
//                               screenTitle: "msg_screen_22_qr_code".tr,
//                               onTapScreenTitle: () => onTapScreenTitle(
//                                   AppRoutes.screen22QrCodeGenertaorScreen),
//                             )
//                           ],
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAppNavigation(BuildContext context) {
//     return Container(
//       decoration: AppDecoration.fillOnPrimaryContainer,
//       child: Column(
//         children: [
//           SizedBox(height: 10.v),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20.h),
//               child: Text(
//                 "lbl_app_navigation".tr,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: appTheme.black900,
//                   fontSize: 20.fSize,
//                   fontFamily: 'Roboto',
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 10.v),
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Padding(
//               padding: EdgeInsets.only(left: 20.h),
//               child: Text(
//                 "msg_check_your_app_s".tr,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: appTheme.blueGray400,
//                   fontSize: 16.fSize,
//                   fontFamily: 'Roboto',
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 5.v),
//           Divider(
//             height: 1.v,
//             thickness: 1.v,
//             color: appTheme.black900,
//           )
//         ],
//       ),
//     );
//   }

//   Widget _buildScreenTitle(
//     BuildContext context, {
//     required String screenTitle,
//     Function? onTapScreenTitle,
//   }) {
//     return GestureDetector(
//       onTap: () {
//         onTapScreenTitle?.call();
//       },
//       child: Container(
//         decoration: AppDecoration.fillOnPrimaryContainer,
//         child: Column(
//           children: [
//             SizedBox(height: 10.v),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.h),
//                 child: Text(
//                   screenTitle,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: appTheme.black900,
//                     fontSize: 20.fSize,
//                     fontFamily: 'Roboto',
//                     fontWeight: FontWeight.w400,
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 10.v),
//             SizedBox(height: 5.v),
//             Divider(
//               height: 1.v,
//               thickness: 1.v,
//               color: appTheme.blueGray400,
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   void onTapScreenTitle(String routeName) {
//     NavigatorService.pushNamed(routeName);
//   }
// }
