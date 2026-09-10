import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/country_names.dart';
import '../../data/repositories/auth_repository.dart';
import '../print/print_reputation_card.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../wallet/wallet_auth_sync.dart';

/// Profile settings: labeled fields, photo, country selector, change password.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Widget builder(BuildContext context) {
    return const ProfileScreen();
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _email;
  late final TextEditingController _name;
  late final TextEditingController _bio;
  String? _selectedCountry;
  String? _avatarImageUri;
  bool _isLoadingProfile = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final sessionMap = PrefUtils().getUserSession();
    final session =
        sessionMap != null ? UserSession.fromJson(sessionMap) : null;
    _email = TextEditingController(text: session?.email ?? '');
    _name = TextEditingController(text: session?.name ?? '');
    _bio = TextEditingController(text: session?.bio ?? '');
    final c = session?.country?.trim();
    _selectedCountry = (c != null && c.isNotEmpty) ? c : null;
    _avatarImageUri = session?.image?.trim().isNotEmpty == true
        ? session!.image!.trim()
        : null;

    // If logged in, refresh from server to keep UI and session in sync.
    if (PrefUtils().isLoggedIn()) {
      _refreshProfileFromServer();
    }
  }

  Future<void> _refreshProfileFromServer() async {
    setState(() => _isLoadingProfile = true);
    try {
      final result = await AuthRepository().profile();
      if (!mounted) return;
      if (result is ProfileSuccess) {
        await PrefUtils().setUserSession(result.user.toJson());
        _email.text = result.user.email ?? '';
        _name.text = result.user.name ?? '';
        _bio.text = result.user.bio ?? '';
        final c = result.user.country?.trim();
        _selectedCountry = (c != null && c.isNotEmpty) ? c : null;
        _avatarImageUri =
            result.user.image?.trim().isNotEmpty == true ? result.user.image : null;
      } else if (result is ProfileFailure) {
        showAppToast(result.message, type: ToastificationType.warning);
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  List<String> get _countryItems {
    final list = List<String>.from(kSelectableCountryNames);
    final sel = _selectedCountry;
    if (sel != null && sel.isNotEmpty && !list.contains(sel)) {
      list.insert(0, sel);
    }
    return list;
  }

  String _initialFromName(String? name) {
    final t = name?.trim() ?? '';
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  Widget _buildAvatar(String? name, Color primary, Color onPrimary) {
    final img = _avatarImageUri?.trim() ?? '';
    if (img.isNotEmpty) {
      if (img.startsWith('file://')) {
        final path = Uri.parse(img).toFilePath();
        return ClipOval(
          child: Image.file(
            File(path),
            width: 106.adaptSize,
            height: 106.adaptSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => CircleAvatar(
              radius: 53.adaptSize,
              backgroundColor: primary,
              child: Text(
                _initialFromName(name),
                style: TextStyle(
                  fontSize: 40.fSize,
                  fontWeight: FontWeight.w700,
                  color: onPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        );
      }
      return ClipOval(
        child: CustomImageView(
          imagePath: img,
          width: 106.adaptSize,
          height: 106.adaptSize,
          fit: BoxFit.cover,
        ),
      );
    }
    return CircleAvatar(
      radius: 53.adaptSize,
      backgroundColor: primary,
      child: Text(
        _initialFromName(name),
        style: TextStyle(
          fontSize: 40.fSize,
          fontWeight: FontWeight.w700,
          color: onPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final source = await showAppModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'lbl_edit_photo'.tr,
                textAlign: TextAlign.center,
                style: AppDs.sheetTitle(theme, color: Colors.white),
              ),
              SizedBox(height: AppDs.space4.v),
              AppSheetOptionTile(
                icon: Icons.photo_camera_outlined,
                title: 'lbl_camera'.tr,
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              AppSheetOptionTile(
                icon: Icons.photo_library_outlined,
                title: 'lbl_photo_library'.tr,
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    setState(() {
      _avatarImageUri = 'file://${x.path}';
    });
  }

  Future<void> _onSave() async {
    if (!PrefUtils().isLoggedIn()) {
      showAppToast('msg_profile_requires_login'.tr, type: ToastificationType.warning);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final name = _name.text.trim().isEmpty ? null : _name.text.trim();
      final email = _email.text.trim().isEmpty ? null : _email.text.trim();
      final country = (_selectedCountry == null || _selectedCountry!.trim().isEmpty)
          ? null
          : _selectedCountry!.trim();
      final bio = _bio.text.trim().isEmpty ? null : _bio.text.trim();

      String? imagePath;
      final img = _avatarImageUri?.trim() ?? '';
      if (img.startsWith('file://')) {
        imagePath = Uri.parse(img).toFilePath();
      }

      final result = await AuthRepository().updateProfile(
        name: name,
        email: email,
        country: country,
        bio: bio,
        imagePath: imagePath,
      );

      if (!mounted) return;
      if (result is ProfileSuccess) {
        await PrefUtils().setUserSession(result.user.toJson());
        showAppToast(
          (result.message?.trim().isNotEmpty == true)
              ? result.message!.trim()
              : 'lbl_save'.tr,
          type: ToastificationType.success,
        );
      } else if (result is ProfileFailure) {
        showAppToast(result.message, type: ToastificationType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openChangePassword() {
    Navigator.pushNamed(context, AppRoutes.changePasswordScreen);
  }

  void _openUpgradePlan() {
    NavigatorService.pushNamed(AppRoutes.screen1SubcriptionScreen);
  }

  /// Maps API/session `subscription_plan` to Free vs Pro for display.
  static bool _sessionIsPro(UserSession session) {
    final raw = session.subscriptionPlan?.trim() ?? '';
    if (raw.isEmpty) return false;
    final s = raw.toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes') return true;
    return s.contains('pro') ||
        s.contains('premium') ||
        s.contains('paid') ||
        s.contains('subscriber') ||
        s.contains('gold') ||
        s.contains('vip');
  }

  static String _planTierLabel(UserSession session) {
    return _sessionIsPro(session) ? 'lbl_pro'.tr : 'lbl_free'.tr;
  }

  Future<void> _logout() async {
    try {
      await AuthRepository().logout();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    syncWalletAfterAuth(forceReset: true);
    await SessionManager.instance.logout();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final err = theme.colorScheme.error;
        return AlertDialog(
          backgroundColor: AppDs.surfaceElevated,
          title: Text(
            'msg_delete_account_title'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'msg_delete_account_warning'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'lbl_cancel'.tr,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: err,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('lbl_delete_account'.tr),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      await AuthRepository().logout();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    if (!mounted) return;
    showAppToast(
      'msg_delete_account_session_cleared'.tr,
      type: ToastificationType.success,
    );
    syncWalletAfterAuth(forceReset: true);
    await SessionManager.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final sessionMap = PrefUtils().getUserSession();
    final session =
        sessionMap != null ? UserSession.fromJson(sessionMap) : null;
    final isGuest = PrefUtils().isGuestAccount();
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
        ),
        body: session == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDs.space6.h),
                  child: AppText(
                    'msg_profile_no_session'.tr,
                    variant: AppTextVariant.body,
                    color: AppDs.textOnDarkSecondary,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : AppLoadingOverlay(
                isLoading: _isLoadingProfile || _isSaving,
                message: _isSaving ? 'lbl_save'.tr : null,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space4.h,
                          AppDs.space3.v,
                          AppDs.space4.h,
                          AppDs.space4.v,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppPageHeader(
                              title: 'lbl_profile_settings'.tr,
                              subtitle: 'msg_manage_personal_info'.tr,
                            ),
                            SizedBox(height: AppDs.space4.v),
                            Center(
                              child: _buildAvatar(
                                session.name,
                                primary,
                                onPrimary,
                              ),
                            ),
                            SizedBox(height: AppDs.space3.v),
                            Center(
                              child: TextButton.icon(
                                onPressed: _pickProfilePhoto,
                                icon: Icon(
                                  Icons.photo_camera_outlined,
                                  size: AppDs.iconSm.adaptSize,
                                  color: primary,
                                ),
                                label: AppText(
                                  'lbl_edit_photo'.tr,
                                  variant: AppTextVariant.accent,
                                ),
                              ),
                            ),
                            SizedBox(height: AppDs.space2.v),
                            AppText(
                              session.name?.trim().isNotEmpty == true
                                  ? session.name!.trim()
                                  : 'lbl_jonathan_saul'.tr,
                              variant: AppTextVariant.title,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppDs.space6.v),
                            if (!PrefUtils().isGuestAccount())
                              const PrintReputationCard(),
                            AppCard(
                              elevated: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _LabeledProfileTextField(
                                    label: 'lbl_email'.tr,
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  SizedBox(height: AppDs.space4.v),
                                  _LabeledProfileTextField(
                                    label: 'lbl_username'.tr,
                                    controller: _name,
                                    keyboardType: TextInputType.name,
                                  ),
                                  SizedBox(height: AppDs.space4.v),
                                  _LabeledCountryDropdown(
                                    label: 'lbl_country'.tr,
                                    value: _selectedCountry,
                                    items: _countryItems,
                                    onChanged: (v) =>
                                        setState(() => _selectedCountry = v),
                                  ),
                                  SizedBox(height: AppDs.space4.v),
                                  _LabeledProfileTextField(
                                    label: 'lbl_optional_info'.tr,
                                    controller: _bio,
                                    maxLines: 3,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppDs.space4.v),
                            AppCard(
                              elevated: true,
                              child: _PlanTierSection(
                                displayLabel: _planTierLabel(session),
                                isPro: _sessionIsPro(session),
                                showUpgrade: !isGuest,
                                onUpgrade: _openUpgradePlan,
                              ),
                            ),
                            if (!isGuest) ...[
                              SizedBox(height: AppDs.space4.v),
                              AppCard(
                                elevated: true,
                                child: _ChangePasswordRow(
                                  onTap: _openChangePassword,
                                ),
                              ),
                            ],
                            SizedBox(height: AppDs.space6.v),
                            AppSectionHeader(title: 'lbl_account_actions'.tr),
                            AppCard(
                              elevated: true,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDs.space3.h,
                                vertical: AppDs.space2.v,
                              ),
                              child: Column(
                                children: [
                                  if (isGuest) ...[
                                    _AccountActionRow(
                                      icon: Icons.login,
                                      title: 'lbl_sign_in'.tr,
                                      iconAndTextColor: primary,
                                      onTap: () => NavigatorService.pushNamed(
                                        AppRoutes.screen0LoginScreen,
                                      ),
                                    ),
                                    SizedBox(height: AppDs.space2.v),
                                    _AccountActionRow(
                                      icon: Icons.person_add_outlined,
                                      title: 'lbl_create_account'.tr,
                                      iconAndTextColor: primary,
                                      onTap: () => NavigatorService.pushNamed(
                                        AppRoutes.guestUpgradeScreen,
                                      ),
                                    ),
                                    SizedBox(height: AppDs.space2.v),
                                    _AccountActionRow(
                                      icon: Icons.logout,
                                      title: 'lbl_log_out'.tr,
                                      iconAndTextColor: Colors.white,
                                      onTap: _logout,
                                    ),
                                  ] else ...[
                                    _AccountActionRow(
                                      icon: Icons.logout,
                                      title: 'lbl_log_out'.tr,
                                      iconAndTextColor: Colors.white,
                                      onTap: _logout,
                                    ),
                                    SizedBox(height: AppDs.space2.v),
                                    _AccountActionRow(
                                      icon: Icons.delete_forever_outlined,
                                      title: 'lbl_delete_account'.tr,
                                      iconAndTextColor:
                                          theme.colorScheme.error,
                                      onTap: _confirmDeleteAccount,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: AppDs.space6.v),
                          ],
                        ),
                      ),
                    ),
                    if (!isGuest)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDs.space4.h,
                          0,
                          AppDs.space4.h,
                          AppDs.space5.v,
                        ),
                        child: AppPrimaryButton(
                          label: 'lbl_save'.tr,
                          isLoading: _isLoadingProfile || _isSaving,
                          onPressed: (_isLoadingProfile || _isSaving)
                              ? null
                              : _onSave,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PlanTierSection extends StatelessWidget {
  const _PlanTierSection({
    required this.displayLabel,
    required this.isPro,
    required this.showUpgrade,
    required this.onUpgrade,
  });

  final String displayLabel;
  final bool isPro;
  final bool showUpgrade;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('lbl_plan'.tr, variant: AppTextVariant.caption),
        SizedBox(height: AppDs.space2.v),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4.h,
            vertical: AppDs.space4.v,
          ),
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(
                isPro
                    ? Icons.workspace_premium_outlined
                    : Icons.card_giftcard_outlined,
                color: primary,
                size: AppDs.iconMd.adaptSize,
              ),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: AppText(displayLabel, variant: AppTextVariant.title),
              ),
            ],
          ),
        ),
        if (showUpgrade) ...[
          SizedBox(height: AppDs.space3.v),
          AppSecondaryButton(
            label: 'lbl_upgrade_plan'.tr,
            onPressed: onUpgrade,
          ),
        ],
      ],
    );
  }
}

class _LabeledProfileTextField extends StatelessWidget {
  const _LabeledProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, variant: AppTextVariant.caption),
        SizedBox(height: AppDs.space2.v),
        Container(
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTypography.body(theme),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppDs.space4.h,
                vertical: maxLines > 1 ? AppDs.space3.v : AppDs.space4.v,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledCountryDropdown extends StatelessWidget {
  const _LabeledCountryDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, variant: AppTextVariant.caption),
        SizedBox(height: AppDs.space2.v),
        Container(
          padding: EdgeInsets.symmetric(horizontal: AppDs.space3.h),
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value != null && items.contains(value) ? value : null,
              hint: AppText(
                'lbl_select_country_placeholder'.tr,
                variant: AppTextVariant.body,
                color: AppDs.textOnDarkDisabled,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
              ),
              dropdownColor: AppDs.surfaceElevated,
              style: AppTypography.body(theme),
              items: items
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.icon,
    required this.title,
    required this.iconAndTextColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color iconAndTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDs.surfaceRaised,
      borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space4.h,
            vertical: AppDs.space4.v,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconAndTextColor, size: AppDs.iconMd.adaptSize),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body(theme).copyWith(
                    color: iconAndTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppDs.textOnDarkDisabled,
                size: AppDs.iconMd.adaptSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordRow extends StatelessWidget {
  const _ChangePasswordRow({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText('lbl_security'.tr, variant: AppTextVariant.caption),
        SizedBox(height: AppDs.space2.v),
        Material(
          color: AppDs.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDs.space4.h,
                vertical: AppDs.space4.v,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_reset_outlined,
                    color: primary,
                    size: AppDs.iconMd.adaptSize,
                  ),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: AppText(
                      'lbl_change_password'.tr,
                      variant: AppTextVariant.body,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppDs.textOnDarkDisabled,
                    size: AppDs.iconMd.adaptSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
