import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

const shopReviewDimensions = [
  'print_quality',
  'service',
  'communication',
  'on_time',
];

const riderReviewDimensions = [
  'speed',
  'professionalism',
  'package_handling',
];

const customerReviewDimensions = [
  'communication',
  'payment',
  'professionalism',
  'would_work_again',
];

List<String> printReviewDimensions(String target) {
  switch (target) {
    case 'rider':
      return riderReviewDimensions;
    case 'customer':
      return customerReviewDimensions;
    default:
      return shopReviewDimensions;
  }
}

Future<bool> showPrintReviewSheet({
  required BuildContext context,
  required int orderId,
  required String target,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppDs.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _PrintReviewSheet(
      orderId: orderId,
      target: target,
    ),
  );
  return submitted == true;
}

Future<void> promptPendingPrintReviews({
  required BuildContext context,
  required PrintOrder order,
}) async {
  for (final pending in order.pendingReviews) {
    if (pending.submitted || pending.target.isEmpty) continue;
    if (!context.mounted) return;
    final ok = await showPrintReviewSheet(
      context: context,
      orderId: order.id,
      target: pending.target,
    );
    if (!ok) return;
  }
}

class _PrintReviewSheet extends StatefulWidget {
  const _PrintReviewSheet({required this.orderId, required this.target});

  final int orderId;
  final String target;

  @override
  State<_PrintReviewSheet> createState() => _PrintReviewSheetState();
}

class _PrintReviewSheetState extends State<_PrintReviewSheet> {
  final _repo = PrintRepository();
  final _comment = TextEditingController();
  late final Map<String, int> _scores;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scores = {
      for (final key in printReviewDimensions(widget.target)) key: 5,
    };
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await _repo.submitReview(
      orderId: widget.orderId,
      target: widget.target,
      scores: Map<String, int>.from(_scores),
      comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is PrintFailure<PrintReview>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 16.v + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'lbl_print_review_${widget.target}'.tr,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.fSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12.v),
            ..._scores.keys.map(
              (key) => Padding(
                padding: EdgeInsets.only(bottom: 8.v),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'lbl_print_dim_$key'.tr,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ...List.generate(5, (index) {
                      final value = index + 1;
                      final selected = (_scores[key] ?? 0) >= value;
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _scores[key] = value),
                        icon: Icon(
                          selected ? Icons.star : Icons.star_border,
                          color: AppDs.printGold,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            TextField(
              controller: _comment,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'lbl_print_review_comment'.tr,
                hintStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
                filled: true,
                fillColor: AppDs.surfaceBase,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 12.v),
            PrintGoldButton(
              label: 'lbl_print_submit_review'.tr,
              loading: _saving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
