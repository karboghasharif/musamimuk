import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/referral_repository.dart';
import '../print/print_ui.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  static Widget builder(BuildContext context) => const ReferralScreen();

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _repo = ReferralRepository();
  final _ibanCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  Map<String, dynamic>? _program;
  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ibanCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final settings = await _repo.settings();
    final me = await _repo.me();
    if (!mounted) return;
    if (settings is ReferralFailure<Map<String, dynamic>>) {
      setState(() {
        _loading = false;
        _error = settings.message;
      });
      return;
    }
    if (me is ReferralFailure<Map<String, dynamic>?>) {
      setState(() {
        _loading = false;
        _error = me.message;
      });
      return;
    }
    final program = (me as ReferralSuccess<Map<String, dynamic>?>).data;
    setState(() {
      _settings = (settings as ReferralSuccess<Map<String, dynamic>>).data;
      _program = program;
      _loading = false;
      if (program != null) {
        _ibanCtrl.text = '${program['iban'] ?? ''}';
        _bankCtrl.text = '${program['bank_name'] ?? ''}';
        _accountCtrl.text = '${program['account_name'] ?? ''}';
      }
    });
  }

  Future<void> _apply() async {
    setState(() => _busy = true);
    final result = await _repo.apply(
      iban: _ibanCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      accountName: _accountCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is ReferralFailure<Map<String, dynamic>>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('lbl_referral_applied'.tr, type: ToastificationType.success);
    await _load();
  }

  Future<void> _withdraw() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    setState(() => _busy = true);
    final result = await _repo.withdraw(
      amount: amount,
      iban: _ibanCtrl.text.trim().isEmpty ? null : _ibanCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is ReferralFailure<Map<String, dynamic>>) {
      showAppToast(result.message, type: ToastificationType.error);
      return;
    }
    showAppToast('msg_referral_withdraw_sent'.tr, type: ToastificationType.success);
    _amountCtrl.clear();
    await _load();
  }

  Future<void> _share() async {
    final url = '${_program?['share_url'] ?? ''}';
    final code = '${_program?['code'] ?? ''}';
    if (url.isEmpty && code.isEmpty) return;
    await Share.share(
      'msg_referral_share'.tr
          .replaceAll('{code}', code)
          .replaceAll('{url}', url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_referral_program'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.all(16.h),
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  Text(
                    'msg_referral_cash_intro'.tr
                        .replaceAll(
                          '{reward}',
                          '${_settings?['reward_sar_per_signup'] ?? 10}',
                        )
                        .replaceAll('{hold}', '${_settings?['hold_days'] ?? 7}')
                        .replaceAll(
                          '{min}',
                          '${_settings?['min_withdraw'] ?? 50}',
                        ),
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  SizedBox(height: 16.v),
                  if (_program == null) ...[
                    _field(_ibanCtrl, 'lbl_print_iban'.tr),
                    SizedBox(height: 8.v),
                    _field(_bankCtrl, 'lbl_referral_bank_name'.tr),
                    SizedBox(height: 8.v),
                    _field(_accountCtrl, 'lbl_referral_account_name'.tr),
                    SizedBox(height: 16.v),
                    PrintGoldButton(
                      label: 'lbl_referral_apply'.tr,
                      loading: _busy,
                      onPressed: _apply,
                    ),
                  ] else ...[
                    _statCard(_program!),
                    SizedBox(height: 12.v),
                    if (_program!['status'] == 'approved') ...[
                      OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.share_outlined, color: AppDs.printGold),
                        label: Text('lbl_referral_share_code'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDs.printGold,
                          side: const BorderSide(color: AppDs.printGold),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: '${_program!['code']}'),
                          );
                          showAppToast('lbl_referral_code_copied'.tr);
                        },
                        child: Text('lbl_referral_copy_code'.tr),
                      ),
                      SizedBox(height: 12.v),
                      _field(_amountCtrl, 'lbl_referral_withdraw_amount'.tr,
                          keyboard: TextInputType.number),
                      SizedBox(height: 8.v),
                      PrintGoldButton(
                        label: 'lbl_referral_withdraw'.tr,
                        loading: _busy,
                        onPressed: _withdraw,
                      ),
                    ] else
                      Text(
                        'msg_referral_status_${_program!['status']}'.tr,
                        style: const TextStyle(color: AppDs.printGold),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _statCard(Map<String, dynamic> program) {
    final stats = program['stats'] is Map
        ? (program['stats'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'lbl_referral_code'.tr}: ${program['code']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.v),
          Text(
            '${'lbl_referral_pending'.tr}: SAR ${program['pending_sar']} · '
            '${'lbl_referral_available'.tr}: SAR ${program['available_sar']} · '
            '${'lbl_referral_paid'.tr}: SAR ${program['paid_sar']}',
            style: const TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 4.v),
          Text(
            '${'lbl_referral_signups'.tr}: ${stats['signups'] ?? 0}',
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppDs.printGold),
        ),
      ),
    );
  }
}
