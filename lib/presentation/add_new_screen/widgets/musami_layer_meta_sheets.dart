import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../core/design_system/app_bottom_sheet.dart';
import '../../../core/design_system/app_design_tokens.dart';
import '../../../localization/app_localization.dart';

/// Optional hyperlink attached to a layer by the user.
///
/// Editor-only metadata: it is never opened while editing and never painted on
/// the canvas.
const String kMusamiLayerLinkMetaKey = 'musamiLayerLink';

/// Accessibility description of an image layer. Stored separately from any
/// visible title and never painted on the canvas.
const String kMusamiLayerAltTextMetaKey = 'musamiLayerAltText';

String? musamiLayerLink(Layer layer) =>
    _trimmedMeta(layer, kMusamiLayerLinkMetaKey);

String? musamiLayerAltText(Layer layer) =>
    _trimmedMeta(layer, kMusamiLayerAltTextMetaKey);

String? _trimmedMeta(Layer layer, String key) {
  final raw = layer.meta?[key]?.toString().trim();
  return (raw == null || raw.isEmpty) ? null : raw;
}

/// Outcome of a metadata editing sheet.
enum MusamiLayerMetaResult { saved, removed, cancelled }

/// What the user did in a metadata sheet, plus the value to persist.
class MusamiLayerMetaEdit {
  const MusamiLayerMetaEdit(this.result, this.value);

  final MusamiLayerMetaResult result;

  /// Trimmed input; only meaningful for [MusamiLayerMetaResult.saved].
  final String value;
}

/// Sheet for attaching / editing / removing a layer hyperlink.
Future<MusamiLayerMetaEdit> showMusamiLayerLinkSheet({
  required BuildContext context,
  required String? initialValue,
}) {
  return _showMetaTextSheet(
    context: context,
    title: 'lbl_layer_menu_link'.tr,
    hint: 'https://example.com',
    helper: 'msg_layer_link_hint'.tr,
    initialValue: initialValue,
    keyboardType: TextInputType.url,
    maxLines: 1,
    validate: _validateUrl,
  );
}

/// Sheet for editing the alternative text of an image layer.
Future<MusamiLayerMetaEdit> showMusamiLayerAltTextSheet({
  required BuildContext context,
  required String? initialValue,
}) {
  return _showMetaTextSheet(
    context: context,
    title: 'lbl_layer_menu_alt_text'.tr,
    hint: 'lbl_layer_alt_text_hint'.tr,
    helper: 'msg_layer_alt_text_hint'.tr,
    initialValue: initialValue,
    keyboardType: TextInputType.multiline,
    maxLines: 3,
    validate: (_) => null,
  );
}

/// Accepts an http(s) URL, optionally without the scheme.
String? _validateUrl(String value) {
  final candidate = value.contains('://') ? value : 'https://$value';
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
    return 'msg_layer_link_invalid'.tr;
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    return 'msg_layer_link_invalid'.tr;
  }
  return null;
}

/// Normalises user input into a storable URL (adds the missing scheme).
String musamiNormalizeLayerLink(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed.contains('://') ? trimmed : 'https://$trimmed';
}

Future<MusamiLayerMetaEdit> _showMetaTextSheet({
  required BuildContext context,
  required String title,
  required String hint,
  required String helper,
  required String? initialValue,
  required TextInputType keyboardType,
  required int maxLines,
  required String? Function(String value) validate,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final result = await showAppModalBottomSheet<MusamiLayerMetaResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => AppDarkSheetTheme(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: AppSheetPagePadding(
          child: _MetaTextForm(
            title: title,
            hint: hint,
            helper: helper,
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validate: validate,
            hasExistingValue: (initialValue ?? '').trim().isNotEmpty,
          ),
        ),
      ),
    ),
  );
  final value = controller.text.trim();
  controller.dispose();
  return MusamiLayerMetaEdit(result ?? MusamiLayerMetaResult.cancelled, value);
}

class _MetaTextForm extends StatefulWidget {
  const _MetaTextForm({
    required this.title,
    required this.hint,
    required this.helper,
    required this.controller,
    required this.keyboardType,
    required this.maxLines,
    required this.validate,
    required this.hasExistingValue,
  });

  final String title;
  final String hint;
  final String helper;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final int maxLines;
  final String? Function(String value) validate;
  final bool hasExistingValue;

  @override
  State<_MetaTextForm> createState() => _MetaTextFormState();
}

class _MetaTextFormState extends State<_MetaTextForm> {
  String? _error;

  void _save() {
    final value = widget.controller.text.trim();
    if (value.isEmpty) {
      Navigator.of(context).pop(MusamiLayerMetaResult.removed);
      return;
    }
    final error = widget.validate(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(MusamiLayerMetaResult.saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMultiline = widget.maxLines > 1;
    final keyboardType = isMultiline && widget.keyboardType == TextInputType.text
        ? TextInputType.multiline
        : widget.keyboardType;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title,
          style: AppDs.sheetTitle(theme, color: AppDs.textOnDarkPrimary),
        ),
        const SizedBox(height: AppDs.space2),
        Text(
          widget.helper,
          style: AppDs.sheetCaption(theme, color: AppDs.textOnDarkSecondary),
        ),
        const SizedBox(height: AppDs.space4),
        TextField(
          controller: widget.controller,
          keyboardType: keyboardType,
          maxLines: widget.maxLines,
          autofocus: true,
          textInputAction: isMultiline
              ? TextInputAction.newline
              : TextInputAction.done,
          onSubmitted: isMultiline ? null : (_) => _save(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          style: AppDs.sheetBody(theme, color: AppDs.textOnDarkPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: _error,
            filled: true,
            fillColor: AppDs.surfaceRaised,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDs.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppDs.space4),
        Row(
          children: [
            if (widget.hasExistingValue)
              Expanded(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pop(MusamiLayerMetaResult.removed),
                  child: Text(
                    'lbl_remove'.tr,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            if (widget.hasExistingValue) const SizedBox(width: AppDs.space3),
            Expanded(
              child: FilledButton(onPressed: _save, child: Text('lbl_save'.tr)),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single `label: value` line of the layer info sheet.
class MusamiLayerInfoEntry {
  const MusamiLayerInfoEntry(this.label, this.value);

  final String label;
  final String value;
}

/// Read-only sheet describing the selected layer.
Future<void> showMusamiLayerInfoSheet({
  required BuildContext context,
  required List<MusamiLayerInfoEntry> entries,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final maxListHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'lbl_layer_menu_info'.tr,
                style: AppDs.sheetTitle(theme, color: AppDs.textOnDarkPrimary),
              ),
              const SizedBox(height: AppDs.space4),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppDs.space3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                entry.label,
                                style: AppDs.sheetCaption(
                                  theme,
                                  color: AppDs.textOnDarkSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDs.space3),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppDs.sheetBody(
                                  theme,
                                  color: AppDs.textOnDarkPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
