/// Saudi IBAN: SA + 22 digits (24 chars). ISO 13616 mod-97 checksum.
abstract final class SaudiIban {
  static String? normalize(String? iban) {
    if (iban == null) return null;
    final clean = iban.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return clean.isEmpty ? null : clean;
  }

  static bool isValid(String? iban) {
    final clean = normalize(iban);
    if (clean == null || !RegExp(r'^SA[0-9]{22}$').hasMatch(clean)) {
      return false;
    }

    final rearranged = clean.substring(4) + clean.substring(0, 4);
    final buffer = StringBuffer();
    for (final ch in rearranged.split('')) {
      final code = ch.codeUnitAt(0);
      if (code >= 65 && code <= 90) {
        buffer.write(code - 55);
      } else {
        buffer.write(ch);
      }
    }

    return _mod97(buffer.toString()) == 1;
  }

  static int _mod97(String numeric) {
    var checksum = 0;
    for (final digit in numeric.split('')) {
      checksum = (checksum * 10 + int.parse(digit)) % 97;
    }
    return checksum;
  }
}
