import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/data/models/print_models.dart';
import 'package:musamimuk/data/repositories/print_repository.dart';

void main() {
  group('print repository contracts', () {
    test('createJob posts design_id and spec without coin fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'quote',
            'spec': {'sizeId': 'a4', 'quantity': 100},
            'quotes': [],
            'messages': [],
            'timeline': [],
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.createJob(
        designId: 7,
        spec: const PrintSpec(sizeId: 'a4', quantity: 100, paper: '250gsm'),
      );

      expect(result, isA<PrintSuccess<PrintOrder>>());
      expect(captured?.path, 'print/jobs');
      expect(captured?.method, 'POST');
      final data = captured?.data as Map;
      expect(data['design_id'], 7);
      expect(data.containsKey('coins'), isFalse);
      expect(data.containsKey('wallet'), isFalse);
      expect((data['spec'] as Map)['quantity'], 100);
    });

    test('pay posts method and returns PrintPaySession with stripe meta', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'protected',
            'payment': {
              'amount': 120.5,
              'method': 'mada',
              'status': 'protected',
              'spendable': false,
            },
            'quotes': [],
            'messages': [],
            'timeline': [],
          },
          'meta': {
            'stripe': {'mode': 'simulated', 'status': 'succeeded'},
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.pay(orderId: 11, method: 'mada');
      expect(result, isA<PrintSuccess<PrintPaySession>>());
      final session = (result as PrintSuccess<PrintPaySession>).data;
      expect(captured?.path, 'print/orders/11/pay');
      expect((captured?.data as Map)['method'], 'mada');
      expect(session.order.status, 'protected');
      expect(session.order.payment?.status, 'protected');
      expect(session.order.payment?.spendable, isFalse);
      expect(session.stripe?.mode, 'simulated');
      expect(session.stripe?.needsClientPayment, isFalse);
    });

    test('acceptQuote and declineQuote hit quote action paths', () async {
      RequestOptions? acceptReq;
      final acceptRepo = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'awaiting_payment',
            'quotes': [
              {'id': 9, 'total': 50, 'eta_hours': 24, 'status': 'accepted'},
            ],
            'messages': [],
            'timeline': [],
          },
        }, onRequest: (request) => acceptReq = request),
      );
      final accepted = await acceptRepo.acceptQuote(orderId: 11, quoteId: 9);
      expect(accepted, isA<PrintSuccess<PrintOrder>>());
      expect(acceptReq?.path, 'print/orders/11/quotes/9/accept');
      expect((accepted as PrintSuccess<PrintOrder>).data.status, 'awaiting_payment');

      RequestOptions? declineReq;
      final declineRepo = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'quote',
            'quotes': [
              {'id': 9, 'total': 50, 'eta_hours': 24, 'status': 'declined'},
            ],
            'messages': [],
            'timeline': [],
          },
        }, onRequest: (request) => declineReq = request),
      );
      final declined = await declineRepo.declineQuote(orderId: 11, quoteId: 9);
      expect(declined, isA<PrintSuccess<PrintOrder>>());
      expect(declineReq?.path, 'print/orders/11/quotes/9/decline');
      expect((declined as PrintSuccess<PrintOrder>).data.offeredQuote, isNull);
    });

    test('PrintOrder.offeredQuote only returns offered quotes', () {
      final order = PrintOrder.fromJson({
        'id': 1,
        'number': 100,
        'pickup_code': 'M-100',
        'status': 'quote',
        'quotes': [
          {'id': 1, 'total': 10, 'eta_hours': 12, 'status': 'declined'},
          {'id': 2, 'total': 20, 'eta_hours': 24, 'status': 'offered'},
        ],
        'messages': [],
        'timeline': [],
      });
      expect(order.offeredQuote?.id, 2);
      expect(order.offeredQuote?.total, 20);

      final none = PrintOrder.fromJson({
        'id': 2,
        'number': 101,
        'pickup_code': 'M-101',
        'status': 'awaiting_payment',
        'quotes': [
          {'id': 3, 'total': 30, 'eta_hours': 24, 'status': 'accepted'},
        ],
        'messages': [],
        'timeline': [],
      });
      expect(none.offeredQuote, isNull);
    });

    test('confirmPickup posts ready order without coin fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'ready',
            'fulfillment': 'pickup',
            'quotes': [],
            'messages': [],
            'timeline': [],
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.confirmPickup(11);
      expect(result, isA<PrintSuccess<PrintOrder>>());
      expect(captured?.path, 'print/orders/11/pickup/confirm');
      expect(captured?.method, 'POST');
      final payload = captured?.data;
      if (payload is Map) {
        expect(payload.containsKey('coins'), isFalse);
        expect(payload.containsKey('wallet'), isFalse);
      }
    });

    test('previewDelivery posts address and reads fee totals', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'print_subtotal': 80,
            'delivery_fee': 10,
            'total': 90,
            'currency': 'SAR',
            'area': {'code': 'A', 'fee': 10},
            'delivery': {'id': 3, 'status': 'requested', 'fee': 10},
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.previewDelivery(
        orderId: 11,
        address: 'King Road',
        lat: 21.57,
        lng: 39.17,
      );
      expect(result, isA<PrintSuccess<PrintDeliveryQuote>>());
      final quote = (result as PrintSuccess<PrintDeliveryQuote>).data;
      expect(quote.deliveryFee, 10);
      expect(quote.total, 90);
      expect(captured?.path, 'print/orders/11/delivery');
      final data = captured?.data as Map;
      expect(data.containsKey('coins'), isFalse);
      expect(data['address'], 'King Road');
    });

    test('verifyDeliveryOtp posts otp without wallet fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 11,
            'number': 10480,
            'pickup_code': 'M-10480',
            'status': 'completed',
            'payment': {
              'amount': 90,
              'method': 'mada',
              'status': 'protected',
              'spendable': false,
            },
            'quotes': [],
            'messages': [],
            'timeline': [],
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.verifyDeliveryOtp(
        orderId: 11,
        otp: '1234',
      );
      expect(result, isA<PrintSuccess<PrintOrder>>());
      final order = (result as PrintSuccess<PrintOrder>).data;
      expect(order.status, 'completed');
      expect(order.payment?.status, 'protected');
      expect(captured?.path, 'print/orders/11/delivery/otp');
      final data = captured?.data as Map;
      expect(data['otp'], '1234');
      expect(data.containsKey('coins'), isFalse);
    });

    test('submitReview posts scores without coin fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 3,
            'target_type': 'shop',
            'verified': true,
            'overall': 4.75,
            'scores': {'print_quality': 5, 'service': 5, 'communication': 4, 'on_time': 5},
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.submitReview(
        orderId: 11,
        target: 'shop',
        scores: const {
          'print_quality': 5,
          'service': 5,
          'communication': 4,
          'on_time': 5,
        },
      );
      expect(result, isA<PrintSuccess<PrintReview>>());
      expect(captured?.path, 'print/orders/11/reviews');
      final data = captured?.data as Map;
      expect(data['target'], 'shop');
      expect(data.containsKey('coins'), isFalse);
      expect(data.containsKey('user_id'), isFalse);
      expect((result as PrintSuccess<PrintReview>).data.verified, isTrue);
    });

    test('searchShops sends sort and level without coin fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': [
            {
              'id': 1,
              'name': 'Volume Press',
              'level_label': 'Trusted Printer',
              'rating': 4.4,
            },
          ],
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.searchShops(sort: 'trusted', level: 2);
      expect(result, isA<PrintSuccess<List<PrintShopSummary>>>());
      expect(captured?.path, 'print/shops');
      expect(captured?.queryParameters['sort'], 'trusted');
      expect(captured?.queryParameters['level'], 2);
      expect(captured?.queryParameters.containsKey('coins'), isFalse);
      final shops = (result as PrintSuccess<List<PrintShopSummary>>).data;
      expect(shops.first.levelLabel, 'Trusted Printer');
    });

    test('myReputation reads customer rating dimensions', () async {
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'rating': 4.5,
            'review_count': 2,
            'communication': 4,
            'payment': 5,
            'professionalism': 4,
            'would_work_again': 5,
            'completed_orders': 3,
          },
        }),
      );

      final result = await repository.myReputation();
      expect(result, isA<PrintSuccess<PrintReputation>>());
      final rep = (result as PrintSuccess<PrintReputation>).data;
      expect(rep.rating, 4.5);
      expect(rep.communication, 4);
      expect(rep.payment, 5);
      expect(rep.professionalism, 4);
    });

    test('shopEarnings gets wallet without coin fields', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'kind': 'shop',
            'available': 90,
            'protected': 0,
            'locked': 10,
            'pending_days': 4,
            'min_withdraw': 20,
            'iban': 'SA0380000000608010167519',
            'currency': 'SAR',
            'payouts': [],
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.shopEarnings();
      expect(result, isA<PrintSuccess<PrintEarnings>>());
      final wallet = (result as PrintSuccess<PrintEarnings>).data;
      expect(captured?.path, 'print/shop/earnings');
      expect(captured?.method, 'GET');
      expect(wallet.available, 90);
      expect(wallet.pendingDays, 4);
    });

    test('withdrawShop posts amount and method without coins or user_id', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'payout': {
              'id': 1,
              'kind': 'shop',
              'amount': 90,
              'method': 'iban',
              'status': 'sent',
            },
            'wallet': {
              'kind': 'shop',
              'available': 0,
              'protected': 0,
              'locked': 0,
              'min_withdraw': 20,
              'payouts': [],
            },
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.withdrawShop(amount: 90, method: 'iban');
      expect(result, isA<PrintSuccess<PrintEarnings>>());
      expect(captured?.path, 'print/shop/withdraw');
      expect(captured?.method, 'POST');
      final data = captured?.data as Map;
      expect(data['amount'], 90);
      expect(data['method'], 'iban');
      expect(data.containsKey('coins'), isFalse);
      expect(data.containsKey('wallet'), isFalse);
      expect(data.containsKey('user_id'), isFalse);
    });

    test('createDispute posts multipart issue and evidence without user_id', () async {
      RequestOptions? captured;
      final repository = PrintRepository(
        dio: _dioReturning({
          'success': true,
          'data': {
            'id': 3,
            'order_id': 11,
            'issue': 'damaged',
            'evidence': 'photo',
            'status': 'open',
          },
        }, onRequest: (request) => captured = request),
      );

      final result = await repository.createDispute(
        orderId: 11,
        issue: 'damaged',
        evidence: 'photo',
      );
      expect(result, isA<PrintSuccess<PrintDispute>>());
      expect(captured?.path, 'print/orders/11/disputes');
      final form = captured?.data;
      expect(form, isA<FormData>());
      final fields = Map<String, String>.fromEntries((form as FormData).fields);
      expect(fields['issue'], 'damaged');
      expect(fields['evidence'], 'photo');
      expect(fields.containsKey('user_id'), isFalse);
      expect(fields.containsKey('coins'), isFalse);
    });
  });
}

Dio _dioReturning(
  Map<String, dynamic> body, {
  void Function(RequestOptions request)? onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        onRequest?.call(request);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: request,
            statusCode: 200,
            data: body,
          ),
        );
      },
    ),
  );
  return dio;
}
