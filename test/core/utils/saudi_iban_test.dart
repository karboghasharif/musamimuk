import 'package:flutter_test/flutter_test.dart';
import 'package:musamimuk/core/utils/saudi_iban.dart';

void main() {
  group('SaudiIban.normalize', () {
    test('strips spaces and uppercases', () {
      expect(
        SaudiIban.normalize(' sa0380 000000 6080 1016 7519 '),
        'SA0380000000608010167519',
      );
    });

    test('maps Arabic-Indic digits', () {
      expect(
        SaudiIban.normalize('SA٠٣٨٠٠٠٠٠٠٠٦٠٨٠١٠١٦٧٥١٩'),
        'SA0380000000608010167519',
      );
    });

    test('prefixes SA when only 22 digits are entered', () {
      expect(
        SaudiIban.normalize('0380000000608010167519'),
        'SA0380000000608010167519',
      );
    });
  });

  group('SaudiIban.isValid', () {
    test('accepts known valid example', () {
      expect(SaudiIban.isValid('SA03 8000 0000 6080 1016 7519'), isTrue);
      expect(SaudiIban.isValid('SA٠٣٨٠٠٠٠٠٠٠٦٠٨٠١٠١٦٧٥١٩'), isTrue);
    });

    test('rejects bad checksum with checksum reason', () {
      expect(
        SaudiIban.validationFailure('SA0380000000608010167518'),
        SaudiIban.reasonChecksum,
      );
    });

    test('rejects bad format with format reason', () {
      expect(SaudiIban.validationFailure('SA123'), SaudiIban.reasonFormat);
    });
  });
}
