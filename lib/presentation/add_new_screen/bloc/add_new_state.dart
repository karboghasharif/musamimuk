part of 'add_new_bloc.dart';

class AddNewState extends Equatable {
  const AddNewState({
    this.screen3AddNewModelObj,
    this.showbottomContainer = '0',
    this.editorKey,
    this.pickedImage,
    this.status = true,
    this.transparentBytes,
    this.valueoneController,
    this.valueTwoController,
    this.selectedDropDownValue,
    this.selectedheight,
    this.selectedwidth,
    this.isBackgroundTransparent = false,
    this.previousBackgroundBytes,
    this.selectedBgColor,
    this.bgColorToolMode = 'wheel',
    this.selectedElementId,
    this.selectedElementType,
    this.activeToolbarMode = 'default',
    this.textContextSecondaryPanel = 'default',
    this.imageContextSecondaryPanel = 'default',
  });

  final GlobalKey<ProImageEditorState>? editorKey;
  final File? pickedImage;
  final String showbottomContainer;
  final AddNewModel? screen3AddNewModelObj;
  final bool status;
  final Uint8List? transparentBytes;
  final TextEditingController? valueoneController;
  final TextEditingController? valueTwoController;
  final SelectionPopupModel? selectedDropDownValue;
  final double? selectedheight;
  final double? selectedwidth;
  final bool isBackgroundTransparent;
  final Uint8List? previousBackgroundBytes;
  final Color? selectedBgColor;
  final String bgColorToolMode;
  final String? selectedElementId;
  final String? selectedElementType;

  /// 'default' | 'text' | 'image' | 'shape'
  final String activeToolbarMode;

  /// Secondary row content for the text contextual toolbar.
  /// 'default' | 'stroke'
  final String textContextSecondaryPanel;

  /// Secondary row / expanded panel for the image contextual toolbar.
  /// 'default' | 'adjust'
  final String imageContextSecondaryPanel;

  final AddNewModel? addNewModel = null;
  @override
  List<Object?> get props => [
    pickedImage,
    screen3AddNewModelObj,
    showbottomContainer,
    editorKey,
    transparentBytes,
    valueoneController,
    valueTwoController,
    selectedDropDownValue,
    selectedheight,
    selectedwidth,
    isBackgroundTransparent,
    previousBackgroundBytes,
    selectedBgColor,
    bgColorToolMode,
    selectedElementId,
    selectedElementType,
    activeToolbarMode,
    textContextSecondaryPanel,
    imageContextSecondaryPanel,
  ];
  AddNewState copyWith({
    final Uint8List? transparentBytes,
    AddNewModel? screen3AddNewModelObj,
    File? pickedImage,
    String? showbottomContainer,
    final GlobalKey<ProImageEditorState>? editorKey,
    TextEditingController? valueoneController,
    TextEditingController? valueTwoController,
    SelectionPopupModel? selectedDropDownValue,
    double? selectedheight,
    double? selectedwidth,
    bool? isBackgroundTransparent,
    Uint8List? previousBackgroundBytes,
    Color? selectedBgColor,
    String? bgColorToolMode,
    String? selectedElementId,
    String? selectedElementType,
    String? activeToolbarMode,
    String? textContextSecondaryPanel,
    String? imageContextSecondaryPanel,
  }) {
    return AddNewState(
      valueoneController: valueoneController ?? this.valueoneController,
      valueTwoController: valueTwoController ?? this.valueTwoController,
      selectedDropDownValue:
          selectedDropDownValue ?? this.selectedDropDownValue,
      transparentBytes: transparentBytes ?? this.transparentBytes,
      pickedImage: pickedImage ?? this.pickedImage,
      editorKey: editorKey ?? this.editorKey,
      showbottomContainer: showbottomContainer ?? this.showbottomContainer,
      screen3AddNewModelObj:
          screen3AddNewModelObj ?? this.screen3AddNewModelObj,
      selectedheight: selectedheight ?? this.selectedheight,
      selectedwidth: selectedwidth ?? this.selectedwidth,
      isBackgroundTransparent:
          isBackgroundTransparent ?? this.isBackgroundTransparent,
      previousBackgroundBytes:
          previousBackgroundBytes ?? this.previousBackgroundBytes,
      selectedBgColor: selectedBgColor ?? this.selectedBgColor,
      bgColorToolMode: bgColorToolMode ?? this.bgColorToolMode,
      selectedElementId: selectedElementId ?? this.selectedElementId,
      selectedElementType: selectedElementType ?? this.selectedElementType,
      activeToolbarMode: activeToolbarMode ?? this.activeToolbarMode,
      textContextSecondaryPanel:
          textContextSecondaryPanel ?? this.textContextSecondaryPanel,
      imageContextSecondaryPanel:
          imageContextSecondaryPanel ?? this.imageContextSecondaryPanel,
    );
  }
}

// Represents the state of Screen3AddNew in the application.\\ ignore_for_file: must_be_immutable
