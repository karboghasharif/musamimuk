part of 'screen_4_add_text_bloc.dart';

/// Represents the state of Screen4AddText in the application.
// ignore: must_be_immutable
class Screen4AddTextState extends Equatable {
  Screen4AddTextState({
    this.originalLanguageEditTextController,
    this.screen4AddTextModelObj,
    this.inputLanguage = AddTextInputLanguage.english,
  });

  TextEditingController? originalLanguageEditTextController;
  Screen4AddTextModel? screen4AddTextModelObj;
  AddTextInputLanguage inputLanguage;

  @override
  List<Object?> get props => [
        originalLanguageEditTextController,
        screen4AddTextModelObj,
        inputLanguage,
      ];

  Screen4AddTextState copyWith({
    TextEditingController? originalLanguageEditTextController,
    Screen4AddTextModel? screen4AddTextModelObj,
    AddTextInputLanguage? inputLanguage,
  }) {
    return Screen4AddTextState(
      originalLanguageEditTextController:
          originalLanguageEditTextController ??
              this.originalLanguageEditTextController,
      screen4AddTextModelObj:
          screen4AddTextModelObj ?? this.screen4AddTextModelObj,
      inputLanguage: inputLanguage ?? this.inputLanguage,
    );
  }
}
