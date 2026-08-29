/// Prompt classification shared by the AI command bar and image provider.
///
/// Detailed prompts must not be classified as raster images based on length:
/// templates need a selectable base image plus editable editor layers.
bool isEditableDesignPrompt(String raw) {
  final text = raw.toLowerCase();
  const designTerms = <String>[
    'banner',
    'template',
    'poster',
    'flyer',
    'social media post',
    'website header',
    'linkedin',
    'layout',
    'brochure',
    'advertisement',
    'ad creative',
  ];
  const compositionTerms = <String>[
    'text',
    'placeholder',
    'icon',
    'logo',
    'left side',
    'right side',
    'center',
    'arranged',
    'section',
    'editable',
  ];

  return designTerms.any(text.contains) && compositionTerms.any(text.contains);
}

bool looksLikeStandaloneImagePrompt(String raw) {
  final text = raw.toLowerCase();
  const imageTerms = <String>[
    'image',
    'photo',
    'picture',
    'sticker',
    'png',
    'illustration',
    'photograph',
    'photography',
    'generate an image',
    'generate image',
    'create an image',
    'draw me',
    'burger',
    'pizza',
    'logo of',
    'icon of',
  ];

  return imageTerms.any(text.contains);
}

/// Whether the user explicitly wants generated pixels applied as the canvas
/// background rather than inserted as a selectable image layer.
bool looksLikeBackgroundImagePrompt(String raw) {
  final text = raw.toLowerCase();
  const backgroundPhrases = <String>[
    'background image',
    'background photo',
    'canvas background',
    'as the background',
    'as background',
    'set the background',
    'change the background',
    'replace the background',
    'update the background',
    'make the background',
    'wallpaper',
    'backdrop',
  ];

  return backgroundPhrases.any(text.contains);
}
