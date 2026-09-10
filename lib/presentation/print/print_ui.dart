import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../data/models/print_models.dart';
import '../../widgets/app_bar/appbar_leading_image.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/app_bar/custom_app_bar.dart';

String printSar(num amount) => 'SAR ${amount.toStringAsFixed(2)}';

String printLocalizedLabel(String? en, String? ar) {
  final code = AppLocalization.activeLanguageCode();
  if (code == 'ar' && (ar?.isNotEmpty ?? false)) return ar!;
  return en ?? '';
}

class PrintLevelBadge extends StatelessWidget {
  const PrintLevelBadge({super.key, this.label, this.labelAr});

  final String? label;
  final String? labelAr;

  @override
  Widget build(BuildContext context) {
    final text = printLocalizedLabel(label, labelAr);
    if (text.isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(text),
      backgroundColor: AppDs.printGold,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class PrintVerifiedReviewList extends StatelessWidget {
  const PrintVerifiedReviewList({super.key, required this.reviews});

  final List<PrintReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Text(
        'msg_print_no_reviews'.tr,
        style: const TextStyle(color: AppDs.textOnDarkSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: reviews
          .map(
            (review) => Padding(
              padding: EdgeInsets.only(bottom: 10.v),
              child: Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: AppDs.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.overall.toStringAsFixed(1)} ★ · ${'lbl_print_verified_review'.tr}',
                      style: const TextStyle(
                        color: AppDs.printGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 6.v),
                        child: Text(
                          review.comment!,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

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
