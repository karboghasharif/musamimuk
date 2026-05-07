bool isValidEmail(String? inputString, {bool isRequired = false}) {
  bool isInputStringValid = false;
  if (!isRequired && (inputString == null ? true : inputString.isEmpty)) {
    isInputStringValid = true;
  }
  if (inputString != null && inputString.isNotEmpty) {
    const pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    final regExp = RegExp(pattern);
    isInputStringValid = regExp.hasMatch(inputString);
  }
  return isInputStringValid;
}

bool isValidPassword(String? inputString, {bool isRequired = false}) {
  bool isInputStringValid = false;
  if (!isRequired && (inputString == null ? true : inputString.isEmpty)) {
    isInputStringValid = true;
  }
  if (inputString != null && inputString.isNotEmpty) {
    const pattern =
        r'^(?=.*?[A-Z])(?=(.*[a-z]){1,})(?=(.*[\d]){1,})(?=(.*[\W]){1,})(?!.*\s).{8,}$';
    final regExp = RegExp(pattern);
    isInputStringValid = regExp.hasMatch(inputString);
  }
  return isInputStringValid;
}

/// Live password feedback aligned with [isValidPassword] rules.
enum PasswordStrengthLevel {
  /// No input yet — show requirements only.
  empty,

  /// Fewer than 8 characters.
  tooShort,

  /// Long enough but missing uppercase, lowercase, digit, or symbol / has spaces.
  weak,

  /// Meets all rules.
  strong,
}

PasswordStrengthLevel classifyPasswordStrength(String? raw) {
  final s = raw ?? '';
  if (s.isEmpty) return PasswordStrengthLevel.empty;
  if (s.length < 8) return PasswordStrengthLevel.tooShort;
  if (isValidPassword(s, isRequired: true)) {
    return PasswordStrengthLevel.strong;
  }
  return PasswordStrengthLevel.weak;
}

bool isText(String? inputString, {bool isRequired = false}) {
  bool isInputStringValid = false;
  if (!isRequired && (inputString == null ? true : inputString.isEmpty)) {
    isInputStringValid = true;
  }
  if (inputString != null && inputString.isNotEmpty) {
    const pattern = r'^[a-zA-Z]+$';
    final regExp = RegExp(pattern);
    isInputStringValid = regExp.hasMatch(inputString);
  }
  return isInputStringValid;
}

/// Digits-only phone after stripping spaces/dashes; optional leading `+`.
/// Accepts typical mobile lengths (7–15 digits).
bool isValidPhoneNumber(String? inputString, {bool isRequired = false}) {
  if (!isRequired && (inputString == null || inputString.trim().isEmpty)) {
    return true;
  }
  if (inputString == null || inputString.trim().isEmpty) return false;
  final normalized = inputString.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  final digits = normalized.startsWith('+')
      ? normalized.substring(1)
      : normalized;
  if (!RegExp(r'^[0-9]+$').hasMatch(digits)) return false;
  return digits.length >= 7 && digits.length <= 15;
}

/// Valid email **or** mobile number (for a single registration field).
bool isValidEmailOrPhone(String? value, {bool isRequired = true}) {
  if (!isRequired && (value == null || value.trim().isEmpty)) return true;
  if (value == null || value.trim().isEmpty) return false;
  final v = value.trim();
  return isValidEmail(v, isRequired: true) ||
      isValidPhoneNumber(v, isRequired: true);
}
