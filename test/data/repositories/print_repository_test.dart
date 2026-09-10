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

    test('pay posts method and reads protected payment', () async {
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
        }),
      );

      final result = await repository.pay(orderId: 11, method: 'mada');
      expect(result, isA<PrintSuccess<PrintOrder>>());
      final order = (result as PrintSuccess<PrintOrder>).data;
      expect(order.status, 'protected');
      expect(order.payment?.status, 'protected');
      expect(order.payment?.spendable, isFalse);
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
