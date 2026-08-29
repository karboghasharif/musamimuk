import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// App-side RTL/LTR helpers for pub.dev [TextEditorState] (no built-in
/// inputTextDirection API like the local fork had).
extension MusamiTextEditorScript on TextEditorState {
  bool get isMusamiRtl => align == TextAlign.right || align == TextAlign.end;

  void setMusamiScriptDirection(TextDirection direction) {
    setState(() {
      align = direction == TextDirection.rtl ? TextAlign.right : TextAlign.left;
    });
  }
}
