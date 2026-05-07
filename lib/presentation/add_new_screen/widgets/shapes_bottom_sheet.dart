import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../../../data/repositories/media_repository.dart';
import 'api_asset_bottom_sheet.dart';

/// Bottom sheet for selecting shapes from API (GET /api/shape/list).
/// Matches reference: search bar, category tabs, sections by category with "See all", items with file_url.
class ShapesBottomSheet extends StatefulWidget {
  const ShapesBottomSheet({
    super.key,
    required this.editorKey,
  });

  final GlobalKey<ProImageEditorState>? editorKey;

  @override
  State<ShapesBottomSheet> createState() => _ShapesBottomSheetState();
}

class _ShapesBottomSheetState extends State<ShapesBottomSheet> {
  @override
  Widget build(BuildContext context) {
    // Keep this widget for backwards compatibility with current call sites.
    // Internally we use the shared API asset picker.
    return ApiAssetBottomSheet(editorKey: widget.editorKey, type: MediaType.shape);
  }
}
