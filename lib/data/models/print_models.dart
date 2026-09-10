class PrintSpec {
  const PrintSpec({
    this.sizeId = 'a4',
    this.customWmm,
    this.customHmm,
    this.quantity = 100,
    this.sides = 1,
    this.color = 'color',
    this.paper = '80gsm',
    this.finishing = const [],
  });

  final String sizeId;
  final int? customWmm;
  final int? customHmm;
  final int quantity;
  final int sides;
  final String color;
  final String paper;
  final List<String> finishing;

  Map<String, dynamic> toJson() => {
    'sizeId': sizeId,
    'customWmm': customWmm,
    'customHmm': customHmm,
    'quantity': quantity,
    'sides': sides,
    'color': color,
    'paper': paper,
    'finishing': finishing,
  };

  factory PrintSpec.fromJson(Map<String, dynamic> json) {
    final finishing = json['finishing'];
    return PrintSpec(
      sizeId: json['sizeId']?.toString() ?? json['size_id']?.toString() ?? 'a4',
      customWmm: _asInt(json['customWmm'] ?? json['custom_wmm']),
      customHmm: _asInt(json['customHmm'] ?? json['custom_hmm']),
      quantity: _asInt(json['quantity']) ?? 100,
      sides: _asInt(json['sides']) ?? 1,
      color: json['color']?.toString() ?? 'color',
      paper: json['paper']?.toString() ?? '80gsm',
      finishing: finishing is List
          ? finishing.map((e) => e.toString()).toList()
          : const [],
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class PrintShopSummary {
  const PrintShopSummary({
    required this.id,
    required this.name,
    this.nameAr,
    this.phone,
    this.status = 'pending',
    this.verified = false,
    this.lat,
    this.lng,
    this.address,
    this.district,
    this.about,
    this.services = const [],
    this.hours = const {},
    this.rating = 0,
    this.reviewCount = 0,
    this.completedOrders = 0,
    this.level = 1,
    this.responseMins = 30,
    this.startingPrice = 0,
    this.trustScore = 0,
    this.distanceKm,
    this.openNow = false,
    this.reviewNote,
  });

  final int id;
  final String name;
  final String? nameAr;
  final String? phone;
  final String status;
  final bool verified;
  final double? lat;
  final double? lng;
  final String? address;
  final String? district;
  final String? about;
  final List<String> services;
  final Map<String, dynamic> hours;
  final double rating;
  final int reviewCount;
  final int completedOrders;
  final int level;
  final int responseMins;
  final double startingPrice;
  final double trustScore;
  final double? distanceKm;
  final bool openNow;
  final String? reviewNote;

  factory PrintShopSummary.fromJson(Map<String, dynamic> json) {
    final services = json['services'];
    final hours = json['hours'];
    return PrintShopSummary(
      id: PrintSpec._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      nameAr: json['name_ar']?.toString(),
      phone: json['phone']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      verified: json['verified'] == true,
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      address: json['address']?.toString(),
      district: json['district']?.toString(),
      about: json['about']?.toString(),
      services: services is List
          ? services.map((e) => e.toString()).toList()
          : const [],
      hours: hours is Map ? hours.cast<String, dynamic>() : const {},
      rating: _asDouble(json['rating']) ?? 0,
      reviewCount: PrintSpec._asInt(json['review_count']) ?? 0,
      completedOrders: PrintSpec._asInt(json['completed_orders']) ?? 0,
      level: PrintSpec._asInt(json['level']) ?? 1,
      responseMins: PrintSpec._asInt(json['response_mins']) ?? 30,
      startingPrice: _asDouble(json['starting_price']) ?? 0,
      trustScore: _asDouble(json['trust_score']) ?? 0,
      distanceKm: _asDouble(json['distance_km']),
      openNow: json['open_now'] == true,
      reviewNote: json['review_note']?.toString(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class PrintQuote {
  const PrintQuote({
    required this.id,
    required this.subtotal,
    required this.finishingTotal,
    required this.total,
    required this.etaHours,
    this.note,
    this.status = 'offered',
    this.currency = 'SAR',
  });

  final int id;
  final double subtotal;
  final double finishingTotal;
  final double total;
  final int etaHours;
  final String? note;
  final String status;
  final String currency;

  factory PrintQuote.fromJson(Map<String, dynamic> json) {
    return PrintQuote(
      id: PrintSpec._asInt(json['id']) ?? 0,
      subtotal: PrintShopSummary._asDouble(json['subtotal']) ?? 0,
      finishingTotal: PrintShopSummary._asDouble(json['finishing_total']) ?? 0,
      total: PrintShopSummary._asDouble(json['total']) ?? 0,
      etaHours: PrintSpec._asInt(json['eta_hours']) ?? 0,
      note: json['note']?.toString(),
      status: json['status']?.toString() ?? 'offered',
      currency: json['currency']?.toString() ?? 'SAR',
    );
  }
}

class PrintPaymentInfo {
  const PrintPaymentInfo({
    required this.amount,
    required this.method,
    required this.status,
    this.protectedAt,
    this.spendable = false,
  });

  final double amount;
  final String method;
  final String status;
  final String? protectedAt;
  final bool spendable;

  factory PrintPaymentInfo.fromJson(Map<String, dynamic> json) {
    return PrintPaymentInfo(
      amount: PrintShopSummary._asDouble(json['amount']) ?? 0,
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      protectedAt: json['protected_at']?.toString(),
      spendable: json['spendable'] == true,
    );
  }
}

class PrintChatMessage {
  const PrintChatMessage({
    required this.id,
    required this.from,
    required this.body,
    this.quoteId,
    this.createdAt,
  });

  final int id;
  final String from;
  final String body;
  final int? quoteId;
  final String? createdAt;

  factory PrintChatMessage.fromJson(Map<String, dynamic> json) {
    return PrintChatMessage(
      id: PrintSpec._asInt(json['id']) ?? 0,
      from: json['from']?.toString() ?? 'system',
      body: json['body']?.toString() ?? '',
      quoteId: PrintSpec._asInt(json['quote_id']),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PrintTimelineEvent {
  const PrintTimelineEvent({
    required this.title,
    this.detail,
    required this.status,
    this.at,
  });

  final String title;
  final String? detail;
  final String status;
  final String? at;

  factory PrintTimelineEvent.fromJson(Map<String, dynamic> json) {
    return PrintTimelineEvent(
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString(),
      status: json['status']?.toString() ?? '',
      at: json['at']?.toString(),
    );
  }
}

class PrintOrder {
  const PrintOrder({
    required this.id,
    required this.number,
    required this.pickupCode,
    required this.status,
    this.designId,
    this.shopId,
    this.spec,
    this.shop,
    this.quotes = const [],
    this.payment,
    this.messages = const [],
    this.timeline = const [],
    this.nextAction,
    this.canCancel = false,
    this.readyForPickup = false,
    this.currency = 'SAR',
  });

  final int id;
  final int number;
  final String pickupCode;
  final String status;
  final int? designId;
  final int? shopId;
  final PrintSpec? spec;
  final PrintShopSummary? shop;
  final List<PrintQuote> quotes;
  final PrintPaymentInfo? payment;
  final List<PrintChatMessage> messages;
  final List<PrintTimelineEvent> timeline;
  final String? nextAction;
  final bool canCancel;
  final bool readyForPickup;
  final String currency;

  PrintQuote? get offeredQuote {
    for (final quote in quotes) {
      if (quote.status == 'offered') return quote;
    }
    return quotes.isEmpty ? null : quotes.last;
  }

  factory PrintOrder.fromJson(Map<String, dynamic> json) {
    final spec = json['spec'];
    final shop = json['shop'];
    final quotes = json['quotes'];
    final messages = json['messages'];
    final timeline = json['timeline'];
    final payment = json['payment'];
    return PrintOrder(
      id: PrintSpec._asInt(json['id']) ?? 0,
      number: PrintSpec._asInt(json['number']) ?? 0,
      pickupCode: json['pickup_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'quote',
      designId: PrintSpec._asInt(json['design_id']),
      shopId: PrintSpec._asInt(json['shop_id']),
      spec: spec is Map
          ? PrintSpec.fromJson(spec.cast<String, dynamic>())
          : null,
      shop: shop is Map
          ? PrintShopSummary.fromJson(shop.cast<String, dynamic>())
          : null,
      quotes: quotes is List
          ? quotes
                .whereType<Map>()
                .map((e) => PrintQuote.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
      payment: payment is Map
          ? PrintPaymentInfo.fromJson(payment.cast<String, dynamic>())
          : null,
      messages: messages is List
          ? messages
                .whereType<Map>()
                .map((e) => PrintChatMessage.fromJson(e.cast<String, dynamic>()))
                .toList()
          : const [],
      timeline: timeline is List
          ? timeline
                .whereType<Map>()
                .map(
                  (e) => PrintTimelineEvent.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
          : const [],
      nextAction: json['next_action']?.toString(),
      canCancel: json['can_cancel'] == true,
      readyForPickup: json['ready_for_pickup'] == true,
      currency: json['currency']?.toString() ?? 'SAR',
    );
  }
}

class PrintNotice {
  const PrintNotice({
    required this.id,
    required this.title,
    required this.body,
    this.read = false,
    this.href,
  });

  final int id;
  final String title;
  final String body;
  final bool read;
  final String? href;

  factory PrintNotice.fromJson(Map<String, dynamic> json) {
    return PrintNotice(
      id: PrintSpec._asInt(json['id']) ?? 0,
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      read: json['read'] == true,
      href: json['href']?.toString(),
    );
  }
}

sealed class PrintResult<T> {}

class PrintSuccess<T> extends PrintResult<T> {
  PrintSuccess(this.data);
  final T data;
}

class PrintFailure<T> extends PrintResult<T> {
  PrintFailure(this.message);
  final String message;
}
