/// Hero tag used for transitions in the Pro Image Editor.
const kImageEditorHeroTag = 'Pro-Image-Editor-Hero';

/// When `true` in [Layer.meta], [LayerWidget] skips painting and hit-testing
/// the layer (used by the app layers panel).
const String kMusamiLayerHiddenMetaKey = 'musamiLayerHidden';

/// When `true` in [Layer.meta], the layer stays visible but cannot be
/// selected, moved, scaled, rotated, or edited on the canvas.
const String kMusamiLayerLockedMetaKey = 'musamiLayerLocked';

/// The maximum distance (in logical pixels) that a pointer can move before
/// being considered a drag instead of a tap.
const double tapSlop = 18.0;

/// The maximum duration (in milliseconds) that a pointer can be held down
/// to still be considered a tap.
const double tapTimeElapsed = 250.0;
