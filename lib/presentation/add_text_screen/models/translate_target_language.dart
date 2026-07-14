/// Languages available in the text-editor translate picker.
enum TranslateTargetLanguage {
  english,
  arabic,
  urdu,
  french,
  spanish,
  german,
  turkish,
  hindi,
  portuguese,
  chinese,
  japanese,
  korean,
  russian,
  italian,
  indonesian,
  persian,
  bengali,
  malay;

  String get labelKey => switch (this) {
        TranslateTargetLanguage.english => 'lbl_english',
        TranslateTargetLanguage.arabic => 'lbl_arabic',
        TranslateTargetLanguage.urdu => 'lbl_urdu',
        TranslateTargetLanguage.french => 'lbl_french',
        TranslateTargetLanguage.spanish => 'lbl_spanish',
        TranslateTargetLanguage.german => 'lbl_german',
        TranslateTargetLanguage.turkish => 'lbl_turkish',
        TranslateTargetLanguage.hindi => 'lbl_hindi',
        TranslateTargetLanguage.portuguese => 'lbl_portuguese',
        TranslateTargetLanguage.chinese => 'lbl_chinese',
        TranslateTargetLanguage.japanese => 'lbl_japanese',
        TranslateTargetLanguage.korean => 'lbl_korean',
        TranslateTargetLanguage.russian => 'lbl_russian',
        TranslateTargetLanguage.italian => 'lbl_italian',
        TranslateTargetLanguage.indonesian => 'lbl_indonesian',
        TranslateTargetLanguage.persian => 'lbl_persian',
        TranslateTargetLanguage.bengali => 'lbl_bengali',
        TranslateTargetLanguage.malay => 'lbl_malay',
      };

  /// Full language name passed to Gemini for accurate translation.
  String get aiName => switch (this) {
        TranslateTargetLanguage.english => 'English',
        TranslateTargetLanguage.arabic => 'Arabic',
        TranslateTargetLanguage.urdu => 'Urdu',
        TranslateTargetLanguage.french => 'French',
        TranslateTargetLanguage.spanish => 'Spanish',
        TranslateTargetLanguage.german => 'German',
        TranslateTargetLanguage.turkish => 'Turkish',
        TranslateTargetLanguage.hindi => 'Hindi',
        TranslateTargetLanguage.portuguese => 'Portuguese',
        TranslateTargetLanguage.chinese => 'Chinese (Simplified)',
        TranslateTargetLanguage.japanese => 'Japanese',
        TranslateTargetLanguage.korean => 'Korean',
        TranslateTargetLanguage.russian => 'Russian',
        TranslateTargetLanguage.italian => 'Italian',
        TranslateTargetLanguage.indonesian => 'Indonesian',
        TranslateTargetLanguage.persian => 'Persian (Farsi)',
        TranslateTargetLanguage.bengali => 'Bengali',
        TranslateTargetLanguage.malay => 'Malay',
      };

  /// MyMemory API code — null when offline fallback is unavailable.
  String? get memoryCode => switch (this) {
        TranslateTargetLanguage.english => 'en',
        TranslateTargetLanguage.arabic => 'ar',
        TranslateTargetLanguage.urdu => 'ur',
        TranslateTargetLanguage.french => 'fr',
        TranslateTargetLanguage.spanish => 'es',
        TranslateTargetLanguage.german => 'de',
        TranslateTargetLanguage.turkish => 'tr',
        TranslateTargetLanguage.hindi => 'hi',
        TranslateTargetLanguage.portuguese => 'pt',
        TranslateTargetLanguage.chinese => 'zh',
        TranslateTargetLanguage.japanese => 'ja',
        TranslateTargetLanguage.korean => 'ko',
        TranslateTargetLanguage.russian => 'ru',
        TranslateTargetLanguage.italian => 'it',
        TranslateTargetLanguage.indonesian => 'id',
        TranslateTargetLanguage.persian => 'fa',
        TranslateTargetLanguage.bengali => 'bn',
        TranslateTargetLanguage.malay => 'ms',
      };

  static TranslateTargetLanguage fromInputLanguage(bool isUrdu) =>
      isUrdu ? TranslateTargetLanguage.urdu : TranslateTargetLanguage.english;

  bool get requiresArabicTashkeela => this == TranslateTargetLanguage.arabic;

  static const List<TranslateTargetLanguage> pickerOptions = [
    TranslateTargetLanguage.english,
    TranslateTargetLanguage.arabic,
    TranslateTargetLanguage.urdu,
    TranslateTargetLanguage.french,
    TranslateTargetLanguage.spanish,
    TranslateTargetLanguage.german,
    TranslateTargetLanguage.turkish,
    TranslateTargetLanguage.hindi,
    TranslateTargetLanguage.portuguese,
    TranslateTargetLanguage.chinese,
    TranslateTargetLanguage.japanese,
    TranslateTargetLanguage.korean,
    TranslateTargetLanguage.russian,
    TranslateTargetLanguage.italian,
    TranslateTargetLanguage.indonesian,
    TranslateTargetLanguage.persian,
    TranslateTargetLanguage.bengali,
    TranslateTargetLanguage.malay,
  ];
}
