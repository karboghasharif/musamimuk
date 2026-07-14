import 'package:musamimuk/core/network/api_utils.dart';

/// User-specific contest state from detail API (`user` block).
class ContestUserContext {
  const ContestUserContext({
    this.primaryAction,
    this.joined = false,
    this.hasSubmitted = false,
    this.canJoin,
    this.canSubmit,
    this.eligibleDesignsCount,
    this.submissionId,
    this.notifyEnabled,
    this.statusMessage,
  });

  final String? primaryAction;
  final bool joined;
  final bool hasSubmitted;
  final bool? canJoin;
  final bool? canSubmit;
  final int? eligibleDesignsCount;
  final int? submissionId;
  final bool? notifyEnabled;
  final String? statusMessage;

  factory ContestUserContext.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContestUserContext();
    final statusMessage = json['status_message']?.toString().trim();
    final joined = apiParseBool(json['has_joined']) ??
        apiParseBool(json['joined']) ??
        apiParseBool(json['is_joined']) ??
        _joinedFromStatusMessage(statusMessage) ??
        false;
    final hasSubmitted = apiParseBool(json['has_submitted']) ??
        apiParseBool(json['submitted']) ??
        (json['submission_id'] != null && apiParseInt(json['submission_id']) > 0);
    return ContestUserContext(
      primaryAction: _normalizeAction(
        json['primary_action']?.toString() ??
            json['next_action']?.toString() ??
            json['cta_action']?.toString() ??
            json['action']?.toString(),
      ),
      joined: joined,
      hasSubmitted: hasSubmitted,
      canJoin: apiParseBool(json['can_join']),
      canSubmit: apiParseBool(json['can_submit']),
      eligibleDesignsCount: json['eligible_designs_count'] == null
          ? null
          : apiParseInt(json['eligible_designs_count']),
      submissionId: json['submission_id'] == null
          ? null
          : apiParseInt(json['submission_id']),
      notifyEnabled:
          apiParseBool(json['notify_enabled'] ?? json['notify_upcoming']),
      statusMessage: statusMessage?.isNotEmpty == true ? statusMessage : null,
    ).normalized();
  }

  /// Join response may nest user under `data.user` or at top level.
  factory ContestUserContext.fromJoinPayload(Map<String, dynamic>? data) {
    if (data == null) return const ContestUserContext();
    final user = data['user'];
    if (user is Map) {
      return ContestUserContext.fromJson(user.cast<String, dynamic>());
    }
    return ContestUserContext.fromJson(data);
  }

  static String? _normalizeAction(String? raw) {
    if (raw == null) return null;
    final s =
        raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    if (s.isEmpty) return null;
    return switch (s) {
      'submit_design' => 'submit',
      'view_gallery' => 'gallery',
      'view_winners' => 'winners',
      'notify_upcoming' => 'notify',
      _ => s,
    };
  }

  static bool? _joinedFromStatusMessage(String? message) {
    if (message == null || message.trim().isEmpty) return null;
    final m = message.toLowerCase();
    if (m.contains('you are in') || m.contains("you're in")) return true;
    if (m.contains('submit') &&
        (m.contains('library') || m.contains('enter') || m.contains('design'))) {
      return true;
    }
    return null;
  }

  static bool hasInlineFlags(Map<String, dynamic> json) {
    return json.containsKey('has_joined') ||
        json.containsKey('joined') ||
        json.containsKey('can_submit') ||
        json.containsKey('can_join') ||
        json.containsKey('primary_action') ||
        json.containsKey('has_submitted') ||
        json.containsKey('status_message');
  }

  bool get _statusImpliesSubmit {
    final m = statusMessage?.toLowerCase() ?? '';
    return m.contains('submit') &&
        (m.contains('library') || m.contains('enter') || m.contains('design'));
  }

  /// Whether the user can open the submit-design flow now.
  bool get shouldShowSubmit =>
      !hasSubmitted &&
      (joined || _statusImpliesSubmit) &&
      (canSubmit != false || _statusImpliesSubmit || _primaryImpliesSubmit);

  bool get _primaryImpliesSubmit =>
      primaryAction?.contains('submit') ?? false;

  /// Resolved CTA for buttons — joined users without a submission always submit first.
  String get actionKey {
    if (shouldShowSubmit || (joined && !hasSubmitted)) return 'submit';
    if (hasSubmitted) return _actionFromPrimary(fallback: 'gallery');
    if (!joined && canJoin != false) {
      if (canJoin == true || _primaryImpliesJoin) return 'join';
      final fromPrimary = _actionFromPrimary(fallback: '');
      if (fromPrimary == 'notify') return 'notify';
      if (fromPrimary == 'join') return 'join';
      return 'join';
    }
    return _actionFromPrimary(fallback: 'gallery');
  }

  bool get _primaryImpliesJoin => primaryAction?.contains('join') ?? false;

  String _actionFromPrimary({required String fallback}) {
    final a = primaryAction ?? '';
    if (a.contains('submit')) return 'submit';
    if (a.contains('join')) return 'join';
    if (a.contains('gallery') || a.contains('browse')) return 'gallery';
    if (a.contains('winner')) return 'winners';
    if (a.contains('result')) return 'results';
    if (a.contains('notify') || a.contains('upcoming')) return 'notify';
    if (a.isNotEmpty) return a;
    return fallback;
  }

  /// Applies [statusMessage] hints so detail CTAs match server copy.
  ContestUserContext normalized() {
    if (!_statusImpliesSubmit) return this;
    return copyWith(
      joined: joined || _statusImpliesSubmit,
      canJoin: false,
      canSubmit: hasSubmitted ? false : true,
    );
  }

  static ContestUserContext? merge(
    ContestUserContext? a,
    ContestUserContext? b,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b?.normalized();
    if (b == null) return a.normalized();
    return ContestUserContext(
      primaryAction: a.primaryAction ?? b.primaryAction,
      joined: a.joined || b.joined,
      hasSubmitted: a.hasSubmitted || b.hasSubmitted,
      canJoin: a.canJoin ?? b.canJoin,
      canSubmit: a.canSubmit ?? b.canSubmit,
      eligibleDesignsCount: a.eligibleDesignsCount ?? b.eligibleDesignsCount,
      submissionId: a.submissionId ?? b.submissionId,
      notifyEnabled: a.notifyEnabled ?? b.notifyEnabled,
      statusMessage: a.statusMessage ?? b.statusMessage,
    ).normalized();
  }

  ContestUserContext copyWith({
    String? primaryAction,
    bool? joined,
    bool? hasSubmitted,
    bool? canJoin,
    bool? canSubmit,
    int? eligibleDesignsCount,
    int? submissionId,
    bool? notifyEnabled,
    String? statusMessage,
  }) {
    return ContestUserContext(
      primaryAction: primaryAction ?? this.primaryAction,
      joined: joined ?? this.joined,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      canJoin: canJoin ?? this.canJoin,
      canSubmit: canSubmit ?? this.canSubmit,
      eligibleDesignsCount:
          eligibleDesignsCount ?? this.eligibleDesignsCount,
      submissionId: submissionId ?? this.submissionId,
      notifyEnabled: notifyEnabled ?? this.notifyEnabled,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
