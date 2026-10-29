import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

Future<bool> showPrintDisputeSheet({
  required BuildContext context,
  required int orderId,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppDs.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _PrintDisputeSheet(orderId: orderId),
  );
  return submitted == true;
}

Future<bool> showPrintDisputeReplySheet({
  required BuildContext context,
  required int orderId,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppDs.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _PrintDisputeReplySheet(orderId: orderId),
  );
  return submitted == true;
}

class _PrintDisputeSheet extends StatefulWidget {
  const _PrintDisputeSheet({required this.orderId});

  final int orderId;

  @override
  State<_PrintDisputeSheet> createState() => _PrintDisputeSheetState();
}

class _PrintDisputeSheetState extends State<_PrintDisputeSheet> {
  final _repo = PrintRepository();
  final _issue = TextEditingController();
  final _evidence = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _busy = false;

  @override
  void dispose() {
    _issue.dispose();
    _evidence.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      showAppToast('msg_print_dispute_images_max'.tr, type: ToastificationType.error);
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(5 - _images.length));
    });
  }

  Future<void> _submit() async {
    if (_busy || _issue.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final result = await _repo.createDispute(
      orderId: widget.orderId,
      issue: _issue.text.trim(),
      evidence: _evidence.text.trim(),
      evidenceImagePaths: _images.map((e) => e.path).toList(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintDispute>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.h,
        right: 16.h,
        top: 16.v,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16.v,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_print_report_problem'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.v),
          TextField(
            controller: _issue,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'lbl_print_dispute_issue'.tr,
              labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ),
          TextField(
            controller: _evidence,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'lbl_print_dispute_evidence'.tr,
              labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ),
          SizedBox(height: 8.v),
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_library_outlined, color: AppDs.printGold),
            label: Text(
              '${'lbl_print_dispute_photos'.tr} (${_images.length}/5)',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          if (_images.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8.v),
              child: Wrap(
                spacing: 8,
                children: _images
                    .asMap()
                    .entries
                    .map(
                      (e) => Chip(
                        label: Text('${e.key + 1}'),
                        onDeleted: () => setState(() => _images.removeAt(e.key)),
                        backgroundColor: AppDs.surfaceBase,
                        labelStyle: const TextStyle(color: Colors.white),
                        deleteIconColor: Colors.white70,
                      ),
                    )
                    .toList(),
              ),
            ),
          SizedBox(height: 12.v),
          PrintGoldButton(
            label: 'lbl_print_submit_dispute'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _PrintDisputeReplySheet extends StatefulWidget {
  const _PrintDisputeReplySheet({required this.orderId});

  final int orderId;

  @override
  State<_PrintDisputeReplySheet> createState() =>
      _PrintDisputeReplySheetState();
}

class _PrintDisputeReplySheetState extends State<_PrintDisputeReplySheet> {
  final _repo = PrintRepository();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _body.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final result = await _repo.replyDispute(
      orderId: widget.orderId,
      body: _body.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintDispute>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.h,
        right: 16.h,
        top: 16.v,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16.v,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_print_dispute_reply'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.v),
          TextField(
            controller: _body,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'lbl_print_dispute_reply'.tr,
              labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ),
          SizedBox(height: 12.v),
          PrintGoldButton(
            label: 'lbl_print_submit_dispute'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
