import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

String printSar(num amount) => 'SAR ${amount.toStringAsFixed(2)}';

class PrintScaffold extends StatelessWidget {
  const PrintScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDs.surfaceBase,
      appBar: CustomAppBar(
        leading: AppbarLeadingImage(
          imagePath: ImageConstant.imgArrowLeftPrimary,
          onTap: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: AppbarTitle(text: title),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: bottom,
      floatingActionButton: floatingActionButton,
    );
  }
}

class PrintGoldButton extends StatelessWidget {
  const PrintGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppDs.printGold,
        foregroundColor: Colors.black,
        disabledBackgroundColor: AppDs.printGold.withValues(alpha: 0.4),
        minimumSize: Size(double.infinity, AppDs.buttonHeight.v),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
        ),
      ),
      child: loading
          ? SizedBox(
              width: 22.adaptSize,
              height: 22.adaptSize,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15.fSize,
              ),
            ),
    );
  }
}
