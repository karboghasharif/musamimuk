import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../background_removal/background_removal_controller.dart';
import '../../background_removal/background_removal_loading_dialog.dart';
import '../../background_removal/background_removal_state.dart';
import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/save_raster_to_gallery.dart';
import '../../data/models/background_removal_api_models.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

/// Arguments when opening [EnhancedRemoveBackgroundScreen] from the editor.
class RemoveBackgroundScreenArgs {
  const RemoveBackgroundScreenArgs({
    this.initialImageBytes,
    this.autoProcess = false,
    this.applyToLayer = false,
  });

  final Uint8List? initialImageBytes;
  final bool autoProcess;
  final bool applyToLayer;
}

class EnhancedRemoveBackgroundScreen extends StatefulWidget {
  const EnhancedRemoveBackgroundScreen({super.key, this.args});

  final RemoveBackgroundScreenArgs? args;

  static Widget builder(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    return EnhancedRemoveBackgroundScreen(
      args: raw is RemoveBackgroundScreenArgs ? raw : null,
    );
  }

  @override
  State<EnhancedRemoveBackgroundScreen> createState() =>
      _EnhancedRemoveBackgroundScreenState();
}

class _EnhancedRemoveBackgroundScreenState
    extends State<EnhancedRemoveBackgroundScreen> {
  final BackgroundRemovalController _controller = BackgroundRemovalController();

  Uint8List? _originalImage;
  Uint8List? _processedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  bool get _fromEditor => widget.args?.applyToLayer == true;

  @override
  void initState() {
    super.initState();
    final bytes = widget.args?.initialImageBytes;
    if (bytes != null) {
      _originalImage = bytes;
    }
    if (widget.args?.autoProcess == true && bytes != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _removeBackground();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        appBar: CustomAppBar(
          leading: AppbarLeadingImage(
            imagePath: ImageConstant.imgArrowLeftPrimary,
          ),
          title: _fromEditor ? null : Text('msg_remove_background'.tr),
        ),
        body: Column(
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
                    if (!_fromEditor) ...[
                      _buildHeroSection(),
                      SizedBox(height: AppDs.space5.v),
                      _buildFeatureChips(),
                      SizedBox(height: AppDs.space5.v),
                    ],
                    _buildPreviewCard(),
                    if (_errorMessage != null) ...[
                      SizedBox(height: AppDs.space4.v),
                      _buildErrorBanner(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 88.adaptSize,
          height: 88.adaptSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary.withValues(alpha: 0.28),
                cs.primary.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
          ),
          child: Icon(
            Icons.auto_fix_high_rounded,
            size: 42.adaptSize,
            color: cs.primary,
          ),
        ),
        SizedBox(height: AppDs.space4.v),
        Text(
          'msg_remove_background'.tr,
          textAlign: TextAlign.center,
          style: AppTypography.heading(Theme.of(context)).copyWith(
            color: AppDs.textOnDarkPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: AppDs.space2.v),
        Text(
          'msg_bg_removal_standalone_subtitle'.tr,
          textAlign: TextAlign.center,
          style: AppTypography.secondary(Theme.of(context)).copyWith(
            color: AppDs.textOnDarkSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChips() {
    final cs = Theme.of(context).colorScheme;
    final labels = <String>[
      'msg_bg_removal_feature_ai'.tr,
      'msg_bg_removal_feature_png'.tr,
      'msg_bg_removal_feature_formats'.tr,
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppDs.space2.h,
      runSpacing: AppDs.space2.v,
      children: labels.map((label) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppDs.space3.h,
            vertical: AppDs.space2.v,
          ),
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusFull.adaptSize),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14.adaptSize, color: cs.primary),
              SizedBox(width: AppDs.space1.h),
              Text(
                label,
                style: AppTypography.caption(Theme.of(context)).copyWith(
                  color: AppDs.textOnDarkPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard() {
    if (_originalImage == null) {
      return _buildUploadZone();
    }

    return AppCard(
      elevated: true,
      padding: EdgeInsets.all(AppDs.space4.h),
      child: _buildComparisonSection(),
    );
  }

  Widget _buildUploadZone() {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : _selectImage,
        borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
        child: Ink(
          decoration: BoxDecoration(
            color: AppDs.surfaceElevated,
            borderRadius: BorderRadius.circular(AppDs.radiusLg.adaptSize),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDs.space5.h,
              vertical: AppDs.space8.v,
            ),
            child: Column(
              children: [
                Container(
                  width: 72.adaptSize,
                  height: 72.adaptSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 34.adaptSize,
                    color: cs.primary,
                  ),
                ),
                SizedBox(height: AppDs.space4.v),
                Text(
                  'msg_bg_removal_tap_upload'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.title(Theme.of(context)).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  'msg_bg_removal_tap_upload_hint'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary(Theme.of(context)).copyWith(
                    color: AppDs.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSection() {
    final panelHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImagePanel(
          label: 'lbl_original'.tr,
          height: panelHeight,
          child: _buildImageContent(_originalImage!),
        ),
        SizedBox(height: AppDs.space4.v),
        _buildImagePanel(
          label: 'lbl_processed'.tr,
          height: panelHeight,
          badge: _processedImage != null
              ? 'msg_bg_removal_ready_download'.tr
              : null,
          child: _buildProcessedContent(),
        ),
      ],
    );
  }

  Widget _buildImagePanel({
    required String label,
    required double height,
    required Widget child,
    String? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.accent(theme).copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDs.space2.h,
                  vertical: AppDs.space1.v,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppDs.radiusSm.adaptSize),
                ),
                child: Text(
                  badge,
                  style: AppTypography.caption(theme).copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: AppDs.space2.v),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ],
    );
  }

  Widget _buildImageContent(Uint8List bytes) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
    );
  }

  Widget _buildProcessedContent() {
    if (_isProcessing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _TransparencyCheckerboard()),
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 36.adaptSize,
                    height: 36.adaptSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: AppDs.space3.v),
                  Text(
                    'msg_removing_background'.tr,
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.textOnDarkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_processedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _TransparencyCheckerboard()),
          _buildImageContent(_processedImage!),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _TransparencyCheckerboard()),
        Center(
          child: Padding(
            padding: EdgeInsets.all(AppDs.space4.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers_clear_outlined,
                  size: 36.adaptSize,
                  color: AppDs.textOnDarkDisabled,
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  'msg_processed_preview_hint'.tr,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(AppDs.space4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          SizedBox(width: AppDs.space3.h),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.body(theme).copyWith(
                color: AppDs.textOnDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDs.space4.h,
        AppDs.space3.v,
        AppDs.space4.h,
        AppDs.space4.v,
      ),
      decoration: BoxDecoration(
        color: AppDs.surfaceElevated,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: _fromEditor ? _buildEditorActions() : _buildStandaloneActions(),
    );
  }

  Widget _buildStandaloneActions() {
    if (_originalImage == null) {
      return AppPrimaryButton(
        label: 'lbl_upload_image'.tr,
        onPressed: _isProcessing ? null : _selectImage,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_processedImage != null) ...[
          AppPrimaryButton(
            label: 'lbl_download'.tr,
            onPressed: _isProcessing ? null : _saveImage,
          ),
          SizedBox(height: AppDs.space3.v),
        ],
        AppPrimaryButton(
          label: _isProcessing
              ? 'msg_removing_background'.tr
              : 'msg_remove_background'.tr,
          onPressed: _isProcessing ? null : _removeBackground,
        ),
        SizedBox(height: AppDs.space2.v),
        TextButton.icon(
          onPressed: _isProcessing ? null : _selectImage,
          icon: Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary),
          label: Text(
            'msg_bg_removal_change_photo'.tr,
            style: AppTypography.body(theme).copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_processedImage != null) ...[
          AppPrimaryButton(
            label: 'lbl_apply'.tr,
            onPressed: _isProcessing ? null : _applyToLayer,
          ),
          SizedBox(height: AppDs.space3.v),
        ],
        AppSecondaryButton(
          label: _isProcessing ? 'msg_removing_background'.tr : 'lbl_retry'.tr,
          onPressed: _isProcessing || _originalImage == null
              ? null
              : _removeBackground,
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 95,
      );

      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _originalImage = bytes;
        _processedImage = null;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'msg_bg_removal_api_failure'.tr);
    }
  }

  String _localizedError(BackgroundRemovalState state) {
    switch (state.errorKind) {
      case BackgroundRemovalErrorKind.invalidFormat:
        return 'msg_bg_removal_invalid_format'.tr;
      case BackgroundRemovalErrorKind.fileTooLarge:
        return 'msg_bg_removal_file_too_large'.tr;
      case BackgroundRemovalErrorKind.timeout:
        return 'msg_bg_removal_timeout'.tr;
      case BackgroundRemovalErrorKind.network:
        return 'msg_bg_removal_network_error'.tr;
      case BackgroundRemovalErrorKind.apiFailure:
      case null:
        return 'msg_bg_removal_api_failure'.tr;
    }
  }

  Future<void> _removeBackground() async {
    final bytes = _originalImage;
    if (bytes == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _processedImage = null;
    });

    BackgroundRemovalLoadingDialog.show(
      context,
      previewBytes: bytes,
      controller: _controller,
    );
    await WidgetsBinding.instance.endOfFrame;

    Uint8List? resultBytes;
    try {
      resultBytes = await _controller.removeBackground(bytes);
    } finally {
      if (mounted) {
        BackgroundRemovalLoadingDialog.hide(context);
      }
    }
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      if (resultBytes != null) {
        _processedImage = resultBytes;
        _errorMessage = null;
        showAppToast(
          'msg_bg_removal_success'.tr,
          type: ToastificationType.success,
        );
      } else {
        _errorMessage = _localizedError(_controller.state);
        showAppToast(
          _errorMessage!,
          type: ToastificationType.error,
        );
      }
      _controller.reset();
    });
  }

  void _applyToLayer() {
    final bytes = _processedImage;
    if (bytes == null) return;
    Navigator.of(context).pop(bytes);
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;
    await saveRasterToGalleryAndOpen(
      context,
      bytes: _processedImage!,
      fileBaseName: 'background_removed',
    );
  }
}

class _TransparencyCheckerboard extends CustomPainter {
  const _TransparencyCheckerboard();

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 12.0;
    final light = Paint()..color = const Color(0xFF2A2A2A);
    final dark = Paint()..color = const Color(0xFF1A1A1A);
    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final isLight = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isLight ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
