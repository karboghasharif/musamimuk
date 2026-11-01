import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';

/// Atelier KYC field — [AppTextField] for single-line, multiline when [maxLines] > 1.
class PrintKycTextField extends StatelessWidget {
  const PrintKycTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.textInputAction,
    this.prefixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space3.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (maxLines > 1) ...[
            AppText(label, variant: AppTextVariant.caption),
            SizedBox(height: AppDs.space2.v),
            TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onChanged: onChanged,
              validator: validator,
              style: AppTypography.body(theme),
              decoration: InputDecoration(
                hintText: label,
                contentPadding: EdgeInsets.all(AppDs.space3.h),
              ),
            ),
          ] else
            AppTextField(
              controller: controller,
              label: label,
              hintText: label,
              textInputType: keyboardType ?? TextInputType.text,
              textInputAction: textInputAction ?? TextInputAction.next,
              prefixIcon: prefixIcon,
              onChanged: onChanged,
              validator: validator,
            ),
          if (helper != null && helper!.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: AppDs.space1.v),
              child: AppText(
                helper!,
                variant: AppTextVariant.caption,
                color: AppDs.textOnDarkSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal step rail: done / current / upcoming — not a thin progress bar alone.
class PrintKycStepHeader extends StatelessWidget {
  const PrintKycStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.subtitle,
    this.stepLabels,
  });

  final int step;
  final int total;
  final String title;
  final String? subtitle;
  final List<String>? stepLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space5.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.symmetric(horizontal: 2.h),
                      color: i <= step
                          ? AppDs.atelierBrass
                          : AppDs.atelierHairline(0.16),
                    ),
                  ),
                _StepDot(
                  index: i,
                  state: i < step
                      ? _StepDotState.done
                      : i == step
                          ? _StepDotState.current
                          : _StepDotState.upcoming,
                ),
              ],
            ],
          ),
          if (stepLabels != null && stepLabels!.length == total) ...[
            SizedBox(height: AppDs.space2.v),
            Row(
              children: [
                for (var i = 0; i < total; i++)
                  Expanded(
                    child: Text(
                      stepLabels![i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(theme).copyWith(
                        color: (i + 1) == step
                            ? AppDs.atelierBrass
                            : AppDs.textOnDarkDisabled,
                        fontWeight: (i + 1) == step
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 10.fSize,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          SizedBox(height: AppDs.space4.v),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3.h,
                height: 44.v,
                margin: EdgeInsetsDirectional.only(end: AppDs.space3.h),
                decoration: BoxDecoration(
                  color: AppDs.atelierBrass,
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lbl_print_step_of'.tr
                          .replaceAll('{n}', '$step')
                          .replaceAll('{m}', '$total'),
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.atelierBrass,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppDs.space1.v),
                    Text(
                      title,
                      style: AppDs.sheetTitle(
                        theme,
                        color: AppDs.textOnDarkPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      SizedBox(height: AppDs.space1.v),
                      Text(
                        subtitle!,
                        style: AppTypography.secondary(theme).copyWith(
                          color: AppDs.textOnDarkSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _StepDotState { done, current, upcoming }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.state});

  final int index;
  final _StepDotState state;

  @override
  Widget build(BuildContext context) {
    final size = 28.adaptSize;
    switch (state) {
      case _StepDotState.done:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppDs.atelierBrass,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16.adaptSize,
            color: AppDs.onAccent,
          ),
        );
      case _StepDotState.current:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppDs.accentYellow,
            shape: BoxShape.circle,
            border: Border.all(color: AppDs.accentYellow, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              color: AppDs.onAccent,
              fontWeight: FontWeight.w800,
              fontSize: 12.fSize,
            ),
          ),
        );
      case _StepDotState.upcoming:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: AppDs.atelierHairline(0.22)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              color: AppDs.textOnDarkSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12.fSize,
            ),
          ),
        );
    }
  }
}

/// Sticky bottom Back / Continue — keeps CTAs clear while scrolling forms.
class PrintKycNavBar extends StatelessWidget {
  const PrintKycNavBar({
    super.key,
    required this.canGoBack,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
    this.loading = false,
  });

  final bool canGoBack;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppDs.space4.h,
          AppDs.space3.v,
          AppDs.space4.h,
          AppDs.space3.v,
        ),
        decoration: BoxDecoration(
          color: AppDs.atelierInk,
          border: Border(
            top: BorderSide(color: AppDs.atelierHairline(0.12)),
          ),
        ),
        child: Row(
          children: [
            if (canGoBack) ...[
              Expanded(
                child: AppSecondaryButton(
                  label: 'lbl_print_back'.tr,
                  onPressed: loading ? null : onBack,
                  expandWidth: true,
                ),
              ),
              SizedBox(width: AppDs.space3.h),
            ],
            Expanded(
              flex: canGoBack ? 2 : 1,
              child: AppPrimaryButton(
                label: primaryLabel,
                isLoading: loading,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large tap-to-upload document zone with clear empty / filled / required states.
class PrintKycDocSlot extends StatelessWidget {
  const PrintKycDocSlot({
    super.key,
    required this.kind,
    required this.required,
    required this.picked,
    required this.onPick,
    this.onClear,
  });

  final String kind;
  final bool required;
  final PrintPickedDoc? picked;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = PrintKyc.labelKey(kind).tr;
    final filled = picked != null;
    final borderColor = filled
        ? AppDs.atelierBrass.withValues(alpha: 0.55)
        : required
            ? AppDs.accentYellow.withValues(alpha: 0.35)
            : AppDs.atelierHairline(0.16);
    final bg = filled
        ? AppDs.atelierBrass.withValues(alpha: 0.08)
        : AppDs.surfaceRaised;

    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space3.v),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppDs.radiusLg),
          child: CustomPaint(
            painter: filled
                ? null
                : _DashedRRectPainter(
                    color: borderColor,
                    radius: AppDs.radiusLg,
                  ),
            child: Container(
              constraints: BoxConstraints(minHeight: 88.v),
              padding: EdgeInsets.all(AppDs.space4.h),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppDs.radiusLg),
                border: filled
                    ? Border.all(color: borderColor, width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: filled
                        ? () => showPrintKycDocPreview(context, picked!)
                        : null,
                    child: filled && picked!.isImage
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppDs.radiusMd),
                            child: Image.file(
                              File(picked!.path),
                              width: 64.adaptSize,
                              height: 64.adaptSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const _DocThumbPlaceholder(
                                icon: Icons.broken_image_outlined,
                              ),
                            ),
                          )
                        : Container(
                            width: 64.adaptSize,
                            height: 64.adaptSize,
                            decoration: BoxDecoration(
                              color: filled
                                  ? AppDs.atelierBrass.withValues(alpha: 0.2)
                                  : AppDs.atelierHairline(0.08),
                              borderRadius:
                                  BorderRadius.circular(AppDs.radiusMd),
                            ),
                            child: Icon(
                              filled
                                  ? (picked!.isPdf
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.description_outlined)
                                  : Icons.upload_file_outlined,
                              color: filled
                                  ? AppDs.atelierBrass
                                  : AppDs.textOnDarkSecondary,
                              size: AppDs.iconMd.adaptSize,
                            ),
                          ),
                  ),
                  SizedBox(width: AppDs.space3.h),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: AppTypography.body(theme).copyWith(
                                  color: AppDs.textOnDarkPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppDs.fontSecondary.clamp(14.0, 16.0),
                                ),
                              ),
                            ),
                            _DocBadge(required: required, filled: filled),
                          ],
                        ),
                        SizedBox(height: AppDs.space1.v),
                        if (filled)
                          Text(
                            '${picked!.name} · ${(picked!.bytes / 1024).toStringAsFixed(0)} KB',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(theme).copyWith(
                              color: AppDs.atelierBrass,
                            ),
                          )
                        else
                          Text(
                            'lbl_print_tap_to_upload'.tr,
                            style: AppTypography.caption(theme).copyWith(
                              color: AppDs.textOnDarkSecondary,
                            ),
                          ),
                        if (!filled)
                          Padding(
                            padding: EdgeInsets.only(top: 2.v),
                            child: Text(
                              'msg_print_doc_limits'.tr,
                              style: AppTypography.caption(theme).copyWith(
                                color: AppDs.textOnDarkDisabled,
                                fontSize: 11.fSize,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (filled && onClear != null)
                    IconButton(
                      onPressed: onClear,
                      tooltip: 'lbl_print_remove_file'.tr,
                      constraints: BoxConstraints(
                        minWidth: AppDs.minTap,
                        minHeight: AppDs.minTap,
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppDs.textOnDarkSecondary,
                        size: AppDs.iconMd.adaptSize,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppDs.textOnDarkDisabled,
                      size: AppDs.iconMd.adaptSize,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocBadge extends StatelessWidget {
  const _DocBadge({required this.required, required this.filled});

  final bool required;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = filled
        ? 'lbl_print_doc_attached'.tr
        : required
            ? 'lbl_print_required_badge'.tr
            : 'lbl_print_optional_badge'.tr;
    final color = filled
        ? AppDs.atelierBrass
        : required
            ? AppDs.accentYellow
            : AppDs.textOnDarkSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space2.h,
        vertical: 2.v,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
      ),
      child: Text(
        text,
        style: AppTypography.caption(theme).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10.fSize,
        ),
      ),
    );
  }
}

class _DocThumbPlaceholder extends StatelessWidget {
  const _DocThumbPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.adaptSize,
      height: 64.adaptSize,
      color: AppDs.surfaceRaised,
      alignment: Alignment.center,
      child: Icon(icon, color: AppDs.atelierBrass, size: AppDs.iconMd.adaptSize),
    );
  }
}

void showPrintKycDocPreview(BuildContext context, PrintPickedDoc doc) {
  final title = PrintKyc.labelKey(doc.kind).tr;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppDs.atelierInk,
        insetPadding: EdgeInsets.all(AppDs.space4.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480.h,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDs.space4.h,
                  AppDs.space3.v,
                  AppDs.space2.h,
                  AppDs.space2.v,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body(Theme.of(ctx)).copyWith(
                          color: AppDs.textOnDarkPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDs.space4.h,
                    0,
                    AppDs.space4.h,
                    AppDs.space4.v,
                  ),
                  child: doc.isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDs.radiusMd),
                          child: InteractiveViewer(
                            child: Image.file(
                              File(doc.path),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(AppDs.space6.h),
                          decoration: BoxDecoration(
                            color: AppDs.surfaceRaised,
                            borderRadius: BorderRadius.circular(AppDs.radiusMd),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doc.isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.description_outlined,
                                color: AppDs.atelierBrass,
                                size: 56.adaptSize,
                              ),
                              SizedBox(height: AppDs.space3.v),
                              Text(
                                doc.name,
                                textAlign: TextAlign.center,
                                style: AppTypography.body(Theme.of(ctx)).copyWith(
                                  color: AppDs.textOnDarkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppDs.space1.v),
                              Text(
                                '${(doc.bytes / 1024).toStringAsFixed(0)} KB'
                                '${doc.extension.isEmpty ? '' : ' · ${doc.extension.toUpperCase()}'}',
                                style: AppTypography.caption(Theme.of(ctx)),
                              ),
                              SizedBox(height: AppDs.space2.v),
                              AppText(
                                'msg_print_doc_preview_file_only'.tr,
                                variant: AppTextVariant.caption,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Review-step grid of document thumbnails (tap to enlarge).
class PrintKycDocPreviewGrid extends StatelessWidget {
  const PrintKycDocPreviewGrid({
    super.key,
    required this.docs,
    this.emptyLabel,
  });

  final List<PrintPickedDoc> docs;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDs.space2.v),
        child: AppText(
          emptyLabel ?? 'msg_print_no_documents'.tr,
          variant: AppTextVariant.secondary,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileW = (width - AppDs.space2.h) / 2;
        return Wrap(
          spacing: AppDs.space2.h,
          runSpacing: AppDs.space2.v,
          children: docs.map((doc) {
            return SizedBox(
              width: tileW,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => showPrintKycDocPreview(context, doc),
                  borderRadius: BorderRadius.circular(AppDs.radiusMd),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppDs.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      border: Border.all(color: AppDs.atelierHairline(0.12)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: doc.isImage
                              ? Image.file(
                                  File(doc.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      ColoredBox(
                                    color: AppDs.atelierHairline(0.06),
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppDs.textOnDarkSecondary,
                                      size: AppDs.iconMd.adaptSize,
                                    ),
                                  ),
                                )
                              : ColoredBox(
                                  color: AppDs.atelierBrass.withValues(alpha: 0.1),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        doc.isPdf
                                            ? Icons.picture_as_pdf_outlined
                                            : Icons.description_outlined,
                                        color: AppDs.atelierBrass,
                                        size: 36.adaptSize,
                                      ),
                                      SizedBox(height: AppDs.space1.v),
                                      Text(
                                        doc.extension.isEmpty
                                            ? 'FILE'
                                            : doc.extension.toUpperCase(),
                                        style: AppTypography.caption(
                                          Theme.of(context),
                                        ).copyWith(
                                          color: AppDs.atelierBrass,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(AppDs.space2.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                PrintKyc.labelKey(doc.kind).tr,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  Theme.of(context),
                                ).copyWith(
                                  color: AppDs.textOnDarkPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2.v),
                              Text(
                                '${(doc.bytes / 1024).toStringAsFixed(0)} KB · ${'lbl_print_tap_to_preview'.tr}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  Theme.of(context),
                                ).copyWith(
                                  color: AppDs.textOnDarkSecondary,
                                  fontSize: 10.fSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Required + optional document lists with progress chip.
class PrintKycDocSection extends StatelessWidget {
  const PrintKycDocSection({
    super.key,
    required this.requiredKinds,
    required this.optionalKinds,
    required this.docs,
    required this.onPick,
    required this.onClear,
  });

  final List<String> requiredKinds;
  final List<String> optionalKinds;
  final Map<String, PrintPickedDoc?> docs;
  final Future<void> Function(String kind) onPick;
  final void Function(String kind) onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attached =
        requiredKinds.where((k) => docs[k] != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(AppDs.space3.h),
          margin: EdgeInsets.only(bottom: AppDs.space4.v),
          decoration: BoxDecoration(
            color: AppDs.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDs.radiusMd),
            border: Border.all(color: AppDs.atelierHairline(0.12)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: AppDs.atelierBrass,
                size: AppDs.iconMd.adaptSize,
              ),
              SizedBox(width: AppDs.space2.h),
              Expanded(
                child: Text(
                  'lbl_print_docs_progress'.tr
                      .replaceAll('{n}', '$attached')
                      .replaceAll('{m}', '${requiredKinds.length}'),
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppText(
          'lbl_print_docs_required_section'.tr,
          variant: AppTextVariant.caption,
        ),
        SizedBox(height: AppDs.space2.v),
        ...requiredKinds.map(
          (kind) => PrintKycDocSlot(
            kind: kind,
            required: true,
            picked: docs[kind],
            onPick: () => onPick(kind),
            onClear: () => onClear(kind),
          ),
        ),
        if (optionalKinds.isNotEmpty) ...[
          SizedBox(height: AppDs.space2.v),
          AppText(
            'lbl_print_docs_optional_section'.tr,
            variant: AppTextVariant.caption,
          ),
          SizedBox(height: AppDs.space2.v),
          ...optionalKinds.map(
            (kind) => PrintKycDocSlot(
              kind: kind,
              required: false,
              picked: docs[kind],
              onPick: () => onPick(kind),
              onClear: () => onClear(kind),
            ),
          ),
        ],
      ],
    );
  }
}

/// Verification stamp plate for pending / needs-info / suspended shop & rider.
class PrintKycStatusBanner extends StatelessWidget {
  const PrintKycStatusBanner({
    super.key,
    required this.status,
    this.reviewNote,
    this.onFixDocs,
    this.onEdit,
  });

  final String status;
  final String? reviewNote;
  final VoidCallback? onFixDocs;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color color;
    final IconData icon;
    final String headline;
    final String body;
    switch (status) {
      case 'needs_info':
        color = const Color(0xFFE8A54B);
        icon = Icons.mark_email_unread_outlined;
        headline = 'lbl_print_status_needs_info'.tr;
        body = 'msg_print_needs_info'.tr;
      case 'pending':
        color = AppDs.atelierBrass;
        icon = Icons.hourglass_top_rounded;
        headline = 'lbl_print_status_pending'.tr;
        body = 'msg_print_awaiting_review'.tr;
      case 'suspended':
        color = theme.colorScheme.error;
        icon = Icons.block_rounded;
        headline = 'lbl_print_status_suspended'.tr;
        body = reviewNote?.trim().isNotEmpty == true
            ? reviewNote!.trim()
            : 'lbl_print_status_suspended'.tr;
      default:
        color = const Color(0xFF7DCEA0);
        icon = Icons.verified_rounded;
        headline = 'lbl_print_status_$status'.tr;
        body = reviewNote?.trim().isNotEmpty == true
            ? reviewNote!.trim()
            : headline;
    }
    final note = (status == 'suspended')
        ? null
        : (reviewNote != null && reviewNote!.trim().isNotEmpty
            ? reviewNote!.trim()
            : null);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppDs.space5.v),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDs.space4.h,
              AppDs.space5.v,
              AppDs.space4.h,
              AppDs.space4.v,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.16),
                  color.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDs.radiusLg - 1),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 72.adaptSize,
                  height: 72.adaptSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDs.atelierInk.withValues(alpha: 0.55),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 32.adaptSize),
                ),
                SizedBox(height: AppDs.space3.v),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: AppDs.sheetTitle(theme, color: color),
                ),
                SizedBox(height: AppDs.space2.v),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: AppTypography.secondary(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    height: 1.45,
                  ),
                ),
                if (note != null) ...[
                  SizedBox(height: AppDs.space3.v),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppDs.space3.h),
                    decoration: BoxDecoration(
                      color: AppDs.atelierInk.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      border: Border.all(color: AppDs.atelierHairline(0.1)),
                    ),
                    child: Text(
                      note,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onFixDocs != null || onEdit != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDs.space4.h,
                AppDs.space1.v,
                AppDs.space4.h,
                AppDs.space4.v,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onFixDocs != null)
                    AppPrimaryButton(
                      label: 'lbl_print_upload_docs'.tr,
                      onPressed: onFixDocs,
                    ),
                  if (onFixDocs != null && onEdit != null)
                    SizedBox(height: AppDs.space2.v),
                  if (onEdit != null)
                    AppSecondaryButton(
                      label: 'lbl_print_edit_profile'.tr,
                      onPressed: onEdit,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Submitted KYC documents as a preview gallery (tap tile to enlarge / open).
class PrintDocumentList extends StatelessWidget {
  const PrintDocumentList({super.key, required this.documents});

  final List<PrintDocument> documents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (documents.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppDs.space4.h),
        decoration: BoxDecoration(
          color: AppDs.surfaceRaised,
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          border: Border.all(color: AppDs.atelierHairline(0.12)),
        ),
        child: AppText(
          'msg_print_no_documents'.tr,
          variant: AppTextVariant.secondary,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppDs.space3.v),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'lbl_print_documents'.tr,
                  style: AppDs.sheetTitle(
                    theme,
                    color: AppDs.textOnDarkPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDs.space2.h,
                  vertical: 4.v,
                ),
                decoration: BoxDecoration(
                  color: AppDs.atelierBrass.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                ),
                child: Text(
                  'lbl_print_docs_on_file'.tr.replaceAll(
                    '{n}',
                    '${documents.length}',
                  ),
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.atelierBrass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileW = (constraints.maxWidth - AppDs.space2.h) / 2;
            return Wrap(
              spacing: AppDs.space2.h,
              runSpacing: AppDs.space2.v,
              children: documents.map((doc) {
                final statusColor = switch (doc.status) {
                  'accepted' => const Color(0xFF7DCEA0),
                  'rejected' => theme.colorScheme.error,
                  _ => AppDs.atelierBrass,
                };
                return SizedBox(
                  width: tileW,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showPrintDocumentPreview(context, doc),
                      borderRadius: BorderRadius.circular(AppDs.radiusMd),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppDs.surfaceRaised,
                          borderRadius: BorderRadius.circular(AppDs.radiusMd),
                          border: Border.all(
                            color: AppDs.atelierHairline(0.12),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: _PrintDocumentThumb(doc: doc),
                            ),
                            Padding(
                              padding: EdgeInsets.all(AppDs.space2.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    PrintKyc.labelKey(doc.kind).tr,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(theme)
                                        .copyWith(
                                      color: AppDs.textOnDarkPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2.v),
                                  Text(
                                    'lbl_print_doc_status_${doc.status}'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(theme)
                                        .copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.fSize,
                                    ),
                                  ),
                                  SizedBox(height: 2.v),
                                  Text(
                                    'lbl_print_tap_to_preview'.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(theme)
                                        .copyWith(
                                      color: AppDs.textOnDarkDisabled,
                                      fontSize: 10.fSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PrintDocumentThumb extends StatelessWidget {
  const _PrintDocumentThumb({required this.doc});

  final PrintDocument doc;

  @override
  Widget build(BuildContext context) {
    final url = doc.fileUrl?.trim();
    if (doc.isImage && url != null && url.isNotEmpty) {
      return CustomImageView(
        imagePath: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return ColoredBox(
      color: AppDs.atelierBrass.withValues(alpha: 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            doc.isPdf
                ? Icons.picture_as_pdf_outlined
                : Icons.description_outlined,
            color: AppDs.atelierBrass,
            size: 36.adaptSize,
          ),
          SizedBox(height: AppDs.space1.v),
          Text(
            doc.extension.isEmpty ? 'FILE' : doc.extension.toUpperCase(),
            style: AppTypography.caption(Theme.of(context)).copyWith(
              color: AppDs.atelierBrass,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showPrintDocumentPreview(
  BuildContext context,
  PrintDocument doc,
) async {
  final title = PrintKyc.labelKey(doc.kind).tr;
  final url = doc.fileUrl?.trim();
  final theme = Theme.of(context);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppDs.atelierInk,
        insetPadding: EdgeInsets.all(AppDs.space4.h),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480.h,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDs.space4.h,
                  AppDs.space3.v,
                  AppDs.space2.h,
                  AppDs.space2.v,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.body(theme).copyWith(
                          color: AppDs.textOnDarkPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDs.space4.h,
                    0,
                    AppDs.space4.h,
                    AppDs.space4.v,
                  ),
                  child: doc.isImage && url != null && url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDs.radiusMd),
                          child: InteractiveViewer(
                            child: CustomImageView(
                              imagePath: url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.all(AppDs.space6.h),
                          decoration: BoxDecoration(
                            color: AppDs.surfaceRaised,
                            borderRadius:
                                BorderRadius.circular(AppDs.radiusMd),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                doc.isPdf
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.description_outlined,
                                color: AppDs.atelierBrass,
                                size: 56.adaptSize,
                              ),
                              SizedBox(height: AppDs.space3.v),
                              Text(
                                'lbl_print_doc_status_${doc.status}'.tr,
                                style: AppTypography.body(theme).copyWith(
                                  color: AppDs.textOnDarkPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: AppDs.space1.v),
                              AppText(
                                'msg_print_doc_preview_external'.tr,
                                variant: AppTextVariant.caption,
                                textAlign: TextAlign.center,
                              ),
                              if (url != null && url.isNotEmpty) ...[
                                SizedBox(height: AppDs.space4.v),
                                AppPrimaryButton(
                                  label: 'lbl_print_open_document'.tr,
                                  onPressed: () async {
                                    final uri = Uri.tryParse(url);
                                    if (uri == null) {
                                      showAppToast(
                                        'msg_print_doc_open_failed'.tr,
                                        type: ToastificationType.error,
                                      );
                                      return;
                                    }
                                    final ok = await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    if (!ok && ctx.mounted) {
                                      showAppToast(
                                        'msg_print_doc_open_failed'.tr,
                                        type: ToastificationType.error,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Review summary row used on submit step + profile panels.
class PrintKycFactRow extends StatelessWidget {
  const PrintKycFactRow(
    this.label,
    this.value, {
    super.key,
    this.stacked = false,
  });

  final String label;
  final String value;

  /// Stack label above value for long content (IBAN, address).
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value.trim().isEmpty ? '—' : value.trim();
    final labelStyle = AppTypography.caption(theme).copyWith(
      color: AppDs.textOnDarkSecondary,
    );
    final valueStyle = AppTypography.body(theme).copyWith(
      color: AppDs.textOnDarkPrimary,
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: AppDs.space2.v),
      padding: EdgeInsets.symmetric(
        horizontal: AppDs.space3.h,
        vertical: AppDs.space3.v,
      ),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierHairline(0.1)),
      ),
      child: stacked || display.length > 28
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                SizedBox(height: AppDs.space1.v),
                Text(display, style: valueStyle),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: Text(label, style: labelStyle)),
                SizedBox(width: AppDs.space2.h),
                Expanded(
                  flex: 3,
                  child: Text(
                    display,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Chip strip for services / days / docs on the review step.
class PrintKycReviewChips extends StatelessWidget {
  const PrintKycReviewChips({
    super.key,
    required this.items,
    this.emptyLabel,
  });

  final List<String> items;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: AppDs.space2.v),
        child: AppText(
          emptyLabel ?? '—',
          variant: AppTextVariant.secondary,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: AppDs.space2.v),
      child: Wrap(
        spacing: AppDs.space2.h,
        runSpacing: AppDs.space2.v,
        children: items
            .map(
              (item) => Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDs.space3.h,
                  vertical: AppDs.space2.v,
                ),
                decoration: BoxDecoration(
                  color: AppDs.accentYellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDs.radiusFull),
                  border: Border.all(
                    color: AppDs.accentYellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  item,
                  style: AppTypography.caption(Theme.of(context)).copyWith(
                    color: AppDs.accentYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Review section with brass spine, optional Edit jump, and body rows.
class PrintKycReviewSection extends StatelessWidget {
  const PrintKycReviewSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppDs.space4.v),
      decoration: BoxDecoration(
        color: AppDs.atelierInk,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space3.h,
              AppDs.space3.v,
              AppDs.space2.h,
              AppDs.space2.v,
            ),
            child: Row(
              children: [
                Container(
                  width: 3.h,
                  height: 28.v,
                  margin: EdgeInsetsDirectional.only(end: AppDs.space3.h),
                  decoration: BoxDecoration(
                    color: AppDs.atelierBrass,
                    borderRadius: BorderRadius.circular(AppDs.radiusFull),
                  ),
                ),
                Container(
                  width: 36.adaptSize,
                  height: 36.adaptSize,
                  margin: EdgeInsetsDirectional.only(end: AppDs.space2.h),
                  decoration: BoxDecoration(
                    color: AppDs.atelierBrass.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDs.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    color: AppDs.atelierBrass,
                    size: AppDs.iconSm.adaptSize,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.body(theme).copyWith(
                      color: AppDs.textOnDarkPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      minimumSize: Size(AppDs.minTap, AppDs.minTap),
                      padding: EdgeInsets.symmetric(horizontal: AppDs.space2.h),
                    ),
                    child: AppText(
                      'lbl_print_edit_section'.tr,
                      variant: AppTextVariant.accent,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDs.space3.h,
              0,
              AppDs.space3.h,
              AppDs.space3.v,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full review step: intro + sections (no duplicate page title).
class PrintKycReviewCard extends StatelessWidget {
  const PrintKycReviewCard({
    super.key,
    required this.children,
    this.intro,
  });

  final List<Widget> children;
  final String? intro;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: AppDs.space4.v),
          padding: EdgeInsets.all(AppDs.space4.h),
          decoration: BoxDecoration(
            color: AppDs.atelierBrass.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDs.radiusLg),
            border: Border.all(
              color: AppDs.atelierBrass.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: AppDs.atelierBrass,
                size: AppDs.iconMd.adaptSize,
              ),
              SizedBox(width: AppDs.space3.h),
              Expanded(
                child: AppText(
                  intro ?? 'msg_print_review_intro'.tr,
                  variant: AppTextVariant.secondary,
                  color: AppDs.textOnDarkSecondary,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

Future<PrintPickedDoc?> pickPrintKycFile(String kind) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: PrintKyc.allowedExtensions,
    withData: false,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final path = file.path;
  if (path == null || path.isEmpty) {
    showAppToast('msg_print_doc_pick_failed'.tr, type: ToastificationType.error);
    return null;
  }
  final bytes = file.size > 0 ? file.size : await File(path).length();
  if (bytes > PrintKyc.maxBytes) {
    showAppToast('msg_print_doc_too_large'.tr, type: ToastificationType.error);
    return null;
  }
  return PrintPickedDoc(
    kind: kind,
    path: path,
    name: file.name,
    bytes: bytes,
  );
}

/// Editable lat/lng with optional debug Jeddah defaults (not silent hardcode).
Future<void> fillDebugLocationIfEmpty({
  required TextEditingController lat,
  required TextEditingController lng,
}) async {
  if (lat.text.trim().isNotEmpty && lng.text.trim().isNotEmpty) return;
  if (kDebugMode) {
    lat.text = '21.5433';
    lng.text = '39.1728';
  }
}

String? requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'msg_print_field_required'.tr;
  }
  return null;
}

/// Saudi IBAN: SA + 22 digits (spaces ignored).
String? saudiIbanText(String? value) {
  final required = requiredText(value);
  if (required != null) return required;
  final clean = value!.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (!RegExp(r'^SA[0-9]{22}$').hasMatch(clean)) {
    return 'msg_print_iban_invalid'.tr;
  }
  return null;
}
