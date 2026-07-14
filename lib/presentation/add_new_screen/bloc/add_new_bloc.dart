import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/app_export.dart';
import '../../../data/models/selectionPopupModel/selection_popup_model.dart';
import '../../../core/utils/canvas_unit_utils.dart';
import '../models/add_new_model.dart';
import '../models/gridgallery_pic_item_model.dart';

part 'add_new_event.dart';
part 'add_new_state.dart';

// A bloc that manages the state of a Screen3AddNew according to the event that is dispatched to it.
class AddNewBloc extends Bloc<AddNewEvent, AddNewState> {
  AddNewBloc(super.initialState) {
    on<Screen3AddNewInitialEvent>(_onInitialize);
    on<ShowContainerEvent>(_onShowContainer);
    on<PickImageEvent>(_pickImageEvent);
    on<SliderHeightValueChangedEvent>(_onSliderHeightValueChanged);
    on<SliderwidthtValueChangedEvent>(_onSliderWidthValueChanged);
    on<MakeTransparentEvent>(_onMakeTransparent);
    on<SetBgColorEvent>(_onSetBgColor);
    on<ApplyCustomSizeEvent>(_onApplyCustomSize);
    on<SetBgColorToolModeEvent>(_onSetBgColorToolMode);
    on<StartScreenColorPickEvent>(_onStartScreenColorPick);
    on<EndScreenColorPickEvent>(_onEndScreenColorPick);
    on<EditorSelectionChangedEvent>(_onEditorSelectionChanged);
    on<EditorClearSelectionEvent>(_onEditorClearSelection);
    on<SetTextContextSecondaryPanelEvent>(_onSetTextContextSecondaryPanel);
    on<SetImageContextSecondaryPanelEvent>(_onSetImageContextSecondaryPanel);
    on<ClearPendingDesignHistoryEvent>(_onClearPendingDesignHistory);
  }

  /// Drops stale [SetBgColorEvent] completions when the slider moves quickly.
  int _bgColorApplyGeneration = 0;

  static bool _bgUsesCheckerboardPreview(Color color) => color.a < 1.0;

  _onSetBgColorToolMode(
    SetBgColorToolModeEvent event,
    Emitter<AddNewState> emit,
  ) {
    emit(state.copyWith(bgColorToolMode: event.mode));
  }

  void _onStartScreenColorPick(
    StartScreenColorPickEvent event,
    Emitter<AddNewState> emit,
  ) {
    emit(
      state.copyWith(
        isScreenColorPicking: true,
        showbottomContainer: '0',
      ),
    );
  }

  void _onEndScreenColorPick(
    EndScreenColorPickEvent event,
    Emitter<AddNewState> emit,
  ) {
    emit(
      state.copyWith(
        isScreenColorPicking: false,
        showbottomContainer: '4',
        bgColorToolMode: 'picker',
      ),
    );
  }

  void _onEditorSelectionChanged(
    EditorSelectionChangedEvent event,
    Emitter<AddNewState> emit,
  ) {
    final id = event.selectedElementId.trim();
    if (id.isEmpty || event.selectedElementType == null) {
      emit(
        state.copyWith(
          selectedElementId: null,
          selectedElementType: null,
          activeToolbarMode: 'default',
          textContextSecondaryPanel: 'default',
          imageContextSecondaryPanel: 'default',
        ),
      );
      return;
    }

    final type = event.selectedElementType;
    final mode = switch (type) {
      'text' => 'text',
      'image' => 'image',
      'shape' => 'shape',
      _ => 'default',
    };

    // Replacing/updating the selected layer re-fires this with the same id;
    // keep the image adjust contextual panel open in that case.
    final sameImageWidgetSelection = mode == 'image' &&
        state.selectedElementId == id &&
        state.selectedElementType == 'image';

    emit(
      state.copyWith(
        selectedElementId: id,
        selectedElementType: type,
        activeToolbarMode: mode,
        textContextSecondaryPanel: mode == 'text' ? 'default' : 'default',
        imageContextSecondaryPanel: sameImageWidgetSelection
            ? state.imageContextSecondaryPanel
            : 'default',
      ),
    );
  }

  void _onEditorClearSelection(
    EditorClearSelectionEvent event,
    Emitter<AddNewState> emit,
  ) {
    emit(
      state.copyWith(
        selectedElementId: null,
        selectedElementType: null,
        activeToolbarMode: 'default',
        textContextSecondaryPanel: 'default',
        imageContextSecondaryPanel: 'default',
      ),
    );
  }

  void _onSetTextContextSecondaryPanel(
    SetTextContextSecondaryPanelEvent event,
    Emitter<AddNewState> emit,
  ) {
    final next = event.panel.trim().isEmpty ? 'default' : event.panel.trim();
    emit(state.copyWith(textContextSecondaryPanel: next));
  }

  void _onSetImageContextSecondaryPanel(
    SetImageContextSecondaryPanelEvent event,
    Emitter<AddNewState> emit,
  ) {
    final next = event.panel.trim().isEmpty ? 'default' : event.panel.trim();
    emit(state.copyWith(imageContextSecondaryPanel: next));
  }

  void _onClearPendingDesignHistory(
    ClearPendingDesignHistoryEvent event,
    Emitter<AddNewState> emit,
  ) {
    emit(state.copyWith(clearPendingDesignHistory: true));
  }

  _onSliderHeightValueChanged(
    SliderHeightValueChangedEvent event,
    Emitter<AddNewState> emit,
  ) async {
    Uint8List image = await _createTransparentImage(
      event.width!,
      event.height!,
    );
    emit(state.copyWith(transparentBytes: image, selectedheight: event.height));
    if (state.editorKey!.currentState != null) {
      // Update the background image in the state manager
      state.editorKey!.currentState!.stateManager.updateBackgroundImages(
        oldImage:
            state.editorKey!.currentState!.stateManager.activeBackgroundImage ??
            EditorImage(byteArray: image),
        newImage: EditorImage(byteArray: image),
      );

      /// Force to rebuild everything
      int pos = state.editorKey!.currentState!.stateManager.historyPointer;
      EditorStateHistory oldHistory =
          state.editorKey!.currentState!.stateManager.stateHistory[pos];

      state.editorKey!.currentState!.stateManager.stateHistory[pos] =
          EditorStateHistory(
            layers: oldHistory.layers,
            transformConfigs: oldHistory.transformConfigs,
            blur: oldHistory.blur,
            filters: [...oldHistory.filters],
          );

      /// Ensure that in the case the editor generated
      /// in the background a screenshot it will generate
      /// it again with the new picture.
      if (pos > 0) {
        state
                .editorKey!
                .currentState!
                .stateManager
                .screenshots[pos - 1]
                .broken =
            true;
      }
    }
  }

  _onSliderWidthValueChanged(
    SliderwidthtValueChangedEvent event,
    Emitter<AddNewState> emit,
  ) async {
    Uint8List image = await _createTransparentImage(
      event.width!,
      event.height!,
    );
    emit(state.copyWith(transparentBytes: image, selectedwidth: event.width));
    if (state.editorKey!.currentState != null) {
      // Update the background image in the state manager
      state.editorKey!.currentState!.stateManager.updateBackgroundImages(
        oldImage:
            state.editorKey!.currentState!.stateManager.activeBackgroundImage ??
            EditorImage(byteArray: image),
        newImage: EditorImage(byteArray: image),
      );

      /// Force to rebuild everything
      int pos = state.editorKey!.currentState!.stateManager.historyPointer;
      EditorStateHistory oldHistory =
          state.editorKey!.currentState!.stateManager.stateHistory[pos];

      state.editorKey!.currentState!.stateManager.stateHistory[pos] =
          EditorStateHistory(
            layers: oldHistory.layers,
            transformConfigs: oldHistory.transformConfigs,
            blur: oldHistory.blur,
            filters: [...oldHistory.filters],
          );

      /// Ensure that in the case the editor generated
      /// in the background a screenshot it will generate
      /// it again with the new picture.
      if (pos > 0) {
        state
                .editorKey!
                .currentState!
                .stateManager
                .screenshots[pos - 1]
                .broken =
            true;
      }
    }
  }

  // late Uint8List transparentBytes;
  // double _transparentAspectRatio = -1;
  _pickImageEvent(PickImageEvent event, Emitter<AddNewState> emit) {
    emit(
      state.copyWith(pickedImage: event.pickeImage, showbottomContainer: "0"),
    );
  }

  _onShowContainer(ShowContainerEvent event, Emitter<AddNewState> emit) {
    emit(state.copyWith(showbottomContainer: event.ishow));
  }

  _onInitialize(
    Screen3AddNewInitialEvent event,
    Emitter<AddNewState> emit,
  ) async {
    final width = (event.width ?? 400.0).clamp(1.0, 8192.0);
    final height = (event.height ?? 400.0).clamp(1.0, 8192.0);
    final unit =
        CanvasUnitUtils.isSupported(event.unit) ? event.unit : 'px';
    final history = event.designHistoryJson?.trim();
    try {
      final image = event.backgroundImageBytes != null &&
              event.backgroundImageBytes!.isNotEmpty
          ? event.backgroundImageBytes!
          : await _createTransparentImage(width, height);
      final w = width.toInt().toString();
      final h = height.toInt().toString();
      emit(
        state.copyWith(
          transparentBytes: image,
          editorKey: GlobalKey<ProImageEditorState>(),
          selectedheight: height,
          selectedwidth: width,
          canvasUnit: unit,
          pendingDesignHistoryJson:
              (history != null && history.isNotEmpty) ? history : null,
          valueoneController: TextEditingController(text: w),
          valueTwoController: TextEditingController(text: h),
          screen3AddNewModelObj: state.screen3AddNewModelObj?.copyWith(
            gridgalleryPicItemList: fillGridgalleryPicItemList(),
          ),
        ),
      );
    } catch (_) {
      final fallback = await _createTransparentImage(400, 400);
      emit(
        state.copyWith(
          transparentBytes: fallback,
          editorKey: GlobalKey<ProImageEditorState>(),
          selectedheight: 400,
          selectedwidth: 400,
          canvasUnit: unit,
          pendingDesignHistoryJson:
              (history != null && history.isNotEmpty) ? history : null,
          valueoneController: TextEditingController(text: '400'),
          valueTwoController: TextEditingController(text: '400'),
          screen3AddNewModelObj: state.screen3AddNewModelObj?.copyWith(
            gridgalleryPicItemList: fillGridgalleryPicItemList(),
          ),
        ),
      );
    }
  }

  _onApplyCustomSize(
    ApplyCustomSizeEvent event,
    Emitter<AddNewState> emit,
  ) async {
    final unit =
        CanvasUnitUtils.isSupported(event.unit) ? event.unit : state.canvasUnit;
    state.valueoneController?.text = event.width.toInt().toString();
    state.valueTwoController?.text = event.height.toInt().toString();
    Uint8List image = await _createTransparentImage(event.width, event.height);
    emit(
      state.copyWith(
        transparentBytes: image,
        selectedheight: event.height,
        selectedwidth: event.width,
        canvasUnit: unit,
      ),
    );
    if (state.editorKey?.currentState != null) {
      _applyBackgroundToEditor(image);
    }
  }

  Future<Uint8List> _createTransparentImage(double width, double height) async {
    // double minSize = 1;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    // _transparentAspectRatio = aspectRatio;
    Uint8List transparentBytes = pngBytes!.buffer.asUint8List();
    return transparentBytes;
  }

  Future<Uint8List> _createFullyTransparentImage(
    double width,
    double height,
  ) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder, Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    // Don't draw anything - this creates a fully transparent image
    // The canvas is already transparent by default

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    Uint8List transparentBytes = pngBytes!.buffer.asUint8List();
    return transparentBytes;
  }

  _onMakeTransparent(
    MakeTransparentEvent event,
    Emitter<AddNewState> emit,
  ) async {
    if (state.isBackgroundTransparent) {
      // Restore previous background
      final Uint8List? prevBytes = state.previousBackgroundBytes;
      if (prevBytes != null) {
        emit(
          state.copyWith(
            transparentBytes: prevBytes,
            isBackgroundTransparent: false,
            previousBackgroundBytes: null,
          ),
        );
        _applyBackgroundToEditor(prevBytes);
      }
      return;
    }
    // Store current and make transparent
    Uint8List? currentBytes = state.transparentBytes;
    Uint8List transparentImage = await _createFullyTransparentImage(
      state.selectedwidth ?? 200,
      state.selectedheight ?? 200,
    );
    emit(
      state.copyWith(
        transparentBytes: transparentImage,
        previousBackgroundBytes: currentBytes,
        isBackgroundTransparent: true,
        selectedBgColor:
            state.selectedBgColor?.withValues(alpha: 0) ?? Colors.transparent,
      ),
    );
    _applyBackgroundToEditor(transparentImage);
  }

  void _applyBackgroundToEditor(Uint8List imageBytes) {
    if (state.editorKey?.currentState == null) return;
    state.editorKey!.currentState!.stateManager.updateBackgroundImages(
      oldImage:
          state.editorKey!.currentState!.stateManager.activeBackgroundImage ??
          EditorImage(byteArray: imageBytes),
      newImage: EditorImage(byteArray: imageBytes),
    );
    int pos = state.editorKey!.currentState!.stateManager.historyPointer;
    EditorStateHistory oldHistory =
        state.editorKey!.currentState!.stateManager.stateHistory[pos];
    state.editorKey!.currentState!.stateManager.stateHistory[pos] =
        EditorStateHistory(
          layers: oldHistory.layers,
          transformConfigs: oldHistory.transformConfigs,
          blur: oldHistory.blur,
          filters: [...oldHistory.filters],
        );
    if (pos > 0) {
      state.editorKey!.currentState!.stateManager.screenshots[pos - 1].broken =
          true;
    }
  }

  Future<Uint8List> _createSolidColorImage(
    double width,
    double height,
    Color color,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, width.toDouble(), height.toDouble()),
      paint,
    );
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes!.buffer.asUint8List();
  }

  _onSetBgColor(SetBgColorEvent event, Emitter<AddNewState> emit) async {
    final generation = ++_bgColorApplyGeneration;
    final w = state.selectedwidth ?? 200;
    final h = state.selectedheight ?? 200;
    final usesCheckerboard = _bgUsesCheckerboardPreview(event.color);

    // Update color immediately so sliders / wheels stay in sync while rendering.
    emit(
      state.copyWith(
        selectedBgColor: event.color,
        isBackgroundTransparent: usesCheckerboard,
        previousBackgroundBytes:
            usesCheckerboard ? state.previousBackgroundBytes : null,
      ),
    );

    final imageBytes = await _createSolidColorImage(w, h, event.color);
    if (generation != _bgColorApplyGeneration || isClosed) return;

    emit(
      state.copyWith(
        transparentBytes: imageBytes,
        selectedBgColor: event.color,
        isBackgroundTransparent: usesCheckerboard,
        previousBackgroundBytes:
            usesCheckerboard ? state.previousBackgroundBytes : null,
      ),
    );
    _applyBackgroundToEditor(imageBytes);
  }

  List<GridgalleryPicItemModel> fillGridgalleryPicItemList() {
    return [
      GridgalleryPicItemModel(
        galleryPicOne: ImageConstant.imgGallerySvgrepoCom,
        gallerypic: "Gallery Pic",
        icon: Icons.image_outlined,
      ),
      GridgalleryPicItemModel(
        galleryPicOne: ImageConstant.imgTextFontSvgrepoCom,
        gallerypic: "Add Text",
        icon: Icons.text_fields,
      ),
      // GridgalleryPicItemModel(gallerypic: "Paint", icon: Icons.brush_outlined),
      // GridgalleryPicItemModel(
      //   gallerypic: "Crop& Rotate",
      //   icon: Icons.crop_rotate,
      // ),
      // GridgalleryPicItemModel(gallerypic: "Tune", icon: Icons.tune),
      // GridgalleryPicItemModel(
      //   gallerypic: "Filter",
      //   icon: Icons.filter_alt_outlined,
      // ),
      // GridgalleryPicItemModel(gallerypic: "Blur", icon: Icons.blur_on_outlined),
    ];
  }
}
