part of 'add_new_bloc.dart';

// Abstract class for all events that can be dispatched from the\\\Screen3AddNew widget.\\\\\\ Events must be immutable and implement the [Equatable] interface.
class AddNewEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Event that is dispatched when the Screen3AddNew widget is first created.
class Screen3AddNewInitialEvent extends AddNewEvent {
  Screen3AddNewInitialEvent({
    this.height,
    this.width,
    this.unit = 'px',
    this.backgroundImageBytes,
    this.designHistoryJson,
  });
  final double? width;
  final double? height;
  final String unit;
  final Uint8List? backgroundImageBytes;
  final String? designHistoryJson;
  @override
  List<Object?> get props =>
      [width, height, unit, backgroundImageBytes, designHistoryJson];
}

class PickImageFromGalleryEvent extends AddNewEvent {}

class ShowContainerEvent extends AddNewEvent {
  ShowContainerEvent({required this.ishow});
  final String ishow;

  @override
  List<Object?> get props => [ishow];
}

class PickImageEvent extends AddNewEvent {
  PickImageEvent({required this.pickeImage});
  final File pickeImage;
  @override
  List<Object?> get props => [pickeImage];
}

class SliderHeightValueChangedEvent extends AddNewEvent {
  final double? width;
  final double? height;

  SliderHeightValueChangedEvent({this.height, this.width});

  @override
  List<Object?> get props => [height, width];
}

class SliderwidthtValueChangedEvent extends AddNewEvent {
  final double? width;
  final double? height;

  SliderwidthtValueChangedEvent({this.height, this.width});

  @override
  List<Object?> get props => [height, width];
}

class MakeTransparentEvent extends AddNewEvent {
  MakeTransparentEvent();

  @override
  List<Object?> get props => [];
}

class SetBgColorEvent extends AddNewEvent {
  SetBgColorEvent({required this.color});
  final Color color;
  @override
  List<Object?> get props => [color];
}

/// Replaces the page background with already cover-cropped raster bytes.
///
/// The bytes must already match the canvas dimensions — cropping happens in
/// [musamiRenderCoverBackground] so the editor never scales them non-uniformly.
class SetBackgroundImageEvent extends AddNewEvent {
  SetBackgroundImageEvent({required this.imageBytes});
  final Uint8List imageBytes;
  @override
  List<Object?> get props => [imageBytes];
}

class ApplyCustomSizeEvent extends AddNewEvent {
  ApplyCustomSizeEvent({
    required this.width,
    required this.height,
    this.unit = 'px',
  });
  final double width;
  final double height;
  final String unit;
  @override
  List<Object?> get props => [width, height, unit];
}

class SetBgColorToolModeEvent extends AddNewEvent {
  SetBgColorToolModeEvent({required this.mode});
  final String mode;
  @override
  List<Object?> get props => [mode];
}

/// Enter full-screen eyedropper mode (samples from canvas via RepaintBoundary).
class StartScreenColorPickEvent extends AddNewEvent {}

/// Exit eyedropper mode and restore the background-color panel.
class EndScreenColorPickEvent extends AddNewEvent {}

/// Editor selection changed (from ProImageEditor callbacks).
class EditorSelectionChangedEvent extends AddNewEvent {
  EditorSelectionChangedEvent({
    required this.selectedElementId,
    required this.selectedElementType,
  });

  /// Empty string means no selection.
  final String selectedElementId;
  final String? selectedElementType;

  @override
  List<Object?> get props => [selectedElementId, selectedElementType];
}

class EditorClearSelectionEvent extends AddNewEvent {
  @override
  List<Object?> get props => [];
}

/// Controls secondary panel within the text contextual toolbar.
///
/// Supported:
/// - `default`
/// - `stroke`
class SetTextContextSecondaryPanelEvent extends AddNewEvent {
  SetTextContextSecondaryPanelEvent({required this.panel});
  final String panel;

  @override
  List<Object?> get props => [panel];
}

/// Secondary area for the image/widget contextual toolbar: `default` | `adjust`.
class SetImageContextSecondaryPanelEvent extends AddNewEvent {
  SetImageContextSecondaryPanelEvent({required this.panel});
  final String panel;

  @override
  List<Object?> get props => [panel];
}

class ClearPendingDesignHistoryEvent extends AddNewEvent {
  @override
  List<Object?> get props => [];
}

class ToggleCanvasLockEvent extends AddNewEvent {
  @override
  List<Object?> get props => [];
}
