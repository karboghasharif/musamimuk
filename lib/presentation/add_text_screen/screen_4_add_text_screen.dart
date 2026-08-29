// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:toastification/toastification.dart';

// import '../../core/app_export.dart';
// import '../../core/utils/app_toast.dart';
// import 'bloc/screen_4_add_text_bloc.dart';
// import 'models/add_text_input_language.dart';
// import 'models/screen_4_add_text_model.dart';
// import 'widgets/urdu_marks_strip.dart';

// /// Maximum characters allowed in the Add Text field.
// const int kAddTextMaxLength = 250;

// Widget? _addTextHideCounter(
//   BuildContext context, {
//   required int currentLength,
//   required int? maxLength,
//   required bool isFocused,
// }) => const SizedBox.shrink();

// class Screen4AddTextScreen extends StatelessWidget {
//   const Screen4AddTextScreen({super.key});

//   static Widget builder(BuildContext context) {
//     return BlocProvider<Screen4AddTextBloc>(
//       create: (context) => Screen4AddTextBloc(
//         Screen4AddTextState(
//           screen4AddTextModelObj: const Screen4AddTextModel(),
//         ),
//       )..add(const Screen4AddTextInitialEvent()),
//       child: const Screen4AddTextScreen(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const _Screen4AddTextScaffold();
//   }
// }

// class _Screen4AddTextScaffold extends StatefulWidget {
//   const _Screen4AddTextScaffold();

//   @override
//   State<_Screen4AddTextScaffold> createState() =>
//       _Screen4AddTextScaffoldState();
// }

// class _Screen4AddTextScaffoldState extends State<_Screen4AddTextScaffold> {
//   final FocusNode _focusNode = FocusNode();
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _speechListening = false;
//   bool _speechReady = false;

//   @override
//   void dispose() {
//     _speech.stop();
//     _focusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _toggleSpeech(
//     TextEditingController controller,
//     AddTextInputLanguage language,
//   ) async {
//     if (_speechListening) {
//       await _speech.stop();
//       if (mounted) setState(() => _speechListening = false);
//       return;
//     }

//     if (!_speechReady) {
//       final ok = await _speech.initialize(
//         onStatus: (status) {
//           if (status == 'done' || status == 'notListening') {
//             if (mounted) setState(() => _speechListening = false);
//           }
//         },
//         onError: (_) {
//           if (mounted) setState(() => _speechListening = false);
//         },
//       );
//       if (!ok) {
//         if (mounted) {
//           showAppToast(
//             'msg_speech_not_available'.tr,
//             type: ToastificationType.warning,
//           );
//         }
//         return;
//       }
//       _speechReady = true;
//     }

//     if (!mounted) return;
//     setState(() => _speechListening = true);

//     final localeId = language == AddTextInputLanguage.urdu ? 'ur_IN' : 'en_US';

//     try {
//       await _speech.listen(
//         localeId: localeId,
//         onResult: (res) {
//           controller.text = res.recognizedWords;
//           controller.selection = TextSelection.collapsed(
//             offset: controller.text.length,
//           );
//         },
//         listenOptions: stt.SpeechListenOptions(
//           listenMode: stt.ListenMode.dictation,
//           cancelOnError: true,
//           partialResults: true,
//         ),
//       );
//     } catch (_) {
//       if (mounted) {
//         showAppToast('msg_speech_error'.tr, type: ToastificationType.error);
//       }
//     } finally {
//       if (mounted) setState(() => _speechListening = false);
//     }
//   }

//   Future<void> _pasteAtCursor(TextEditingController controller) async {
//     final data = await Clipboard.getData(Clipboard.kTextPlain);
//     final text = data?.text;
//     if (text == null || text.isEmpty) {
//       if (mounted) {
//         showAppToast('msg_paste_empty'.tr, type: ToastificationType.info);
//       }
//       return;
//     }
//     final value = controller.value;
//     final sel = value.selection;
//     final s = value.text;
//     final next = !sel.isValid
//         ? s + text
//         : s.replaceRange(sel.start, sel.end, text);
//     final off = !sel.isValid ? next.length : sel.start + text.length;
//     controller.value = TextEditingValue(
//       text: next.length > kAddTextMaxLength
//           ? next.substring(0, kAddTextMaxLength)
//           : next,
//       selection: TextSelection.collapsed(
//         offset: off > kAddTextMaxLength ? kAddTextMaxLength : off,
//       ),
//     );
//     _focusNode.requestFocus();
//   }

//   void _clearField(TextEditingController controller) {
//     controller.clear();
//     _focusNode.requestFocus();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppDs.surfaceBase,
//       resizeToAvoidBottomInset: true,
//       body: BlocBuilder<Screen4AddTextBloc, Screen4AddTextState>(
//         builder: (context, state) {
//           final controller = state.originalLanguageEditTextController;
//           final lang = state.inputLanguage;
//           final isUrdu = lang == AddTextInputLanguage.urdu;

//           if (controller == null) {
//             return const Center(child: AppLoadingBlock());
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Expanded(
//                 child: SafeArea(
//                   bottom: false,
//                   child: SingleChildScrollView(
//                     padding: EdgeInsets.fromLTRB(
//                       AppDs.space4.h,
//                       AppDs.space3.v,
//                       AppDs.space4.h,
//                       AppDs.space6.v,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Row(
//                           children: [
//                             IconButton(
//                               onPressed: () {
//                                 if (Navigator.of(context).canPop()) {
//                                   Navigator.of(context).pop();
//                                 } else {
//                                   NavigatorService.pushNamed(
//                                     AppRoutes.screen3AddNewScreen,
//                                   );
//                                 }
//                               },
//                               icon: const Icon(Icons.close_rounded),
//                               tooltip: MaterialLocalizations.of(
//                                 context,
//                               ).closeButtonTooltip,
//                               style: IconButton.styleFrom(
//                                 foregroundColor: AppDs.textOnDarkPrimary,
//                               ),
//                             ),
//                           ],
//                         ),
//                         AppPageHeader(
//                           title: isUrdu
//                               ? 'lbl_add_text_title_urdu'.tr
//                               : 'lbl_add_text_title_english'.tr,
//                           subtitle: 'msg_add_text_helper'.tr,
//                         ),
//                         SizedBox(height: AppDs.space4.v),
//                         _LanguageToggle(
//                           language: lang,
//                           onChanged: (v) => context
//                               .read<Screen4AddTextBloc>()
//                               .add(Screen4AddTextSetLanguageEvent(v)),
//                         ),
//                         SizedBox(height: AppDs.space4.v),
//                         AppCard(
//                           elevated: true,
//                           padding: EdgeInsets.fromLTRB(
//                             AppDs.space4.h,
//                             AppDs.space3.v,
//                             AppDs.space4.h,
//                             AppDs.space3.v,
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               TextField(
//                                 controller: controller,
//                                 focusNode: _focusNode,
//                                 maxLines: 8,
//                                 minLines: 5,
//                                 maxLength: kAddTextMaxLength,
//                                 textAlign: isUrdu
//                                     ? TextAlign.right
//                                     : TextAlign.left,
//                                 textDirection: isUrdu
//                                     ? TextDirection.rtl
//                                     : TextDirection.ltr,
//                                 style: AppTypography.body(Theme.of(context)).copyWith(
//                                   color: AppDs.textOnDarkPrimary,
//                                 ),
//                                 decoration: InputDecoration(
//                                   isDense: true,
//                                   border: InputBorder.none,
//                                   hintText: isUrdu
//                                       ? 'msg_add_text_placeholder_ur'.tr
//                                       : 'msg_add_text_placeholder_en'.tr,
//                                   hintStyle: AppTypography.secondary(
//                                     Theme.of(context),
//                                   ).copyWith(
//                                     color: AppDs.textOnDarkPrimary,
//                                   ),
//                                   counterText: '',
//                                 ),
//                                 buildCounter: _addTextHideCounter,
//                               ),
//                               SizedBox(height: AppDs.space2.v),
//                               ValueListenableBuilder<TextEditingValue>(
//                                 valueListenable: controller,
//                                 builder: (context, value, _) {
//                                   final len = value.text.length;
//                                   return Align(
//                                     alignment: isUrdu
//                                         ? Alignment.centerLeft
//                                         : Alignment.centerRight,
//                                     child: AppText(
//                                       '$len/$kAddTextMaxLength',
//                                       variant: AppTextVariant.caption,
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: AppDs.space4.v),
//                         AppCard(
//                           padding: EdgeInsets.symmetric(
//                             vertical: AppDs.space3.v,
//                             horizontal: AppDs.space2.h,
//                           ),
//                           child: SingleChildScrollView(
//                             scrollDirection: Axis.horizontal,
//                             child: Row(
//                               children: [
//                                 _ToolbarAction(
//                                   icon: Icons.mic_rounded,
//                                   label: 'lbl_toolbar_voice'.tr,
//                                   iconColor: _speechListening
//                                       ? Theme.of(context).colorScheme.error
//                                       : AppDs.textOnDarkSecondary,
//                                   onPressed: () =>
//                                       _toggleSpeech(controller, lang),
//                                   semanticLabel: 'lbl_toolbar_voice'.tr,
//                                 ),
//                                 SizedBox(width: AppDs.space1.h),
//                                 _ToolbarAction(
//                                   icon: Icons.content_paste_rounded,
//                                   label: 'lbl_toolbar_paste'.tr,
//                                   onPressed: () => _pasteAtCursor(controller),
//                                   semanticLabel: 'lbl_toolbar_paste'.tr,
//                                 ),
//                                 SizedBox(width: AppDs.space1.h),
//                                 _ToolbarAction(
//                                   icon: Icons.delete_outline_rounded,
//                                   label: 'lbl_toolbar_clear'.tr,
//                                   onPressed: () => _clearField(controller),
//                                   semanticLabel: 'lbl_toolbar_clear'.tr,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         if (isUrdu) ...[
//                           SizedBox(height: AppDs.space4.v),
//                           UrduMarksStrip(
//                             controller: controller,
//                             focusNode: _focusNode,
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               Material(
//                 color: AppDs.surfaceBase,
//                 elevation: 8,
//                 shadowColor: Colors.black.withValues(alpha: 0.08),
//                 child: SafeArea(
//                   top: false,
//                   child: Padding(
//                     padding: EdgeInsets.fromLTRB(
//                       AppDs.space4.h,
//                       AppDs.space3.v,
//                       AppDs.space4.h,
//                       AppDs.space4.v,
//                     ),
//                     child: ValueListenableBuilder<TextEditingValue>(
//                       valueListenable: controller,
//                       builder: (context, value, _) {
//                         final hasText = value.text.trim().isNotEmpty;
//                         return AppPrimaryButton(
//                           label: 'lbl_add_text_to_design'.tr,
//                           onPressed: hasText
//                               ? () {
//                                   if (Navigator.of(context).canPop()) {
//                                     Navigator.of(
//                                       context,
//                                     ).pop(value.text.trim());
//                                   } else {
//                                     NavigatorService.pushNamed(
//                                       AppRoutes.screen3AddNewScreen,
//                                     );
//                                   }
//                                 }
//                               : null,
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _LanguageToggle extends StatelessWidget {
//   const _LanguageToggle({required this.language, required this.onChanged});

//   final AddTextInputLanguage language;
//   final ValueChanged<AddTextInputLanguage> onChanged;

//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       padding: EdgeInsets.all(AppDs.space1.h),
//       child: Row(
//         children: [
//           Expanded(
//             child: _LangSegment(
//               label: 'lbl_english'.tr,
//               selected: language == AddTextInputLanguage.english,
//               onTap: () => onChanged(AddTextInputLanguage.english),
//             ),
//           ),
//           SizedBox(width: AppDs.space2.h),
//           Expanded(
//             child: _LangSegment(
//               label: 'lbl_urdu'.tr,
//               selected: language == AddTextInputLanguage.urdu,
//               onTap: () => onChanged(AddTextInputLanguage.urdu),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _LangSegment extends StatelessWidget {
//   const _LangSegment({
//     required this.label,
//     required this.selected,
//     required this.onTap,
//   });

//   final String label;
//   final bool selected;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final primary = Theme.of(context).colorScheme.primary;

//     return AnimatedContainer(
//       duration: AppDs.motionFast,
//       curve: Curves.easeOutCubic,
//       decoration: BoxDecoration(
//         color: selected ? AppDs.surfaceElevated : Colors.transparent,
//         borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
//         border: Border.all(
//           color: selected
//               ? primary.withValues(alpha: 0.35)
//               : Colors.transparent,
//         ),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
//           onTap: onTap,
//           child: SizedBox(
//             height: AppDs.minTap.v,
//             child: Center(
//               child: AppText(
//                 label,
//                 variant: AppTextVariant.body,
//                 color: selected ? primary : AppDs.textOnDarkSecondary,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ToolbarAction extends StatelessWidget {
//   const _ToolbarAction({
//     required this.icon,
//     required this.label,
//     required this.onPressed,
//     required this.semanticLabel,
//     this.iconColor = AppDs.textOnDarkSecondary,
//   });

//   final IconData icon;
//   final String label;
//   final VoidCallback? onPressed;
//   final String semanticLabel;
//   final Color iconColor;

//   @override
//   Widget build(BuildContext context) {
//     final enabled = onPressed != null;
//     final color = enabled ? iconColor : iconColor.withValues(alpha: 0.35);

//     return Semantics(
//       button: enabled,
//       label: semanticLabel,
//       child: DecoratedBox(
//         decoration: BoxDecoration(
//           color: AppDs.surfaceElevated,
//           borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
//           border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
//         ),
//         child: Material(
//           color: Colors.transparent,
//           borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
//           child: InkWell(
//             borderRadius: BorderRadius.circular(AppDs.radiusMd.adaptSize),
//             onTap: onPressed,
//             child: SizedBox(
//               width: 72.h,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(
//                   vertical: AppDs.space2.v,
//                   horizontal: AppDs.space1.h,
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(icon, size: AppDs.iconMd.adaptSize, color: color),
//                     SizedBox(height: AppDs.space1.v),
//                     AppText(
//                       label,
//                       variant: AppTextVariant.caption,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       textAlign: TextAlign.center,
//                       color: enabled ? null : AppDs.textOnDarkSecondary.withValues(alpha: 0.35),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
