/// Theme chips for Smart Suggestions caption generation.
enum AiCaptionTheme {
  sale,
  birthday,
  wedding,
  eidRamadan,
  shopOpening,
  thankYou,
  motivational,
  contest;

  String get labelKey => switch (this) {
        AiCaptionTheme.sale => 'lbl_ai_theme_sale',
        AiCaptionTheme.birthday => 'lbl_ai_theme_birthday',
        AiCaptionTheme.wedding => 'lbl_ai_theme_wedding',
        AiCaptionTheme.eidRamadan => 'lbl_ai_theme_eid',
        AiCaptionTheme.shopOpening => 'lbl_ai_theme_shop_opening',
        AiCaptionTheme.thankYou => 'lbl_ai_theme_thank_you',
        AiCaptionTheme.motivational => 'lbl_ai_theme_motivational',
        AiCaptionTheme.contest => 'lbl_ai_theme_contest',
      };

  String get aiName => switch (this) {
        AiCaptionTheme.sale => 'Sale',
        AiCaptionTheme.birthday => 'Birthday',
        AiCaptionTheme.wedding => 'Wedding',
        AiCaptionTheme.eidRamadan => 'Eid/Ramadan',
        AiCaptionTheme.shopOpening => 'Shop Opening',
        AiCaptionTheme.thankYou => 'Thank You',
        AiCaptionTheme.motivational => 'Motivational',
        AiCaptionTheme.contest => 'Contest',
      };

  static const List<AiCaptionTheme> pickerOptions = [
    AiCaptionTheme.sale,
    AiCaptionTheme.birthday,
    AiCaptionTheme.wedding,
    AiCaptionTheme.eidRamadan,
    AiCaptionTheme.shopOpening,
    AiCaptionTheme.thankYou,
    AiCaptionTheme.motivational,
    AiCaptionTheme.contest,
  ];
}
