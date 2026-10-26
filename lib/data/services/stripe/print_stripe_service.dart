import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../models/print_models.dart';

/// Present Stripe PaymentSheet for print order checkout (Phase A).
class PrintStripeService {
  PrintStripeService._();
  static final PrintStripeService instance = PrintStripeService._();

  String? _publishableKey;

  Future<void> ensurePublishableKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      throw StateError('Missing Stripe publishable key.');
    }
    if (_publishableKey == trimmed) return;
    Stripe.publishableKey = trimmed;
    _publishableKey = trimmed;
    await Stripe.instance.applySettings();
  }

  /// Returns true when the customer completed payment in PaymentSheet.
  Future<bool> presentPaymentSheet(PrintStripeCheckout checkout) async {
    if (!checkout.needsClientPayment) {
      return checkout.status == 'succeeded';
    }
    final secret = checkout.clientSecret;
    final key = checkout.publishableKey;
    if (secret == null || secret.isEmpty || key == null || key.isEmpty) {
      throw StateError('Stripe checkout is incomplete.');
    }

    await ensurePublishableKey(key);
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: secret,
        merchantDisplayName: 'Musamimuk',
        style: ThemeMode.dark,
      ),
    );
    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false;
      }
      debugPrint('Stripe PaymentSheet error: ${e.error.localizedMessage}');
      rethrow;
    }
  }
}
