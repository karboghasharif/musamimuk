import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import 'bloc/screen_twentythree_bloc.dart';
import 'models/screen_twentythree_model.dart';

class ScreenTwentythreeScreen extends StatelessWidget {
  const ScreenTwentythreeScreen({super.key});
  static Widget builder(BuildContext context) {
    return BlocProvider<ScreenTwentythreeBloc>(
      create: (context) => ScreenTwentythreeBloc(const ScreenTwentythreeState(
        screenTwentythreeModelObj: ScreenTwentythreeModel(),
      ))
        ..add(ScreenTwentythreeInitialEvent()),
      child: const ScreenTwentythreeScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScreenTwentythreeBloc, ScreenTwentythreeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: appTheme.blueGray90007,
          body: Center(
            child: CustomImageView(
              imagePath: ImageConstant.imgMusammimuk02,
              height: 269.v,
              width: 276.h,
            ),
          ),
        );
      },
    );
  }
}
