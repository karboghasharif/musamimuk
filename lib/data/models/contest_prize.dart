class ContestPrize {
  const ContestPrize({
    this.amount,
    this.currency,
    this.description,
    this.label,
  });

  final double? amount;
  final String? currency;
  final String? description;
  final String? label;

  factory ContestPrize.fromJson(dynamic json) {
    if (json is! Map) return const ContestPrize();
    final map = json.cast<String, dynamic>();
    final amountRaw = map['amount'] ?? map['prize_amount'] ?? map['value'];
    double? amount;
    if (amountRaw is num) {
      amount = amountRaw.toDouble();
    } else {
      amount = double.tryParse(amountRaw?.toString() ?? '');
    }
    return ContestPrize(
      amount: amount,
      currency: map['currency']?.toString() ?? map['prize_currency']?.toString(),
      description:
          map['description']?.toString() ?? map['prize_description']?.toString(),
      label: map['label']?.toString() ?? map['prize_label']?.toString(),
    );
  }

  String displayText() {
    if (label != null && label!.trim().isNotEmpty) return label!.trim();
    if (amount != null) {
      final cur = (currency ?? '').trim();
      final formatted = amount! == amount!.roundToDouble()
          ? amount!.toInt().toString()
          : amount.toString();
      return cur.isEmpty ? formatted : '$cur $formatted';
    }
    return description?.trim() ?? '';
  }
}
