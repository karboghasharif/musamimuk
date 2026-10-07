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
    this.levelLabel,
    this.levelLabelAr,
    this.levelProgress,
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
  final String? levelLabel;
  final String? levelLabelAr;
  final PrintLevelProgress? levelProgress;

  bool get canOperate => status == 'verified' || status == 'active';

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
      levelLabel: json['level_label']?.toString(),
      levelLabelAr: json['level_label_ar']?.toString(),
      levelProgress: json['level_progress'] is Map
          ? PrintLevelProgress.fromJson(
              (json['level_progress'] as Map).cast<String, dynamic>(),
            )
          : null,
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
    this.shopTotal,
    this.note,
    this.status = 'offered',
    this.currency = 'SAR',
  });

  final int id;
  final double subtotal;
  final double finishingTotal;
  final double total;
  final double? shopTotal;
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
      shopTotal: PrintShopSummary._asDouble(json['shop_total']),
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
    this.releasedAt,
    this.availableAt,
    this.shopNet,
    this.riderNet,
    this.holdDaysLeft,
    this.spendable = false,
  });

  final double amount;
  final String method;
  final String status;
  final String? protectedAt;
  final String? releasedAt;
  final String? availableAt;
  final double? shopNet;
  final double? riderNet;
  final int? holdDaysLeft;
  final bool spendable;

  factory PrintPaymentInfo.fromJson(Map<String, dynamic> json) {
    return PrintPaymentInfo(
      amount: PrintShopSummary._asDouble(json['amount']) ?? 0,
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      protectedAt: json['protected_at']?.toString(),
      releasedAt: json['released_at']?.toString(),
      availableAt: json['available_at']?.toString(),
      shopNet: PrintShopSummary._asDouble(json['shop_net']),
      riderNet: PrintShopSummary._asDouble(json['rider_net']),
      holdDaysLeft: PrintSpec._asInt(json['hold_days_left']),
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
    this.thread = 'customer_shop',
    this.createdAt,
  });

  final int id;
  final String from;
  final String body;
  final int? quoteId;
  final String thread;
  final String? createdAt;

  factory PrintChatMessage.fromJson(Map<String, dynamic> json) {
    return PrintChatMessage(
      id: PrintSpec._asInt(json['id']) ?? 0,
      from: json['from']?.toString() ?? 'system',
      body: json['body']?.toString() ?? '',
      quoteId: PrintSpec._asInt(json['quote_id']),
      thread: json['thread']?.toString() ?? 'customer_shop',
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
    this.fulfillment,
    this.printSubtotal,
    this.deliveryFee,
    this.total,
    this.delivery,
    this.pendingReviews = const [],
    this.dispute,
    this.systemTotal,
    this.designName,
    this.designFile,
    this.customerName,
    this.dropoffAddress,
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
  final String? fulfillment;
  final double? printSubtotal;
  final double? deliveryFee;
  final double? total;
  final PrintDeliveryInfo? delivery;
  final List<PrintPendingReview> pendingReviews;
  final PrintDispute? dispute;
  final double? systemTotal;
  final String? designName;
  final String? designFile;
  final String? customerName;
  final String? dropoffAddress;

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
    final pending = json['pending_reviews'];
    final design = json['design'];
    final customer = json['customer'];
    final systemQuote = json['system_quote'];
    final dropoff = json['dropoff'];
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
      fulfillment: json['fulfillment']?.toString(),
      printSubtotal: PrintShopSummary._asDouble(json['print_subtotal']),
      deliveryFee: PrintShopSummary._asDouble(json['delivery_fee']),
      total: PrintShopSummary._asDouble(json['total']),
      delivery: json['delivery'] is Map
          ? PrintDeliveryInfo.fromJson(
              (json['delivery'] as Map).cast<String, dynamic>(),
            )
          : null,
      pendingReviews: pending is List
          ? pending
                .whereType<Map>()
                .map(
                  (e) => PrintPendingReview.fromJson(
                    e.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
      dispute: json['dispute'] is Map
          ? PrintDispute.fromJson(
              (json['dispute'] as Map).cast<String, dynamic>(),
            )
          : null,
      systemTotal: systemQuote is Map
          ? PrintShopSummary._asDouble(systemQuote['total'])
          : null,
      designName: design is Map ? design['name']?.toString() : null,
      designFile: design is Map ? design['file_path']?.toString() : null,
      customerName: customer is Map ? customer['name']?.toString() : null,
      dropoffAddress: dropoff is Map ? dropoff['address']?.toString() : null,
    );
  }
}

class PrintDeliveryInfo {
  const PrintDeliveryInfo({
    required this.id,
    required this.status,
    this.orderId,
    this.riderId,
    this.address,
    this.fee = 0,
    this.expectedEarning = 0,
    this.distanceKm = 0,
    this.customerLat,
    this.customerLng,
    this.riderLat,
    this.riderLng,
    this.arrivedShopAt,
    this.arrivedCustomerAt,
    this.areaCode,
    this.riderName,
    this.riderPhone,
    this.pickupCode,
    this.orderStatus,
    this.shopName,
  });

  final int id;
  final String status;
  final int? orderId;
  final int? riderId;
  final String? address;
  final double fee;
  final double expectedEarning;
  final double distanceKm;
  final double? customerLat;
  final double? customerLng;
  final double? riderLat;
  final double? riderLng;
  final String? arrivedShopAt;
  final String? arrivedCustomerAt;
  final String? areaCode;
  final String? riderName;
  final String? riderPhone;
  final String? pickupCode;
  final String? orderStatus;
  final String? shopName;

  factory PrintDeliveryInfo.fromJson(Map<String, dynamic> json) {
    final area = json['area'];
    final rider = json['rider'];
    final order = json['order'];
    final shop = order is Map ? order['shop'] : null;
    return PrintDeliveryInfo(
      id: PrintSpec._asInt(json['id']) ?? 0,
      status: json['status']?.toString() ?? 'requested',
      orderId: PrintSpec._asInt(json['order_id'] ?? (order is Map ? order['id'] : null)),
      riderId: PrintSpec._asInt(json['rider_id']),
      address: json['address']?.toString(),
      fee: PrintShopSummary._asDouble(json['fee']) ?? 0,
      expectedEarning: PrintShopSummary._asDouble(json['expected_earning']) ?? 0,
      distanceKm: PrintShopSummary._asDouble(json['distance_km']) ?? 0,
      customerLat: PrintShopSummary._asDouble(json['customer_lat']),
      customerLng: PrintShopSummary._asDouble(json['customer_lng']),
      riderLat: PrintShopSummary._asDouble(json['rider_lat']),
      riderLng: PrintShopSummary._asDouble(json['rider_lng']),
      arrivedShopAt: json['arrived_shop_at']?.toString(),
      arrivedCustomerAt: json['arrived_customer_at']?.toString(),
      areaCode: area is Map ? area['code']?.toString() : null,
      riderName: rider is Map ? rider['name']?.toString() : null,
      riderPhone: rider is Map ? rider['phone']?.toString() : null,
      pickupCode: order is Map ? order['pickup_code']?.toString() : null,
      orderStatus: order is Map ? order['status']?.toString() : null,
      shopName: shop is Map ? shop['name']?.toString() : null,
    );
  }
}

class PrintDeliveryQuote {
  const PrintDeliveryQuote({
    required this.printSubtotal,
    required this.deliveryFee,
    required this.total,
    this.distanceKm,
    this.areaCode,
    this.assigned = false,
    this.otp,
    this.delivery,
    this.order,
    this.currency = 'SAR',
  });

  final double printSubtotal;
  final double deliveryFee;
  final double total;
  final double? distanceKm;
  final String? areaCode;
  final bool assigned;
  final String? otp;
  final PrintDeliveryInfo? delivery;
  final PrintOrder? order;
  final String currency;

  factory PrintDeliveryQuote.fromJson(Map<String, dynamic> json) {
    final area = json['area'];
    final order = json['order'];
    final delivery = json['delivery'];
    return PrintDeliveryQuote(
      printSubtotal: PrintShopSummary._asDouble(json['print_subtotal']) ?? 0,
      deliveryFee: PrintShopSummary._asDouble(json['delivery_fee']) ?? 0,
      total: PrintShopSummary._asDouble(json['total']) ?? 0,
      distanceKm: PrintShopSummary._asDouble(json['distance_km']),
      areaCode: area is Map ? area['code']?.toString() : null,
      assigned: json['assigned'] == true,
      otp: json['otp']?.toString(),
      delivery: delivery is Map
          ? PrintDeliveryInfo.fromJson(delivery.cast<String, dynamic>())
          : null,
      order: order is Map
          ? PrintOrder.fromJson(order.cast<String, dynamic>())
          : null,
      currency: json['currency']?.toString() ?? 'SAR',
    );
  }
}

class PrintRiderProfile {
  const PrintRiderProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.status = 'pending',
    this.online = false,
    this.vehicle,
    this.plate,
    this.iban,
    this.nationalId,
    this.district,
    this.reviewNote,
    this.completedDeliveries = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.level = 1,
    this.levelLabel,
    this.levelLabelAr,
    this.levelProgress,
  });

  final int id;
  final String name;
  final String phone;
  final String status;
  final bool online;
  final String? vehicle;
  final String? plate;
  final String? iban;
  final String? nationalId;
  final String? district;
  final String? reviewNote;
  final int completedDeliveries;
  final double rating;
  final int reviewCount;
  final int level;
  final String? levelLabel;
  final String? levelLabelAr;
  final PrintLevelProgress? levelProgress;

  bool get isApproved => status == 'approved';

  factory PrintRiderProfile.fromJson(Map<String, dynamic> json) {
    return PrintRiderProfile(
      id: PrintSpec._asInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      online: json['online'] == true,
      vehicle: json['vehicle']?.toString(),
      plate: json['plate']?.toString(),
      iban: json['iban']?.toString(),
      nationalId: json['national_id']?.toString(),
      district: json['district']?.toString(),
      reviewNote: json['review_note']?.toString(),
      completedDeliveries: PrintSpec._asInt(json['completed_deliveries']) ?? 0,
      rating: PrintShopSummary._asDouble(json['rating']) ?? 0,
      reviewCount: PrintSpec._asInt(json['review_count']) ?? 0,
      level: PrintSpec._asInt(json['level']) ?? 1,
      levelLabel: json['level_label']?.toString(),
      levelLabelAr: json['level_label_ar']?.toString(),
      levelProgress: json['level_progress'] is Map
          ? PrintLevelProgress.fromJson(
              (json['level_progress'] as Map).cast<String, dynamic>(),
            )
          : null,
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

class PrintLevelProgress {
  const PrintLevelProgress({
    this.level = 1,
    this.label,
    this.labelAr,
    this.hint,
    this.completedOrders = 0,
    this.rating = 0,
  });

  final int level;
  final String? label;
  final String? labelAr;
  final String? hint;
  final int completedOrders;
  final double rating;

  factory PrintLevelProgress.fromJson(Map<String, dynamic> json) {
    return PrintLevelProgress(
      level: PrintSpec._asInt(json['level']) ?? 1,
      label: json['label']?.toString(),
      labelAr: json['label_ar']?.toString(),
      hint: json['hint']?.toString(),
      completedOrders: PrintSpec._asInt(json['completed_orders']) ?? 0,
      rating: PrintShopSummary._asDouble(json['rating']) ?? 0,
    );
  }
}

class PrintPendingReview {
  const PrintPendingReview({
    required this.target,
    this.targetId,
    this.submitted = false,
  });

  final String target;
  final int? targetId;
  final bool submitted;

  factory PrintPendingReview.fromJson(Map<String, dynamic> json) {
    return PrintPendingReview(
      target: json['target']?.toString() ?? '',
      targetId: PrintSpec._asInt(json['target_id']),
      submitted: json['submitted'] == true,
    );
  }
}

class PrintReview {
  const PrintReview({
    required this.id,
    required this.targetType,
    this.scores = const {},
    this.overall = 0,
    this.comment,
    this.verified = true,
    this.createdAt,
  });

  final int id;
  final String targetType;
  final Map<String, dynamic> scores;
  final double overall;
  final String? comment;
  final bool verified;
  final String? createdAt;

  factory PrintReview.fromJson(Map<String, dynamic> json) {
    final scores = json['scores'];
    return PrintReview(
      id: PrintSpec._asInt(json['id']) ?? 0,
      targetType: json['target_type']?.toString() ?? '',
      scores: scores is Map ? scores.cast<String, dynamic>() : const {},
      overall: PrintShopSummary._asDouble(json['overall']) ?? 0,
      comment: json['comment']?.toString(),
      verified: json['verified'] != false,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PrintReputation {
  const PrintReputation({
    this.rating = 0,
    this.reviewCount = 0,
    this.communication = 0,
    this.payment = 0,
    this.professionalism = 0,
    this.wouldWorkAgain = 0,
    this.completedOrders = 0,
  });

  final double rating;
  final int reviewCount;
  final double communication;
  final double payment;
  final double professionalism;
  final double wouldWorkAgain;
  final int completedOrders;

  factory PrintReputation.fromJson(Map<String, dynamic> json) {
    return PrintReputation(
      rating: PrintShopSummary._asDouble(json['rating']) ?? 0,
      reviewCount: PrintSpec._asInt(json['review_count']) ?? 0,
      communication: PrintShopSummary._asDouble(json['communication']) ?? 0,
      payment: PrintShopSummary._asDouble(json['payment']) ?? 0,
      professionalism: PrintShopSummary._asDouble(json['professionalism']) ?? 0,
      wouldWorkAgain: PrintShopSummary._asDouble(json['would_work_again']) ?? 0,
      completedOrders: PrintSpec._asInt(json['completed_orders']) ?? 0,
    );
  }
}

class PrintDispute {
  const PrintDispute({
    required this.id,
    required this.orderId,
    required this.issue,
    this.evidence,
    this.shopReply,
    this.status = 'open',
    this.resolution,
    this.refundAmount,
    this.createdAt,
  });

  final int id;
  final int orderId;
  final String issue;
  final String? evidence;
  final String? shopReply;
  final String status;
  final String? resolution;
  final double? refundAmount;
  final String? createdAt;

  bool get isOpen => status == 'open' || status == 'shop_replied';

  factory PrintDispute.fromJson(Map<String, dynamic> json) {
    return PrintDispute(
      id: PrintSpec._asInt(json['id']) ?? 0,
      orderId: PrintSpec._asInt(json['order_id']) ?? 0,
      issue: json['issue']?.toString() ?? '',
      evidence: json['evidence']?.toString(),
      shopReply: json['shop_reply']?.toString(),
      status: json['status']?.toString() ?? 'open',
      resolution: json['resolution']?.toString(),
      refundAmount: PrintShopSummary._asDouble(json['refund_amount']),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class PrintPayoutRecord {
  const PrintPayoutRecord({
    required this.id,
    required this.kind,
    required this.amount,
    required this.method,
    required this.status,
    this.destination,
    this.sentAt,
  });

  final int id;
  final String kind;
  final double amount;
  final String method;
  final String status;
  final String? destination;
  final String? sentAt;

  factory PrintPayoutRecord.fromJson(Map<String, dynamic> json) {
    return PrintPayoutRecord(
      id: PrintSpec._asInt(json['id']) ?? 0,
      kind: json['kind']?.toString() ?? '',
      amount: PrintShopSummary._asDouble(json['amount']) ?? 0,
      method: json['method']?.toString() ?? 'iban',
      status: json['status']?.toString() ?? 'processing',
      destination: json['destination']?.toString(),
      sentAt: json['sent_at']?.toString(),
    );
  }
}

class PrintEarnings {
  const PrintEarnings({
    this.kind = 'shop',
    this.available = 0,
    this.protectedBalance = 0,
    this.locked = 0,
    this.pendingDays,
    this.minWithdraw = 20,
    this.iban,
    this.currency = 'SAR',
    this.payouts = const [],
  });

  final String kind;
  final double available;
  final double protectedBalance;
  final double locked;
  final int? pendingDays;
  final double minWithdraw;
  final String? iban;
  final String currency;
  final List<PrintPayoutRecord> payouts;

  factory PrintEarnings.fromJson(Map<String, dynamic> json) {
    final payouts = json['payouts'];
    return PrintEarnings(
      kind: json['kind']?.toString() ?? 'shop',
      available: PrintShopSummary._asDouble(json['available']) ?? 0,
      protectedBalance: PrintShopSummary._asDouble(json['protected']) ?? 0,
      locked: PrintShopSummary._asDouble(json['locked']) ?? 0,
      pendingDays: PrintSpec._asInt(json['pending_days']),
      minWithdraw: PrintShopSummary._asDouble(json['min_withdraw']) ?? 20,
      iban: json['iban']?.toString(),
      currency: json['currency']?.toString() ?? 'SAR',
      payouts: payouts is List
          ? payouts
                .whereType<Map>()
                .map(
                  (e) => PrintPayoutRecord.fromJson(
                    e.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : const [],
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
