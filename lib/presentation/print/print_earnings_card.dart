import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/models/print_models.dart';
import '../../data/repositories/print_repository.dart';
import 'print_ui.dart';

class PrintEarningsCard extends StatefulWidget {
  const PrintEarningsCard({super.key, required this.kind});

  final String kind;

  @override
  State<PrintEarningsCard> createState() => _PrintEarningsCardState();
}

class _PrintEarningsCardState extends State<PrintEarningsCard> {
  final _repo = PrintRepository();
  PrintEarnings? _earnings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = widget.kind == 'rider'
        ? await _repo.riderEarnings()
        : await _repo.shopEarnings();
    if (!mounted) return;
    if (result is PrintSuccess<PrintEarnings>) {
      setState(() => _earnings = result.data);
    }
  }

  Future<void> _withdraw() async {
    final earnings = _earnings;
    if (earnings == null) return;
    final stripe = earnings.stripe;
    if (stripe != null && stripe.required && !stripe.payoutsEnabled) {
      final started = await _repo.startStripeConnect(widget.kind);
      if (!mounted) return;
      if (started is PrintFailure<PrintStripeConnect>) {
        showAppToast(started.message, type: ToastificationType.error);
        return;
      }
      final connect = (started as PrintSuccess<PrintStripeConnect>).data;
      final url = connect.url;
      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        showAppToast('msg_print_stripe_connect_open'.tr);
        return;
      }
      if (connect.payoutsEnabled) {
        await _load();
      }
    }
    if (!mounted) return;
    final ok = await showPrintWithdrawSheet(
      context: context,
      kind: widget.kind,
      earnings: earnings,
    );
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _earnings;
    if (earnings == null) return const SizedBox.shrink();

    Widget row(String label, String value) => Padding(
      padding: EdgeInsets.only(bottom: 6.v),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppDs.printGold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final pendingLabel = earnings.pendingDays == null
        ? printSar(earnings.locked)
        : '${printSar(earnings.locked)} · ${earnings.pendingDays} ${'lbl_print_days_left'.tr}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.v),
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_print_earnings'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.v),
          row('lbl_print_available'.tr, printSar(earnings.available)),
          row('lbl_print_protected'.tr, printSar(earnings.protectedBalance)),
          row('lbl_print_pending_hold'.tr, pendingLabel),
          SizedBox(height: 8.v),
          if (earnings.stripe?.required == true &&
              earnings.stripe?.payoutsEnabled != true)
            Padding(
              padding: EdgeInsets.only(bottom: 8.v),
              child: Text(
                'msg_print_stripe_connect_required'.tr,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          PrintGoldButton(
            label: earnings.stripe?.required == true &&
                    earnings.stripe?.payoutsEnabled != true
                ? 'lbl_print_stripe_connect'.tr
                : 'lbl_print_withdraw'.tr,
            onPressed: _withdraw,
          ),
        ],
      ),
    );
  }
}

Future<bool> showPrintWithdrawSheet({
  required BuildContext context,
  required String kind,
  required PrintEarnings earnings,
}) async {
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppDs.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => _PrintWithdrawSheet(
      kind: kind,
      earnings: earnings,
    ),
  );
  return submitted == true;
}

class _PrintWithdrawSheet extends StatefulWidget {
  const _PrintWithdrawSheet({required this.kind, required this.earnings});

  final String kind;
  final PrintEarnings earnings;

  @override
  State<_PrintWithdrawSheet> createState() => _PrintWithdrawSheetState();
}

class _PrintWithdrawSheetState extends State<_PrintWithdrawSheet> {
  final _repo = PrintRepository();
  final _amount = TextEditingController();
  final _destination = TextEditingController();
  String _method = 'iban';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _amount.text = widget.earnings.available.toStringAsFixed(2);
    _destination.text = widget.earnings.iban ?? '';
  }

  @override
  void dispose() {
    _amount.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final parsed = double.tryParse(_amount.text.trim());
    final result = widget.kind == 'rider'
        ? await _repo.withdrawRider(
            amount: parsed,
            method: _method,
            destination: _destination.text.trim(),
          )
        : await _repo.withdrawShop(
            amount: parsed,
            method: _method,
            destination: _destination.text.trim(),
          );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is PrintFailure<PrintEarnings>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('msg_print_withdraw_sent'.tr);
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
            'lbl_print_withdraw'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.v),
          Text(
            '${'lbl_print_available'.tr}: ${printSar(widget.earnings.available)}',
            style: const TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10.v),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'lbl_print_withdraw_amount'.tr,
              labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ),
          DropdownButton<String>(
            value: _method,
            dropdownColor: AppDs.surfaceRaised,
            items: [
              for (final method in ['iban', 'mada', 'stc'])
                DropdownMenuItem(
                  value: method,
                  child: Text(
                    'lbl_print_payout_$method'.tr,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _method = value);
            },
          ),
          TextField(
            controller: _destination,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'lbl_print_iban'.tr,
              labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
            ),
          ),
          SizedBox(height: 12.v),
          PrintGoldButton(
            label: 'lbl_print_withdraw'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
