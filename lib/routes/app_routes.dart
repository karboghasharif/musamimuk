import 'package:flutter/material.dart';

import '../presentation/add_logos_screen/screen_6_add_logos_screen.dart';
import '../presentation/add_new_screen/add_new_screen.dart';
import '../presentation/add_shape_screen/screen_5_add_shape_screen.dart';
import '../presentation/add_text_screen/screen_4_add_text_screen.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/background_color_tab_container_screen/screen_9_background_color_tab_container_screen.dart';
import '../presentation/color_picker_screen/screen_10_color_picker_screen.dart';
import '../presentation/color_wheel_tab_container_screen/screen_11_color_wheel_tab_container_screen.dart';
import '../presentation/home_screen/screen_1_home_screen.dart';
import '../presentation/favorites/favorites_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/login_screen/screen_0_login_screen.dart';
import '../presentation/profile_screen/change_password_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/my_designs_screen/screen_18_my_designs_screen.dart';
import '../presentation/new_design_screen/screen_2_new_design_screen.dart';
import '../presentation/online_designs_screen/screen_16_online_designs_screen.dart';
import '../presentation/open_design/open_design_deep_link_screen.dart';
import '../presentation/png_images_screen/screen_6_add_png_images_screen.dart';
import '../presentation/qr_code_genertaor_screen/enhanced_qr_generator_screen.dart';
import '../presentation/qr_code_genertaor_screen/screen_22_qr_code_genertaor_screen.dart';
import '../presentation/complete_profile_screen/complete_profile_screen.dart';
import '../presentation/register_screen/screen_0_register_screen.dart';
import '../presentation/remove_background_screen/background_removal_settings_screen.dart';
import '../presentation/remove_background_screen/enhanced_remove_background_screen.dart';
import '../presentation/remove_background_screen/screen_19_remove_background_screen.dart';
import '../presentation/remove_background_screen1/screen_20_remove_background_screen.dart';
import '../presentation/remove_background_screen2/screen_21_remove_background_screen.dart';
import '../presentation/resize_paper_screen/screen_7_resize_paper_screen.dart';
import '../presentation/contest/contest_feed_screen.dart';
import '../presentation/contest/contest_gallery_screen.dart';
import '../presentation/guest_upgrade/guest_upgrade_screen.dart';
import '../presentation/contest/contest_my_submissions_screen.dart';
import '../presentation/contest/contest_winners_screen.dart';
import '../presentation/screen_contest_screen/screen_contest_screen.dart';
import '../presentation/screen_contesttwo_screen/screen_contesttwo_screen.dart';
import '../presentation/ai_studio/ai_studio_chat_screen.dart';
import '../presentation/ai_studio/ai_studio_design_screen.dart';
import '../presentation/ai_studio/ai_studio_image_screen.dart';
import '../presentation/ai_studio/ai_studio_vision_screen.dart';
import '../presentation/about_us_screen/about_us_screen.dart';
import '../presentation/screen_twentythree_screen/screen_twentythree_screen.dart';
import '../presentation/search_bar_screen/screen_17_search_bar_screen.dart';
import '../presentation/subcription_screen/screen_1_subcription_screen.dart';
import '../presentation/swatch_tab_container_screen/screen_12_swatch_tab_container_screen.dart';
import '../presentation/transperant_bg_screen/screen_8_transperant_bg_screen.dart';
import '../presentation/wallet/coin_store_screen.dart';
import '../presentation/wallet/wallet_transactions_screen.dart';
import '../presentation/print/print_settings_screen.dart';
import '../presentation/print/print_shops_screen.dart';
import '../presentation/print/print_shop_profile_screen.dart';
import '../presentation/print/print_chat_screen.dart';
import '../presentation/print/print_tracking_screen.dart';
import '../presentation/print/print_orders_screen.dart';
import '../presentation/print/print_shop_screens.dart';

class AppRoutes {
  static const String screenTwentythreeScreen = '/screen_twentythree_screen';
  static const String screen0LoginScreen = '/screen_0_login_screen';
  static const String forgotPasswordScreen = '/forgot_password_screen';
  static const String root = '/root';
  static const String screen0RegisterScreen = '/screen_0_register_screen';
  static const String guestUpgradeScreen = '/guest_upgrade_screen';
  static const String completeProfileScreen = '/complete_profile_screen';
  static const String screen1HomeScreen = '/screen_1_home_screen';
  static const String profileScreen = '/profile_screen';
  static const String changePasswordScreen = '/change_password_screen';
  static const String screen1SubcriptionScreen = '/screen_1_subcription_screen';
  static const String coinStoreScreen = '/coin_store_screen';
  static const String walletTransactionsScreen = '/wallet_transactions_screen';
  static const String screen2NewDesignScreen = '/screen_2_new_design_screen';
  static const String screen3AddNewScreen = '/screen_3_add_new_screen';
  static const String screen4AddTextScreen = '/screen_4_add_text_screen';
  static const String screen5AddShapeScreen = '/screen_5_add_shape_screen';
  static const String screen6AddPngImagesScreen =
      '/screen_6_add_png_images_screen';
  static const String screen6AddLogosScreen = '/screen_6_add_logos_screen';
  static const String screen7ResizePaperScreen =
      '/screen_7_resize_paper_screen';
  static const String screen8TransperantBgScreen =
      '/screen_8_transperant_bg_screen';
  static const String screen9BackgroundColorPage =
      '/screen_9_background_color_page';
  static const String screen9BackgroundColorTabContainerScreen =
      '/screen_9_background_color_tab_container_screen';
  static const String screen10ColorPickerScreen =
      '/screen_10_color_picker_screen';
  static const String screen11ColorWheelPage = '/screen_11_color_wheel_page';
  static const String screen11ColorWheelTabContainerScreen =
      '/screen_11_color_wheel_tab_container_screen';
  static const String screen12SwatchPage = '/screen_12_swatch_page';
  static const String screen12SwatchTabContainerScreen =
      '/screen_12_swatch_tab_container_screen';
  static const String screen13TransperancyPage = '/screen_13_transperancy_page';
  static const String screen14RecentColorsPage =
      '/screen_14_recent_colors_page';
  static const String screenContesttwoScreen = '/screen_contesttwo_screen';
  static const String screenContestScreen = '/screen_contest_screen';
  static const String contestGalleryScreen = '/contest_gallery_screen';
  static const String contestFeedScreen = '/contest_feed_screen';
  static const String contestWinnersScreen = '/contest_winners_screen';
  static const String contestMySubmissionsScreen =
      '/contest_my_submissions_screen';
  static const String favoritesScreen = '/favorites_screen';
  static const String notificationsScreen = '/notifications_screen';
  static const String screen16OnlineDesignsScreen =
      '/screen_16_online_designs_screen';
  static const String screen17SearchBarScreen = '/screen_17_search_bar_screen';
  static const String screen18MyDesignsScreen = '/screen_18_my_designs_screen';
  static const String openDesignDeepLinkScreen = '/open_design_deep_link_screen';
  static const String screen19RemoveBackgroundScreen =
      '/screen_19_remove_background_screen';
  static const String enhancedRemoveBackgroundScreen =
      '/enhanced_remove_background_screen';
  static const String backgroundRemovalSettingsScreen =
      '/background_removal_settings_screen';
  static const String screen20RemoveBackgroundScreen =
      '/screen_20_remove_background_screen';
  static const String screen21RemoveBackgroundScreen =
      '/screen_21_remove_background_screen';
  static const String screen22QrCodeGenertaorScreen =
      '/screen_22_qr_code_genertaor_screen';
  static const String enhancedQrGeneratorScreen =
      '/enhanced_qr_generator_screen';
  static const String appNavigationScreen = '/app_navigation_screen';
  static const String aboutUsScreen = '/about_us_screen';
  static const String aiStudioImageScreen = '/ai_studio_image_screen';
  static const String aiStudioDesignScreen = '/ai_studio_design_screen';
  static const String aiStudioChatScreen = '/ai_studio_chat_screen';
  static const String aiStudioVisionScreen = '/ai_studio_vision_screen';
  static const String printSettingsScreen = '/print_settings_screen';
  static const String printShopsScreen = '/print_shops_screen';
  static const String printShopProfileScreen = '/print_shop_profile_screen';
  static const String printChatScreen = '/print_chat_screen';
  static const String printTrackingScreen = '/print_tracking_screen';
  static const String printOrdersScreen = '/print_orders_screen';
  static const String printShopRegisterScreen = '/print_shop_register_screen';
  static const String printShopHomeScreen = '/print_shop_home_screen';
  static const String printShopDashboardScreen = '/print_shop_dashboard_screen';
  static const String initialRoute = '/initialRoute';
  static Map<String, WidgetBuilder> get routes => {
    screenTwentythreeScreen: ScreenTwentythreeScreen.builder,
    screen0LoginScreen: Screen0LoginScreen.builder,
    forgotPasswordScreen: ForgotPasswordScreen.builder,
    // root: (_) => RootScreen(),
    screen0RegisterScreen: Screen0RegisterScreen.builder,
    guestUpgradeScreen: GuestUpgradeScreen.builder,
    completeProfileScreen: CompleteProfileScreen.builder,
    screen1HomeScreen: Screen1HomeScreen.builder,
    profileScreen: ProfileScreen.builder,
    changePasswordScreen: ChangePasswordScreen.builder,
    screen1SubcriptionScreen: Screen1SubcriptionScreen.builder,
    coinStoreScreen: CoinStoreScreen.builder,
    walletTransactionsScreen: WalletTransactionsScreen.builder,
    screen2NewDesignScreen: Screen2NewDesignScreen.builder,
    screen3AddNewScreen: AddNewScreen.builder,

    // screen3AddNewScreen: AddNewScreen.builder,
    // screen4AddTextScreen: Screen4AddTextScreen.builder,
    // screen5AddShapeScreen: Screen5AddShapeScreen.builder,
    screen6AddPngImagesScreen: Screen6AddPngImagesScreen.builder,
    // screen6AddLogosScreen: Screen6AddLogosScreen.builder,
    screen7ResizePaperScreen: Screen7ResizePaperScreen.builder,
    screen8TransperantBgScreen: Screen8TransperantBgScreen.builder,
    screen9BackgroundColorTabContainerScreen:
        Screen9BackgroundColorTabContainerScreen.builder,
    // screen10ColorPickerScreen: Screen10ColorPickerScreen.builder,
    // screen11ColorWheelTabContainerScreen:
    //     Screen11ColorWheelTabContainerScreen.builder,
    screen12SwatchTabContainerScreen: Screen12SwatchTabContainerScreen.builder,
    screenContesttwoScreen: ScreenContesttwoScreen.builder,
    screenContestScreen: ScreenContestScreen.builder,
    contestGalleryScreen: ContestGalleryScreen.builder,
    contestFeedScreen: ContestFeedScreen.builder,
    contestWinnersScreen: ContestWinnersScreen.builder,
    contestMySubmissionsScreen: ContestMySubmissionsScreen.builder,
    screen16OnlineDesignsScreen: Screen16OnlineDesignsScreen.builder,
    screen17SearchBarScreen: Screen17SearchBarScreen.builder,
    screen18MyDesignsScreen: Screen18MyDesignsScreen.builder,
    openDesignDeepLinkScreen: OpenDesignDeepLinkScreen.builder,
    favoritesScreen: FavoritesScreen.builder,
    notificationsScreen: NotificationsScreen.builder,
    screen19RemoveBackgroundScreen: Screen19RemoveBackgroundScreen.builder,
    enhancedRemoveBackgroundScreen: EnhancedRemoveBackgroundScreen.builder,
    backgroundRemovalSettingsScreen: BackgroundRemovalSettingsScreen.builder,
    screen20RemoveBackgroundScreen: Screen20RemoveBackgroundScreen.builder,
    screen21RemoveBackgroundScreen: Screen21RemoveBackgroundScreen.builder,
    screen22QrCodeGenertaorScreen: Screen22QrCodeGenertaorScreen.builder,
    enhancedQrGeneratorScreen: EnhancedQrGeneratorScreen.builder,
    // appNavigationScreen: AppNavigationScreen.builder,
    aboutUsScreen: AboutUsScreen.builder,
    aiStudioImageScreen: AiStudioImageScreen.builder,
    aiStudioDesignScreen: AiStudioDesignScreen.builder,
    aiStudioChatScreen: AiStudioChatScreen.builder,
    aiStudioVisionScreen: AiStudioVisionScreen.builder,
    printSettingsScreen: PrintSettingsScreen.builder,
    printShopsScreen: PrintShopsScreen.builder,
    printShopProfileScreen: PrintShopProfileScreen.builder,
    printChatScreen: PrintChatScreen.builder,
    printTrackingScreen: PrintTrackingScreen.builder,
    printOrdersScreen: PrintOrdersScreen.builder,
    printShopRegisterScreen: PrintShopRegisterScreen.builder,
    printShopHomeScreen: PrintShopHomeScreen.builder,
    printShopDashboardScreen: PrintShopDashboardScreen.builder,
    initialRoute: ScreenTwentythreeScreen.builder,
  };
}
