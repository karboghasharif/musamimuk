import 'editor_ai_composition.dart';

/// Strict OpenAI structured-output schema for editable design compositions.
const Map<String, dynamic> editorAiCompositionJsonSchema = {
  'type': 'object',
  'additionalProperties': false,
  'properties': {
    'elements': {
      'type': 'array',
      'minItems': 1,
      'maxItems': EditorAiComposition.maxElements,
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'properties': {
          'type': {
            'type': 'string',
            'enum': ['text', 'image', 'icon', 'shape'],
          },
          'x': {'type': 'number', 'minimum': 0, 'maximum': 1},
          'y': {'type': 'number', 'minimum': 0, 'maximum': 1},
          'width': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 1},
          'height': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 1},
          'zIndex': {'type': 'integer', 'minimum': 0, 'maximum': 100},
          'text': {
            'type': ['string', 'null'],
            'maxLength': 500,
          },
          'fontSize': {
            'type': ['number', 'null'],
            'minimum': 0.012,
            'maximum': 0.25,
          },
          'fontWeight': {
            'type': ['integer', 'null'],
            'minimum': 100,
            'maximum': 900,
          },
          'align': {
            'type': ['string', 'null'],
            'enum': ['left', 'center', 'right', null],
          },
          'color': {
            'type': ['string', 'null'],
            'pattern': '^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?\$',
          },
          'backgroundColor': {
            'type': ['string', 'null'],
            'pattern': '^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?\$',
          },
          'assetId': {
            'type': ['string', 'null'],
            'maxLength': 80,
          },
          'prompt': {
            'type': ['string', 'null'],
            'maxLength': 1000,
          },
          'clip': {
            'type': ['string', 'null'],
            'enum': ['none', 'circle', null],
          },
          'icon': {
            'type': ['string', 'null'],
            'enum': [
              'home',
              'email',
              'user',
              'phone',
              'location',
              'website',
              'calendar',
              'star',
              'check',
              'arrow',
              null,
            ],
          },
          'shape': {
            'type': ['string', 'null'],
            'enum': ['rectangle', 'circle', 'line', null],
          },
          'strokeWidth': {
            'type': ['number', 'null'],
            'minimum': 0.001,
            'maximum': 0.1,
          },
          'fill': {
            'type': ['boolean', 'null'],
          },
        },
        'required': [
          'type',
          'x',
          'y',
          'width',
          'height',
          'zIndex',
          'text',
          'fontSize',
          'fontWeight',
          'align',
          'color',
          'backgroundColor',
          'assetId',
          'prompt',
          'clip',
          'icon',
          'shape',
          'strokeWidth',
          'fill',
        ],
      },
    },
  },
  'required': ['elements'],
};
