/// Saudi IBAN: SA + 22 digits (24 chars). ISO 13616 mod-97 checksum.
abstract final class SaudiIban {
  /// Why [isValid] failed (for localized messages).
  static const String reasonEmpty = 'empty';
  static const String reasonFormat = 'format';
  static const String reasonChecksum = 'checksum';

  /// Strip spaces/punctuation, map Arabic digits → ASCII, uppercase.
  ///
  /// If the user enters only the 22 numeric digits, prefixes `SA`.
  static String? normalize(String? iban) {
    if (iban == null) return null;
    final mapped = _mapEasternDigits(iban);
    final clean = mapped
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (clean.isEmpty) return null;
    if (RegExp(r'^[0-9]{22}$').hasMatch(clean)) {
      return 'SA$clean';
    }
    return clean;
  }

  static bool isValid(String? iban) => validationFailure(iban) == null;

  /// Returns null when valid; otherwise [reasonEmpty]/[reasonFormat]/[reasonChecksum].
  static String? validationFailure(String? iban) {
    final clean = normalize(iban);
    if (clean == null) return reasonEmpty;
    if (!RegExp(r'^SA[0-9]{22}$').hasMatch(clean)) return reasonFormat;
    if (!_passesChecksum(clean)) return reasonChecksum;
    return null;
  }

  static bool _passesChecksum(String clean) {
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

  /// Arabic-Indic (٠-٩) and Extended Arabic-Indic / Persian (۰-۹) → 0-9.
  static String _mapEasternDigits(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.write(String.fromCharCode(0x30 + (rune - 0x0660)));
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.write(String.fromCharCode(0x30 + (rune - 0x06F0)));
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
