import 'package:musamimuk/core/network/api_utils.dart';

/// Server wallet balance snapshot (`GET /wallet` or nested in other responses).
class WalletBalance {
  const WalletBalance({
    required this.balance,
    this.lifetimeEarned = 0,
    this.lifetimeSpent = 0,
    this.currencyLabel = 'coins',
  });

  final int balance;
  final int lifetimeEarned;
  final int lifetimeSpent;
  final String currencyLabel;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: apiParseInt(json['balance']),
      lifetimeEarned: apiParseInt(json['lifetime_earned']),
      lifetimeSpent: apiParseInt(json['lifetime_spent']),
      currencyLabel: apiParseString(
        json['currency_label'],
        fallback: 'coins',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'lifetime_earned': lifetimeEarned,
        'lifetime_spent': lifetimeSpent,
        'currency_label': currencyLabel,
      };

  WalletBalance copyWith({
    int? balance,
    int? lifetimeEarned,
    int? lifetimeSpent,
    String? currencyLabel,
  }) {
    return WalletBalance(
      balance: balance ?? this.balance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      lifetimeSpent: lifetimeSpent ?? this.lifetimeSpent,
      currencyLabel: currencyLabel ?? this.currencyLabel,
    );
  }
}

/// Feature cost row from `GET /wallet/costs`.
class WalletFeatureCost {
  const WalletFeatureCost({
    required this.feature,
    required this.coins,
    this.enabled = true,
    this.description = '',
  });

  final String feature;
  final int coins;
  final bool enabled;
  final String description;

  factory WalletFeatureCost.fromJson(Map<String, dynamic> json) {
    return WalletFeatureCost(
      feature: apiParseString(json['feature']),
      coins: apiParseInt(json['coins']),
      enabled: apiParseBool(json['enabled']) ?? true,
      description: apiParseString(json['description']),
    );
  }

  /// Known server feature keys for costly actions.
  static const String aiOpenaiEditor = 'ai.openai.editor';
  static const String aiOpenaiImages = 'ai.openai.images';
  static const String aiGeminiEditor = 'ai.gemini.editor';
  static const String aiGrokEditor = 'ai.grok.editor';
  static const String removeBackground = 'remove_background';
}

/// `GET /wallet/costs` payload (cost rows plus optional Grok feature flag).
class WalletCostsPayload {
  const WalletCostsPayload({
    required this.costs,
    this.grokEnabled = true,
  });

  final List<WalletFeatureCost> costs;
  final bool grokEnabled;
}

/// IAP package from `GET /wallet/packages`.
class WalletPackage {
  const WalletPackage({
    required this.sku,
    required this.title,
    required this.coins,
    this.bonusCoins = 0,
    this.totalCoins = 0,
    this.priceMicros = 0,
    this.currency = 'USD',
    this.platform = '',
  });

  final String sku;
  final String title;
  final int coins;
  final int bonusCoins;
  final int totalCoins;
  final int priceMicros;
  final String currency;
  final String platform;

  int get displayTotalCoins =>
      totalCoins > 0 ? totalCoins : (coins + bonusCoins);

  factory WalletPackage.fromJson(Map<String, dynamic> json) {
    final coins = apiParseInt(json['coins']);
    final bonus = apiParseInt(json['bonus_coins']);
    final total = apiParseInt(json['total_coins']);
    return WalletPackage(
      sku: apiParseString(json['sku']),
      title: apiParseString(json['title']),
      coins: coins,
      bonusCoins: bonus,
      totalCoins: total > 0 ? total : coins + bonus,
      priceMicros: apiParseInt(json['price_micros']),
      currency: apiParseString(json['currency'], fallback: 'USD'),
      platform: apiParseString(json['platform']),
    );
  }
}

/// Ledger entry from `GET /wallet/transactions`.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceAfter,
    this.feature,
    this.description = '',
    this.createdAt,
  });

  final int id;
  final String type;
  final int amount;
  final int? balanceAfter;
  final String? feature;
  final String description;
  final String? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: apiParseInt(json['id']),
      type: apiParseString(json['type']),
      amount: apiParseInt(json['amount']),
      balanceAfter: json.containsKey('balance_after')
          ? apiParseInt(json['balance_after'])
          : null,
      feature: json['feature']?.toString(),
      description: apiParseString(
        json['description'] ?? json['message'] ?? json['note'],
      ),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class WalletTransactionsPage {
  const WalletTransactionsPage({
    required this.items,
    this.currentPage = 1,
    this.lastPage = 1,
    this.perPage = 20,
    this.total = 0,
  });

  final List<WalletTransaction> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}

/// Details from HTTP 402 / `insufficient_coins` responses.
class InsufficientCoinsInfo {
  const InsufficientCoinsInfo({
    this.balance = 0,
    this.required = 0,
    this.shortage = 0,
    this.feature = '',
    this.message = '',
  });

  final int balance;
  final int required;
  final int shortage;
  final String feature;
  final String message;

  factory InsufficientCoinsInfo.fromResponse({
    dynamic body,
    String? fallbackMessage,
  }) {
    Map<String, dynamic>? map;
    if (body is Map) {
      map = body.cast<String, dynamic>();
    }
    final payload = map != null ? apiExtractPayloadMap(map) : null;
    final source = payload ?? map ?? const <String, dynamic>{};
    final balance = apiParseInt(source['balance']);
    final required = apiParseInt(source['required'] ?? source['cost']);
    final shortage = apiParseInt(
      source['shortage'],
      fallback: required > balance ? required - balance : 0,
    );
    return InsufficientCoinsInfo(
      balance: balance,
      required: required,
      shortage: shortage,
      feature: apiParseString(source['feature']),
      message: (apiExtractMessage(map) ?? fallbackMessage ?? '').trim(),
    );
  }
}

/// Result of `POST /wallet/iap/verify`.
class WalletIapVerifyResult {
  const WalletIapVerifyResult({
    required this.wallet,
    this.alreadyCredited = false,
    this.message = '',
    this.coinsAdded = 0,
  });

  final WalletBalance wallet;
  final bool alreadyCredited;
  final String message;
  final int coinsAdded;

  factory WalletIapVerifyResult.fromPayload(
    Map<String, dynamic> payload, {
    String? message,
  }) {
    final walletJson = payload['wallet'];
    final wallet = walletJson is Map
        ? WalletBalance.fromJson(walletJson.cast<String, dynamic>())
        : WalletBalance.fromJson(payload);
    return WalletIapVerifyResult(
      wallet: wallet,
      alreadyCredited: apiParseBool(payload['already_credited']) ?? false,
      message: message ?? '',
      coinsAdded: apiParseInt(payload['coins_added'] ?? payload['credited']),
    );
  }
}

/// Tries to parse a nested `wallet` object from auth or feature payloads.
WalletBalance? walletBalanceFromPayload(dynamic payload) {
  if (payload is! Map) return null;
  final map = payload.cast<String, dynamic>();
  final nested = map['wallet'];
  if (nested is Map) {
    return WalletBalance.fromJson(nested.cast<String, dynamic>());
  }
  if (map.containsKey('balance')) {
    return WalletBalance.fromJson(map);
  }
  return null;
}
