import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/saudi_iban.dart';
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
  List<Map<String, dynamic>> _withdrawals = const [];
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
    final withdrawals = await _repo.withdrawals();
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
    final payouts = withdrawals is ReferralSuccess<List<Map<String, dynamic>>>
        ? withdrawals.data
        : <Map<String, dynamic>>[];
    setState(() {
      _settings = (settings as ReferralSuccess<Map<String, dynamic>>).data;
      _program = program;
      _withdrawals = payouts;
      _loading = false;
      if (program != null) {
        _ibanCtrl.text = '${program['iban'] ?? ''}';
        _bankCtrl.text = '${program['bank_name'] ?? ''}';
        _accountCtrl.text = '${program['account_name'] ?? ''}';
      }
    });
  }

  Future<void> _apply() async {
    final failure = SaudiIban.validationFailure(_ibanCtrl.text);
    if (failure != null) {
      final message = switch (failure) {
        SaudiIban.reasonFormat => 'msg_print_iban_format'.tr,
        SaudiIban.reasonChecksum => 'msg_print_iban_checksum'.tr,
        _ => 'msg_print_iban_invalid'.tr,
      };
      showAppToast(message, type: ToastificationType.error);
      return;
    }
    final iban = SaudiIban.normalize(_ibanCtrl.text);
    if (_bankCtrl.text.trim().isEmpty || _accountCtrl.text.trim().isEmpty) {
      showAppToast('msg_print_field_required'.tr, type: ToastificationType.error);
      return;
    }
    setState(() => _busy = true);
    final result = await _repo.apply(
      iban: iban!,
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

  String get _inviteUrl {
    final fromApi = '${_program?['invite_url'] ?? _program?['share_url'] ?? ''}'.trim();
    if (fromApi.isNotEmpty) return fromApi;
    final code = '${_program?['code'] ?? ''}'.trim();
    if (code.isEmpty) return '';
    return 'https://srv1813447.hstgr.cloud/r/$code';
  }

  Future<void> _share() async {
    final code = '${_program?['code'] ?? ''}'.trim();
    final url = _inviteUrl;
    if (code.isEmpty || url.isEmpty) return;
    await Share.share(
      'msg_referral_share'.tr
          .replaceAll('{code}', code)
          .replaceAll('{url}', url),
    );
  }

  Future<void> _copy(String value, String toastKey) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    showAppToast(toastKey.tr);
  }

  @override
  Widget build(BuildContext context) {
    return PrintScaffold(
      title: 'lbl_referral_program'.tr,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppDs.atelierBrass,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.h, 8.v, 16.h, 28.v),
                children: [
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    SizedBox(height: 12.v),
                  ],
                  _IntroBand(settings: _settings),
                  SizedBox(height: 16.v),
                  if (_program == null)
                    _ApplyForm(
                      ibanCtrl: _ibanCtrl,
                      bankCtrl: _bankCtrl,
                      accountCtrl: _accountCtrl,
                      busy: _busy,
                      onApply: _apply,
                    )
                  else ...[
                    _BalanceHero(program: _program!),
                    SizedBox(height: 12.v),
                    _FunnelStrip(program: _program!),
                    SizedBox(height: 12.v),
                    _InviteKit(
                      program: _program!,
                      inviteUrl: _inviteUrl,
                      onShare: _share,
                      onCopyCode: () => _copy(
                        '${_program!['code']}',
                        'lbl_referral_code_copied',
                      ),
                      onCopyLink: () => _copy(
                        _inviteUrl,
                        'lbl_referral_link_copied',
                      ),
                    ),
                    SizedBox(height: 12.v),
                    _ProfilePanel(program: _program!),
                    if (_program!['status'] == 'approved') ...[
                      SizedBox(height: 16.v),
                      _WithdrawPanel(
                        amountCtrl: _amountCtrl,
                        busy: _busy,
                        minWithdraw: _num(_settings?['min_withdraw'] ??
                            _program!['settings']?['min_withdraw'] ??
                            50),
                        available: _num(_program!['available_sar']),
                        onWithdraw: _withdraw,
                      ),
                    ] else ...[
                      SizedBox(height: 12.v),
                      _StatusBanner(status: '${_program!['status']}'),
                    ],
                    if (_withdrawals.isNotEmpty) ...[
                      SizedBox(height: 16.v),
                      _WithdrawalsSection(items: _withdrawals),
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  static double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

// —— Sections ——

class _IntroBand extends StatelessWidget {
  const _IntroBand({required this.settings});

  final Map<String, dynamic>? settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reward = settings?['reward_sar_per_signup'] ?? 10;
    final hold = settings?['hold_days'] ?? 7;
    final min = settings?['min_withdraw'] ?? 50;
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppDs.surfaceRaised,
            AppDs.atelierInk,
          ],
        ),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.adaptSize,
                height: 36.adaptSize,
                decoration: BoxDecoration(
                  color: AppDs.atelierBrass.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppDs.radiusSm),
                ),
                child: Icon(
                  Icons.handshake_outlined,
                  color: AppDs.atelierBrass,
                  size: 20.adaptSize,
                ),
              ),
              SizedBox(width: 10.h),
              Expanded(
                child: Text(
                  'lbl_referral_earn_title'.tr,
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.fSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.v),
          Text(
            'msg_referral_cash_intro'.tr
                .replaceAll('{reward}', '$reward')
                .replaceAll('{hold}', '$hold')
                .replaceAll('{min}', '$min'),
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.45,
              fontSize: 13.fSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.program});

  final Map<String, dynamic> program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = _asDouble(program['available_sar']);
    final pending = _asDouble(program['pending_sar']);
    final paid = _asDouble(program['paid_sar']);
    return Container(
      padding: EdgeInsets.fromLTRB(18.h, 18.v, 18.h, 14.v),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        color: AppDs.surfaceRaised,
        border: Border.all(color: AppDs.atelierBrass.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppDs.atelierLamp,
            blurRadius: 28,
            offset: Offset(0, 8.v),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lbl_referral_available'.tr,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 4.v),
          Text(
            printSar(available),
            style: AppTypography.body(theme).copyWith(
              color: AppDs.atelierBrass,
              fontWeight: FontWeight.w800,
              fontSize: 32.fSize,
              height: 1.1,
            ),
          ),
          SizedBox(height: 14.v),
          PrintMetricStrip(
            items: [
              (printSar(pending), 'lbl_referral_pending'.tr),
              (printSar(paid), 'lbl_referral_paid'.tr),
              (
                '${program['stats'] is Map ? (program['stats']['withdrawals_paid'] ?? 0) : 0}',
                'lbl_referral_paid_transfers'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunnelStrip extends StatelessWidget {
  const _FunnelStrip({required this.program});

  final Map<String, dynamic> program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = program['stats'] is Map
        ? (program['stats'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final clicks = stats['link_clicks'] ?? program['link_clicks'] ?? 0;
    final signups = stats['signups'] ?? 0;
    final qualified = stats['qualified'] ?? 0;
    final conversion = stats['conversion_pct'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 14.v),
      decoration: BoxDecoration(
        color: AppDs.atelierInk,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'lbl_referral_funnel'.tr,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.v),
          PrintMetricStrip(
            items: [
              ('$clicks', 'lbl_referral_link_clicks'.tr),
              ('$signups', 'lbl_referral_signups_total'.tr),
              ('$qualified', 'lbl_referral_signups'.tr),
              ('$conversion%', 'lbl_referral_conversion'.tr),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteKit extends StatelessWidget {
  const _InviteKit({
    required this.program,
    required this.inviteUrl,
    required this.onShare,
    required this.onCopyCode,
    required this.onCopyLink,
  });

  final Map<String, dynamic> program;
  final String inviteUrl;
  final VoidCallback onShare;
  final VoidCallback onCopyCode;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = '${program['code'] ?? ''}';
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_referral_invite_kit'.tr,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.v),
          _CopyRow(
            label: 'lbl_referral_code'.tr,
            value: code,
            mono: true,
            onCopy: onCopyCode,
          ),
          SizedBox(height: 10.v),
          _CopyRow(
            label: 'lbl_referral_paid_link'.tr,
            value: inviteUrl,
            onCopy: onCopyLink,
          ),
          SizedBox(height: 14.v),
          FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: Text('lbl_referral_share_code'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: AppDs.atelierBrass,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, AppDs.buttonHeight.v),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDs.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.mono = false,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppDs.atelierInk,
      borderRadius: BorderRadius.circular(AppDs.radiusMd),
      child: InkWell(
        onTap: onCopy,
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.h, 10.v, 8.h, 10.v),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.caption(theme).copyWith(
                        color: AppDs.textOnDarkSecondary,
                        fontSize: 11.fSize,
                      ),
                    ),
                    SizedBox(height: 2.v),
                    Text(
                      value.isEmpty ? '—' : value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(theme).copyWith(
                        color: AppDs.textOnDarkPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: mono ? 18.fSize : 13.fSize,
                        letterSpacing: mono ? 1.2 : 0,
                        fontFamily: mono ? 'monospace' : null,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: 'lbl_referral_copy'.tr,
                icon: Icon(
                  Icons.copy_rounded,
                  color: AppDs.atelierBrass,
                  size: 20.adaptSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.program});

  final Map<String, dynamic> program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = '${program['status'] ?? ''}';
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'lbl_referral_profile'.tr,
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          SizedBox(height: 12.v),
          _InfoLine(
            icon: Icons.person_outline_rounded,
            label: 'lbl_referral_account_name'.tr,
            value: '${program['account_name'] ?? '—'}',
          ),
          _InfoLine(
            icon: Icons.account_balance_outlined,
            label: 'lbl_referral_bank_name'.tr,
            value: '${program['bank_name'] ?? '—'}',
          ),
          _InfoLine(
            icon: Icons.credit_card_outlined,
            label: 'lbl_print_iban'.tr,
            value: '${program['iban'] ?? '—'}',
            mono: true,
          ),
          if ('${program['display_name'] ?? ''}'.trim().isNotEmpty)
            _InfoLine(
              icon: Icons.badge_outlined,
              label: 'lbl_referral_display_name'.tr,
              value: '${program['display_name']}',
            ),
          if ('${program['approved_at'] ?? ''}'.isNotEmpty)
            _InfoLine(
              icon: Icons.verified_outlined,
              label: 'lbl_referral_approved_at'.tr,
              value: _formatDate('${program['approved_at']}'),
            ),
        ],
      ),
    );
  }

  static String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return iso;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 10.v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.adaptSize, color: AppDs.atelierBrass),
          SizedBox(width: 10.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption(theme).copyWith(
                    color: AppDs.textOnDarkSecondary,
                    fontSize: 11.fSize,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.body(theme).copyWith(
                    color: AppDs.textOnDarkPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.fSize,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      'approved' || 'paid' => const Color(0xFF22C55E),
      'rejected' => const Color(0xFFEF4444),
      'suspended' => const Color(0xFFF97316),
      'requested' || 'pending' => AppDs.atelierBrass,
      _ => AppDs.textOnDarkSecondary,
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 5.v),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDs.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        'lbl_referral_status_$status'.tr,
        style: AppTypography.caption(theme).copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.fSize,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: AppDs.atelierBrass.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: AppDs.atelierBrass.withValues(alpha: 0.35)),
      ),
      child: Text(
        'msg_referral_status_$status'.tr,
        style: AppTypography.body(theme).copyWith(
          color: AppDs.atelierBrass,
          height: 1.4,
          fontSize: 13.fSize,
        ),
      ),
    );
  }
}

class _WithdrawPanel extends StatelessWidget {
  const _WithdrawPanel({
    required this.amountCtrl,
    required this.busy,
    required this.minWithdraw,
    required this.available,
    required this.onWithdraw,
  });

  final TextEditingController amountCtrl;
  final bool busy;
  final double minWithdraw;
  final double available;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_referral_withdraw'.tr,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.v),
          Text(
            'msg_referral_withdraw_hint'.tr
                .replaceAll('{min}', minWithdraw.toStringAsFixed(0))
                .replaceAll('{available}', available.toStringAsFixed(2)),
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              height: 1.35,
            ),
          ),
          SizedBox(height: 12.v),
          _ReferralField(
            controller: amountCtrl,
            label: 'lbl_referral_withdraw_amount'.tr,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 12.v),
          PrintGoldButton(
            label: 'lbl_referral_withdraw'.tr,
            loading: busy,
            onPressed: onWithdraw,
          ),
        ],
      ),
    );
  }
}

class _WithdrawalsSection extends StatelessWidget {
  const _WithdrawalsSection({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lbl_referral_withdrawal_history'.tr,
          style: AppTypography.body(theme).copyWith(
            color: AppDs.textOnDarkPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10.v),
        ...items.map((row) {
          final status = '${row['status'] ?? ''}';
          final amount = _asDouble(row['amount_sar']);
          final created = '${row['created_at'] ?? ''}';
          final dt = DateTime.tryParse(created)?.toLocal();
          final when = dt == null
              ? created
              : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          return Container(
            margin: EdgeInsets.only(bottom: 8.v),
            padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 12.v),
            decoration: BoxDecoration(
              color: AppDs.atelierInk,
              borderRadius: BorderRadius.circular(AppDs.radiusMd),
              border: Border.all(color: AppDs.atelierHairline(0.1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printSar(amount),
                        style: AppTypography.body(theme).copyWith(
                          color: AppDs.textOnDarkPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        when,
                        style: AppTypography.caption(theme).copyWith(
                          color: AppDs.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ApplyForm extends StatelessWidget {
  const _ApplyForm({
    required this.ibanCtrl,
    required this.bankCtrl,
    required this.accountCtrl,
    required this.busy,
    required this.onApply,
  });

  final TextEditingController ibanCtrl;
  final TextEditingController bankCtrl;
  final TextEditingController accountCtrl;
  final bool busy;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: AppDs.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDs.radiusLg),
        border: Border.all(color: AppDs.atelierHairline(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'lbl_referral_apply_title'.tr,
            style: AppTypography.body(theme).copyWith(
              color: AppDs.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12.v),
          _ReferralField(controller: ibanCtrl, label: 'lbl_print_iban'.tr),
          SizedBox(height: 4.v),
          Text(
            'msg_print_iban_hint'.tr,
            style: AppTypography.caption(theme).copyWith(
              color: AppDs.textOnDarkSecondary,
              fontSize: 12.fSize,
            ),
          ),
          SizedBox(height: 10.v),
          _ReferralField(
            controller: bankCtrl,
            label: 'lbl_referral_bank_name'.tr,
          ),
          SizedBox(height: 10.v),
          _ReferralField(
            controller: accountCtrl,
            label: 'lbl_referral_account_name'.tr,
          ),
          SizedBox(height: 16.v),
          PrintGoldButton(
            label: 'lbl_referral_apply'.tr,
            loading: busy,
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}

class _ReferralField extends StatelessWidget {
  const _ReferralField({
    required this.controller,
    required this.label,
    this.keyboard = TextInputType.text,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: AppDs.textOnDarkPrimary),
      cursorColor: AppDs.atelierBrass,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppDs.textOnDarkSecondary),
        filled: true,
        fillColor: AppDs.atelierInk,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: BorderSide(color: AppDs.atelierHairline(0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDs.radiusMd),
          borderSide: const BorderSide(color: AppDs.atelierBrass),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDs.radiusMd),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFFCA5A5), height: 1.35),
      ),
    );
  }
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
