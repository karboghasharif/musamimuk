import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/services/background_removal_service.dart';
import '../../core/services/remove_bg_service.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';

class EnhancedRemoveBackgroundScreen extends StatefulWidget {
  const EnhancedRemoveBackgroundScreen({super.key});

  static Widget builder(BuildContext context) {
    return const EnhancedRemoveBackgroundScreen();
  }

  @override
  State<EnhancedRemoveBackgroundScreen> createState() =>
      _EnhancedRemoveBackgroundScreenState();
}

class _EnhancedRemoveBackgroundScreenState
    extends State<EnhancedRemoveBackgroundScreen> {
  Uint8List? _originalImage;
  Uint8List? _processedImage;
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _errorMessage;
  // Using BackgroundRemovalService with multiple fallback options

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "AI Background Removal",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 24.v),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 20.v),
                _buildImagePreview(),
                SizedBox(height: 20.v),
                _buildControls(),
                SizedBox(height: 16.v),
                _buildProgressIndicator(),
                SizedBox(height: 16.v),
                _buildResults(),
              ],
            ),
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
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgReply,
                height: 19.adaptSize,
                width: 19.adaptSize,
              ),
              Text("lbl_save".tr, style: CustomTextStyles.bodySmall10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        CustomImageView(
          imagePath: ImageConstant.imgGalleryRemoveSvgrepoCom,
          height: 72.adaptSize,
          width: 72.adaptSize,
        ),
        SizedBox(height: 20.v),
        Text(
          "AI Background Removal",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10.v),
        Text(
          "Remove background from your images using AI",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.3, // 30% of screen height
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child:
          _originalImage != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(12.h),
                child: Image.memory(
                  _originalImage!,
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: double.maxFinite,
                ),
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48.adaptSize,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  SizedBox(height: 16.v),
                  Text(
                    "No image selected",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 400) {
          // Stack vertically on smaller screens
          return Column(
            children: [
              CustomElevatedButton(
                height: 50.v,
                width: double.maxFinite,
                text: "Select Image",
                buttonStyle: CustomButtonStyles.fillPrimary,
                buttonTextStyle: CustomTextStyles.titleMediumBold,
                onPressed: _isProcessing ? null : _selectImage,
              ),
              if (_originalImage != null) ...[
                SizedBox(height: 12.v),
                CustomElevatedButton(
                  height: 50.v,
                  width: double.maxFinite,
                  text: _isProcessing ? "Processing..." : "Remove Background",
                  buttonStyle: CustomButtonStyles.fillYellow,
                  buttonTextStyle: CustomTextStyles.titleMediumBluegray90004,
                  onPressed: _isProcessing ? null : _removeBackground,
                ),
              ],
            ],
          );
        } else {
          // Row layout for larger screens
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomElevatedButton(
                height: 50.v,
                width: 120.h,
                text: "Select Image",
                buttonStyle: CustomButtonStyles.fillPrimary,
                buttonTextStyle: CustomTextStyles.titleMediumBold,
                onPressed: _isProcessing ? null : _selectImage,
              ),
              if (_originalImage != null)
                CustomElevatedButton(
                  height: 50.v,
                  width: 120.h,
                  text: _isProcessing ? "Processing..." : "Remove Background",
                  buttonStyle: CustomButtonStyles.fillYellow,
                  buttonTextStyle: CustomTextStyles.titleMediumBluegray90004,
                  onPressed: _isProcessing ? null : _removeBackground,
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildProgressIndicator() {
    if (!_isProcessing && _progress == 0.0) return const SizedBox.shrink();

    return Column(
      children: [
        LinearProgressIndicator(
          value: _progress,
          backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
        SizedBox(height: 8.v),
        Text(
          "Processing... ${(_progress * 100).toInt()}%",
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_processedImage == null && _errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: EdgeInsets.all(16.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_processedImage != null) ...[
          SizedBox(height: 20.v),
          Text(
            "Result",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.v),
          Container(
            height:
                MediaQuery.of(context).size.height *
                0.25, // 25% of screen height
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.h),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.h),
              child: Image.memory(
                _processedImage!,
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: double.maxFinite,
              ),
            ),
          ),
          SizedBox(height: 20.v),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack vertically on smaller screens
                return Column(
                  children: [
                    CustomElevatedButton(
                      height: 50.v,
                      width: double.maxFinite,
                      text: "Save Image",
                      buttonStyle: CustomButtonStyles.fillPrimary,
                      buttonTextStyle: CustomTextStyles.titleMediumBold,
                      onPressed: _saveImage,
                    ),
                    SizedBox(height: 12.v),
                    CustomElevatedButton(
                      height: 50.v,
                      width: double.maxFinite,
                      text: "Try Again",
                      buttonStyle: CustomButtonStyles.outlineBlackTL24,
                      buttonTextStyle: CustomTextStyles.titleMediumBold,
                      onPressed: _reset,
                    ),
                  ],
                );
              } else {
                // Row layout for larger screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomElevatedButton(
                      height: 50.v,
                      width: 120.h,
                      text: "Save Image",
                      buttonStyle: CustomButtonStyles.fillPrimary,
                      buttonTextStyle: CustomTextStyles.titleMediumBold,
                      onPressed: _saveImage,
                    ),
                    CustomElevatedButton(
                      height: 50.v,
                      width: 120.h,
                      text: "Try Again",
                      buttonStyle: CustomButtonStyles.outlineBlackTL24,
                      buttonTextStyle: CustomTextStyles.titleMediumBold,
                      onPressed: _reset,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _originalImage = bytes;
          _processedImage = null;
          _errorMessage = null;
          _progress = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _removeBackground() async {
    if (_originalImage == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _errorMessage = null;
      _processedImage = null;
    });

    try {
      final result = await BackgroundRemovalService.removeBackground(
        _originalImage!,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      setState(() {
        _isProcessing = false;
        if (result != null) {
          _processedImage = result;
          _errorMessage = null;
        } else {
          _errorMessage = 'Background removal failed. Please try again.';
          _processedImage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error processing image: $e';
        _processedImage = null;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    try {
      final String? filePath = await RemoveBgService().saveImageToDevice(
        _processedImage!,
        'background_removed_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (filePath != null) {
        showAppToast(
          'Image saved to: $filePath',
          type: ToastificationType.success,
        );
      } else {
        showAppToast(
          'Failed to save image',
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      showAppToast(
        'Error saving image: $e',
        type: ToastificationType.error,
      );
    }
  }

  void _reset() {
    setState(() {
      _originalImage = null;
      _processedImage = null;
      _errorMessage = null;
      _progress = 0.0;
      _isProcessing = false;
    });
  }
}
