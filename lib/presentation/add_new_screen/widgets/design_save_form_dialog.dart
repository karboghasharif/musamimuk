import 'package:flutter/material.dart';

import 'package:toastification/toastification.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/app_toast.dart';
import 'design_export_encode.dart';

/// Save dialog: file name; optional format and visibility (sizes & JPG quality follow editor).
///
/// [showFileType] / [allowedFileTypes] — device gallery flows show PNG/JPG only;
/// workspace upload hides format and fixes type to JPG in the submitted result.
Future<DesignSaveFormResult?> showDesignSaveFormDialog(
  BuildContext context, {
  required int initialWidth,
  required int initialHeight,
  String? suggestedName,
  bool showVisibility = true,
  bool showFileType = true,
  List<DesignExportFileType>? allowedFileTypes,
}) {
  return showDialog<DesignSaveFormResult>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (ctx) => _DesignSaveFormDialog(
      initialWidth: initialWidth,
      initialHeight: initialHeight,
      suggestedName: suggestedName,
      showVisibility: showVisibility,
      showFileType: showFileType,
      allowedFileTypes: allowedFileTypes,
    ),
  );
}

const List<DesignExportFileType> _designSaveDialogDefaultTypeOrder =
    <DesignExportFileType>[
  DesignExportFileType.png,
  DesignExportFileType.jpg,
  DesignExportFileType.pdf,
];

abstract final class _SaveDialogLook {
  static const Color accent = Color(0xFF7A1E32);
  static const Color segmentSelected = Color(0xFF3D3D3D);
  static const Color segmentIdle = Color(0xFFE8E8E8);
  static const Color label = Color(0xFF1A1A1A);
  static const Color fieldFill = Color(0xFFF0F0F0);
  static const Color segmentOnSelected = Colors.white;
  static const int defaultJpgQuality = 90;
}

class _DesignSaveFormDialog extends StatefulWidget {
  const _DesignSaveFormDialog({
    required this.initialWidth,
    required this.initialHeight,
    this.suggestedName,
    required this.showVisibility,
    required this.showFileType,
    this.allowedFileTypes,
  });

  final int initialWidth;
  final int initialHeight;
  final String? suggestedName;
  final bool showVisibility;
  final bool showFileType;
  final List<DesignExportFileType>? allowedFileTypes;

  @override
  State<_DesignSaveFormDialog> createState() => _DesignSaveFormDialogState();
}

class _DesignSaveFormDialogState extends State<_DesignSaveFormDialog> {
  late final TextEditingController _nameCtrl;
  late DesignExportFileType _fileType;
  String _visibility = 'public';

  List<DesignExportFileType> _orderedFileTypesForUi() {
    if (!widget.showFileType) return const [];
    final allowed = widget.allowedFileTypes;
    if (allowed == null) {
      return _designSaveDialogDefaultTypeOrder;
    }
    return _designSaveDialogDefaultTypeOrder
        .where(allowed.contains)
        .toList(growable: false);
  }

  DesignExportFileType _initialFileSelection(List<DesignExportFileType> order) {
    if (order.isEmpty) return DesignExportFileType.jpg;
    if (order.contains(DesignExportFileType.jpg)) {
      return DesignExportFileType.jpg;
    }
    return order.first;
  }

  @override
  void initState() {
    super.initState();
    final types = _orderedFileTypesForUi();
    _fileType = widget.showFileType ? _initialFileSelection(types) : DesignExportFileType.jpg;
    _nameCtrl = TextEditingController(
      text: widget.suggestedName?.trim().isNotEmpty == true
          ? widget.suggestedName!.trim()
          : 'msg_save_default_filename'.tr,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _nameCtrl.text.trim();
    if (title.isEmpty) {
      showAppToast('msg_save_name_required'.tr, type: ToastificationType.warning);
      return;
    }
    final w = widget.initialWidth.clamp(16, 8192);
    final h = widget.initialHeight.clamp(16, 8192);
    final fileType = widget.showFileType ? _fileType : DesignExportFileType.jpg;
    final visibility = widget.showVisibility ? _visibility : 'public';

    Navigator.of(context, rootNavigator: true).pop(
      DesignSaveFormResult(
        title: title,
        visibility: visibility,
        fileType: fileType,
        width: w,
        height: h,
        quality: _SaveDialogLook.defaultJpgQuality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDs.radiusSheet.adaptSize),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 18.h, vertical: 20.v),
      child: Padding(
        padding: EdgeInsets.only(bottom: inset.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420.h, maxHeight: 520.v),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.h, 20.v, 18.h, 18.v),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'lbl_save_dialog_heading'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _SaveDialogLook.label,
                  ),
                ),
                SizedBox(height: AppDs.space5.v),
                _LabeledRow(
                  label: 'lbl_file_name'.tr,
                  child: TextField(
                    controller: _nameCtrl,
                    style: TextStyle(
                      color: _SaveDialogLook.label,
                      fontSize: AppDs.bodyMin.fSize,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.insert_drive_file_outlined,
                        color: _SaveDialogLook.label.withValues(alpha: 0.45),
                        size: 22.adaptSize,
                      ),
                      filled: true,
                      fillColor: _SaveDialogLook.fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDs.space3.h,
                        vertical: AppDs.space3.v,
                      ),
                    ),
                  ),
                ),
                if (widget.showFileType && _orderedFileTypesForUi().isNotEmpty) ...[
                  SizedBox(height: AppDs.space4.v),
                  _LabeledRow(
                    label: 'lbl_file_type'.tr,
                    child: _SegmentRow<DesignExportFileType>(
                      value: _fileType,
                      options: _orderedFileTypesForUi().map((t) {
                        final labelKey = switch (t) {
                          DesignExportFileType.png => 'lbl_format_png',
                          DesignExportFileType.jpg => 'lbl_format_jpg',
                          DesignExportFileType.pdf => 'lbl_format_pdf',
                        };
                        return (t, labelKey.tr);
                      }).toList(),
                      onChanged: (v) => setState(() => _fileType = v),
                    ),
                  ),
                ],
                if (widget.showVisibility) ...[
                  SizedBox(height: AppDs.space4.v),
                  _LabeledRow(
                    label: 'msg_choose_design_visibility'.tr,
                    child: _SegmentRow<String>(
                      value: _visibility,
                      options: [
                        ('public', 'lbl_public'.tr),
                        ('private', 'lbl_private'.tr),
                      ],
                      onChanged: (v) => setState(() => _visibility = v),
                    ),
                  ),
                ],
                SizedBox(height: AppDs.space6.v),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      child: Text(
                        'lbl_dialog_close'.tr,
                        style: TextStyle(
                          color: _SaveDialogLook.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: AppDs.bodyMin.fSize,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _SaveDialogLook.accent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDs.space6.h,
                          vertical: AppDs.space3.v,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                        ),
                      ),
                      child: Text(
                        'lbl_save'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppDs.bodyMin.fSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _SaveDialogLook.label,
            fontSize: AppDs.bodyMin.fSize,
          ),
        ),
        SizedBox(height: AppDs.space2.v),
        child,
      ],
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(width: AppDs.space2.h),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(options[i].$1),
                borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    vertical: AppDs.space3.v,
                    horizontal: AppDs.space2.h,
                  ),
                  decoration: BoxDecoration(
                    color: value == options[i].$1
                        ? _SaveDialogLook.segmentSelected
                        : _SaveDialogLook.segmentIdle,
                    borderRadius: BorderRadius.circular(AppDs.radiusMd.h),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[i].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: value == options[i].$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12.fSize,
                      color: value == options[i].$1
                          ? _SaveDialogLook.segmentOnSelected
                          : _SaveDialogLook.label,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
