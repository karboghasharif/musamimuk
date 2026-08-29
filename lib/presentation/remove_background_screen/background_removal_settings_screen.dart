import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/services/hugging_face_service.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';

class BackgroundRemovalSettingsScreen extends StatefulWidget {
  const BackgroundRemovalSettingsScreen({super.key});

  static Widget builder(BuildContext context) {
    return const BackgroundRemovalSettingsScreen();
  }

  @override
  State<BackgroundRemovalSettingsScreen> createState() =>
      _BackgroundRemovalSettingsScreenState();
}

class _BackgroundRemovalSettingsScreenState
    extends State<BackgroundRemovalSettingsScreen> {
  final TextEditingController _modelController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isStatusError = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hf_api_key');
    if (!mounted) return;
    setState(() {
      _modelController.text = prefs.getString('hf_model') ?? 'briaai/RMBG-1.4';
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hf_model', _modelController.text.trim());

      setState(() {
        _statusMessage = 'Settings saved successfully!';
        _isStatusError = false;
      });

      showAppToast(_statusMessage!, type: ToastificationType.success);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving settings: $e';
        _isStatusError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 24.v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 30.v),
              _buildSecurityNotice(),
              SizedBox(height: 20.v),
              _buildModelSection(),
              SizedBox(height: 20.v),
              _buildStatusSection(),
              SizedBox(height: 30.v),
              _buildSaveButton(),
              SizedBox(height: 20.v),
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 3.v,
              width: 30.h,
              margin: EdgeInsets.only(top: 11.v, bottom: 5.v),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1.h),
              ),
            ),
            Container(
              height: 3.v,
              width: 20.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1.h),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        "Background Removal Settings",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Configure AI Background Removal",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.v),
        Text(
          "Background removal credentials are managed securely by the Musamimuk backend",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.all(16.adaptSize),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.adaptSize),
      ),
      child: Text(
        "API credentials are never stored on this device. Requests use your authenticated Musamimuk session.",
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildModelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Background Removal Model",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.v),
        Text(
          "Choose the AI model for background removal",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        SizedBox(height: 12.v),
        CustomTextFormField(
          controller: _modelController,
          hintText: "briaai/RMBG-1.4",
          textInputType: TextInputType.text,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.h,
            vertical: 14.v,
          ),
        ),
        SizedBox(height: 8.v),
        _buildModelOptions(),
      ],
    );
  }

  Widget _buildModelOptions() {
    final models = HuggingFaceService.getAvailableModels();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Models:",
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.v),
        ...models.map(
          (model) => Padding(
            padding: EdgeInsets.only(bottom: 4.v),
            child: GestureDetector(
              onTap: () {
                _modelController.text = model;
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.v),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6.h),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 16.adaptSize,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(width: 8.h),
                    Expanded(
                      child: Text(model, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: _isStatusError
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Row(
        children: [
          Icon(
            _isStatusError ? Icons.error_outline : Icons.check_circle_outline,
            color: _isStatusError
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Text(
              _statusMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _isStatusError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.maxFinite,
      child: CustomElevatedButton(
        height: 50.v,
        text: _isLoading ? "Saving..." : "Save Settings",
        buttonStyle: CustomButtonStyles.fillPrimary,
        buttonTextStyle: CustomTextStyles.titleMediumBold,
        onPressed: _isLoading ? null : _saveSettings,
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20.adaptSize,
              ),
              SizedBox(width: 8.h),
              Text(
                "How to get started:",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          _buildInfoItem("1. Visit https://huggingface.co/settings/tokens"),
          _buildInfoItem("2. Create a new token with 'Read' permissions"),
          _buildInfoItem("3. Copy the token and paste it above"),
          _buildInfoItem("4. Choose your preferred background removal model"),
          _buildInfoItem("5. Save settings and start removing backgrounds!"),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.v),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
