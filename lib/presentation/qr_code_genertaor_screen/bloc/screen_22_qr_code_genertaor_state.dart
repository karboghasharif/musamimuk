part of 'screen_22_qr_code_genertaor_bloc.dart';

// represents the state of screen22qrcodegenertaor in the application.\\ ignore_for_file: must_be_immutable
class Screen22QrCodeGenertaorState extends Equatable {
  Screen22QrCodeGenertaorState({this.screen22QrCodeGenertaorModelObj});
  final Screen22QrCodeGenertaorModel? screen22QrCodeGenertaorModelObj;
  @override
  List<Object?> get props => [screen22QrCodeGenertaorModelObj];
  Screen22QrCodeGenertaorState copyWith(
      {Screen22QrCodeGenertaorModel? screen22QrCodeGenertaorModelObj}) {
    return Screen22QrCodeGenertaorState(
      screen22QrCodeGenertaorModelObj: screen22QrCodeGenertaorModelObj ??
          this.screen22QrCodeGenertaorModelObj,
    );
  }
}
