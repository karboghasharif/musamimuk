import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/country_names.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

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
  static const Color _pageBackground = Color(0xFF282C31);
  static const Color _fieldBackground = Color(0xFF343A40);

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
    setState(() => _isLoadingProfile = false);
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
        (result.message?.trim().isNotEmpty == true) ? result.message!.trim() : 'lbl_save'.tr,
        type: ToastificationType.success,
      );
    } else if (result is ProfileFailure) {
      showAppToast(result.message, type: ToastificationType.error);
    }
    setState(() => _isSaving = false);
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
    await PrefUtils().clearAuth();
    if (!mounted) return;
    NavigatorService.pushNamedAndRemoveUntil(
      AppRoutes.screen0LoginScreen,
      routePredicate: false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final err = theme.colorScheme.error;
        return AlertDialog(
          backgroundColor: _fieldBackground,
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
    await PrefUtils().clearAuth();
    if (!mounted) return;
    showAppToast(
      'msg_delete_account_session_cleared'.tr,
      type: ToastificationType.success,
    );
    NavigatorService.pushNamedAndRemoveUntil(
      AppRoutes.screen0LoginScreen,
      routePredicate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionMap = PrefUtils().getUserSession();
    final session =
        sessionMap != null ? UserSession.fromJson(sessionMap) : null;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
          title: Padding(
            padding: EdgeInsets.only(left: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'lbl_profile_settings'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ),
        body: session == null
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.h),
                  child: Text(
                    'msg_profile_no_session'.tr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 8.v),
                          Text(
                            'msg_manage_personal_info'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                          SizedBox(height: 20.v),
                          Center(child: _buildAvatar(session.name, primary, onPrimary)),
                          SizedBox(height: 12.v),
                          Center(
                            child: TextButton.icon(
                              onPressed: _pickProfilePhoto,
                              icon: Icon(
                                Icons.photo_camera_outlined,
                                size: 20.adaptSize,
                                color: primary,
                              ),
                              label: Text(
                                'lbl_edit_photo'.tr,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.v),
                          Text(
                            session.name?.trim().isNotEmpty == true
                                ? session.name!.trim()
                                : 'lbl_jonathan_saul'.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 20.v),
                          Container(
                            height: 2.v,
                            margin: EdgeInsets.symmetric(horizontal: 8.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  primary.withValues(alpha: 0.95),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 24.v),
                          _LabeledProfileTextField(
                            label: 'lbl_email'.tr,
                            controller: _email,
                            fieldBg: _fieldBackground,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: 18.v),
                          _LabeledProfileTextField(
                            label: 'lbl_username'.tr,
                            controller: _name,
                            fieldBg: _fieldBackground,
                            keyboardType: TextInputType.name,
                          ),
                          SizedBox(height: 18.v),
                          _LabeledCountryDropdown(
                            label: 'lbl_country'.tr,
                            value: _selectedCountry,
                            items: _countryItems,
                            fieldBg: _fieldBackground,
                            onChanged: (v) =>
                                setState(() => _selectedCountry = v),
                          ),
                          SizedBox(height: 18.v),
                          _LabeledProfileTextField(
                            label: 'lbl_optional_info'.tr,
                            controller: _bio,
                            fieldBg: _fieldBackground,
                            maxLines: 3,
                          ),
                          SizedBox(height: 18.v),
                          _PlanTierSection(
                            displayLabel: _planTierLabel(session),
                            isPro: _sessionIsPro(session),
                            fieldBg: _fieldBackground,
                            onUpgrade: _openUpgradePlan,
                          ),
                          SizedBox(height: 18.v),
                          _ChangePasswordRow(
                            fieldBg: _fieldBackground,
                            onTap: _openChangePassword,
                          ),
                          SizedBox(height: 28.v),
                          Text(
                            'lbl_account_actions'.tr,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 10.v),
                          _AccountActionRow(
                            fieldBg: _fieldBackground,
                            icon: Icons.logout,
                            title: 'lbl_log_out'.tr,
                            iconAndTextColor: Colors.white,
                            onTap: _logout,
                          ),
                          SizedBox(height: 12.v),
                          _AccountActionRow(
                            fieldBg: _fieldBackground,
                            icon: Icons.delete_forever_outlined,
                            title: 'lbl_delete_account'.tr,
                            iconAndTextColor: theme.colorScheme.error,
                            onTap: _confirmDeleteAccount,
                          ),
                          SizedBox(height: 32.v),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.h, 0, 24.h, 20.v),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54.v,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: onPrimary,
                          elevation: 2,
                          shadowColor: Colors.black45,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.h),
                          ),
                        ),
                        onPressed: (_isLoadingProfile || _isSaving)
                            ? null
                            : _onSave,
                        child: Text(
                          'lbl_save'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PlanTierSection extends StatelessWidget {
  const _PlanTierSection({
    required this.displayLabel,
    required this.isPro,
    required this.fieldBg,
    required this.onUpgrade,
  });

  final String displayLabel;
  final bool isPro;
  final Color fieldBg;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lbl_plan'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.v),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(
                isPro
                    ? Icons.workspace_premium_outlined
                    : Icons.card_giftcard_outlined,
                color: primary,
                size: 22.adaptSize,
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Text(
                  displayLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.v),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onUpgrade,
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withValues(alpha: 0.9)),
              padding: EdgeInsets.symmetric(vertical: 14.v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.h),
              ),
            ),
            child: Text(
              'lbl_upgrade_plan'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledProfileTextField extends StatelessWidget {
  const _LabeledProfileTextField({
    required this.label,
    required this.controller,
    required this.fieldBg,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final Color fieldBg;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.v),
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: readOnly ? Colors.white54 : Colors.white,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.h,
                vertical: maxLines > 1 ? 14.v : 16.v,
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
    required this.fieldBg,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final Color fieldBg;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.v),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.h),
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value != null && items.contains(value) ? value : null,
              hint: Text(
                'lbl_select_country_placeholder'.tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white38,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
              ),
              dropdownColor: fieldBg,
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
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
    required this.fieldBg,
    required this.icon,
    required this.title,
    required this.iconAndTextColor,
    required this.onTap,
  });

  final Color fieldBg;
  final IconData icon;
  final String title;
  final Color iconAndTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fieldBg,
      borderRadius: BorderRadius.circular(12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.h),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconAndTextColor, size: 22.adaptSize),
              SizedBox(width: 12.h),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: iconAndTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white38, size: 24.adaptSize),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangePasswordRow extends StatelessWidget {
  const _ChangePasswordRow({
    required this.fieldBg,
    required this.onTap,
  });

  final Color fieldBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lbl_security'.tr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.v),
        Material(
          color: fieldBg,
          borderRadius: BorderRadius.circular(12.h),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.h),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_reset_outlined, color: primary, size: 22.adaptSize),
                  SizedBox(width: 12.h),
                  Expanded(
                    child: Text(
                      'lbl_change_password'.tr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white38, size: 24.adaptSize),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
