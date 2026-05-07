import 'package:flutter/material.dart';

/// Inserts [text] at the caret, or replaces the current selection.
void insertTextAtCursor(
  TextEditingController controller,
  String text, {
  FocusNode? focusNode,
}) {
  final value = controller.value;
  final sel = value.selection;
  final s = value.text;
  if (!sel.isValid) {
    final nt = s + text;
    controller.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: nt.length),
    );
  } else {
    final nt = s.replaceRange(sel.start, sel.end, text);
    final off = sel.start + text.length;
    controller.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: off),
    );
  }
  _requestFocusAfterFrame(focusNode);
}

/// Deletes the selection, or one code unit before the caret.
void deleteSelectionOrCharBefore(
  TextEditingController controller, {
  FocusNode? focusNode,
}) {
  final value = controller.value;
  final sel = value.selection;
  final s = value.text;
  if (!sel.isValid) return;
  if (sel.start != sel.end) {
    final nt = s.replaceRange(sel.start, sel.end, '');
    controller.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: sel.start),
    );
  } else {
    final pos = sel.start;
    if (pos <= 0) return;
    final nt = s.replaceRange(pos - 1, pos, '');
    controller.value = TextEditingValue(
      text: nt,
      selection: TextSelection.collapsed(offset: pos - 1),
    );
  }
  _requestFocusAfterFrame(focusNode);
}

void _requestFocusAfterFrame(FocusNode? focusNode) {
  if (focusNode == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (focusNode.canRequestFocus) focusNode.requestFocus();
  });
}
