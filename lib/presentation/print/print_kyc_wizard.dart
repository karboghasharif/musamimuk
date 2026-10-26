import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import 'print_ui.dart';

InputDecoration printKycDecoration(String label, {String? helper}) {
  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperMaxLines: 2,
    labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
    helperStyle: const TextStyle(color: Colors.white54, fontSize: 12),
    filled: true,
    fillColor: AppDs.surfaceRaised,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class PrintKycStepHeader extends StatelessWidget {
  const PrintKycStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
  });

  final int step;
  final int total;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lbl_print_step_of'.tr
                .replaceAll('{n}', '$step')
                .replaceAll('{m}', '$total'),
            style: TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
              fontSize: 13.fSize,
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18.fSize,
            ),
          ),
          SizedBox(height: 10.v),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: step / total,
              minHeight: 6,
              backgroundColor: Colors.white12,
              color: AppDs.printGold,
            ),
          ),
        ],
      ),
    );
  }
}

class PrintKycTextField extends StatelessWidget {
  const PrintKycTextField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.v),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: printKycDecoration(label, helper: helper),
      ),
    );
  }
}

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
    final label = PrintKyc.labelKey(kind).tr;
    return Container(
      margin: EdgeInsets.only(bottom: 10.v),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: picked == null && required
              ? Colors.orangeAccent.withValues(alpha: 0.5)
              : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  required ? '$label *' : label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (picked != null && onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, color: Colors.white70),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
            ],
          ),
          Text(
            'msg_print_doc_limits'.tr,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          SizedBox(height: 8.v),
          if (picked != null)
            Text(
              '${picked!.name} · ${(picked!.bytes / 1024).toStringAsFixed(0)} KB',
              style: const TextStyle(color: AppDs.printGold),
            )
          else
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file, color: AppDs.printGold),
                label: Text(
                  'lbl_print_choose_file'.tr,
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
        ],
      ),
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
    final Color color;
    final String title;
    switch (status) {
      case 'needs_info':
        color = Colors.orangeAccent;
        title = 'msg_print_needs_info'.tr;
      case 'pending':
        color = AppDs.printGold;
        title = 'msg_print_awaiting_review'.tr;
      case 'suspended':
        color = Colors.redAccent;
        title = 'lbl_print_status_suspended'.tr;
      default:
        color = Colors.greenAccent;
        title = 'lbl_print_status_$status'.tr;
    }
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.v),
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (reviewNote != null && reviewNote!.trim().isNotEmpty) ...[
            SizedBox(height: 6.v),
            Text(reviewNote!, style: const TextStyle(color: Colors.white70)),
          ],
          if (onFixDocs != null || onEdit != null) ...[
            SizedBox(height: 10.v),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onFixDocs != null)
                  PrintGoldButton(
                    label: 'lbl_print_upload_docs'.tr,
                    onPressed: onFixDocs!,
                  ),
                if (onEdit != null)
                  OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      side: BorderSide(color: color),
                    ),
                    child: Text(
                      'lbl_print_edit_profile'.tr,
                      style: TextStyle(color: color),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PrintDocumentList extends StatelessWidget {
  const PrintDocumentList({super.key, required this.documents});

  final List<PrintDocument> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Text(
        'msg_print_no_documents'.tr,
        style: const TextStyle(color: Colors.white54),
      );
    }
    return Column(
      children: documents
          .map(
            (doc) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                PrintKyc.labelKey(doc.kind).tr,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'lbl_print_doc_status_${doc.status}'.tr,
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: doc.fileUrl != null
                  ? const Icon(Icons.open_in_new, color: AppDs.printGold)
                  : null,
            ),
          )
          .toList(),
    );
  }
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
