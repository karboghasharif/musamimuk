import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import '../../../core/config/editor_ai_config.dart';
import '../../../core/utils/pref_utils.dart';
import 'editor_ai_command_bar.dart';

/// Draggable host for [MusamiEditorAiExpandableFab] that keeps tap-to-open
/// working while allowing the user to reposition the FAB within safe bounds.
class DraggableEditorAiFab extends StatefulWidget {
  const DraggableEditorAiFab({
    super.key,
    required this.fabKey,
    required this.onOpenMode,
  });

  final GlobalKey<ExpandableFabState> fabKey;
  final ValueChanged<EditorAiGenerationMode> onOpenMode;

  @override
  State<DraggableEditorAiFab> createState() => _DraggableEditorAiFabState();
}

class _DraggableEditorAiFabState extends State<DraggableEditorAiFab> {
  static const double _fabSize = 56;
  static const double _menuClearance = 280;

  Offset? _offset;
  Offset? _dragStartFab;
  Offset? _dragStartGlobal;
  bool _moved = false;

  @override
  void initState() {
    super.initState();
    final saved = PrefUtils().getEditorFabOffset();
    if (saved != null) {
      _offset = saved;
    }
  }

  Offset _defaultOffset(Size size, EdgeInsets padding) {
    return Offset(
      size.width - padding.right - _fabSize - 16,
      size.height - padding.bottom - _fabSize - 88,
    );
  }

  Offset _clamp(Offset raw, Size size, EdgeInsets padding) {
    final minX = padding.left + 8;
    final maxX = size.width - padding.right - _fabSize - 8;
    final minY = padding.top + 72;
    final maxY = size.height - padding.bottom - _fabSize - 72;
    return Offset(
      raw.dx.clamp(minX, maxX > minX ? maxX : minX),
      raw.dy.clamp(minY, maxY > minY ? maxY : minY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;
    final pos = _clamp(
      _offset ?? _defaultOffset(size, padding),
      size,
      padding,
    );

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: _fabSize + 8,
      // Extra height so the upward speed-dial children stay hittable.
      height: _menuClearance,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            _dragStartFab = pos;
            _dragStartGlobal = e.position;
            _moved = false;
          },
          onPointerMove: (e) {
            final startFab = _dragStartFab;
            final startGlobal = _dragStartGlobal;
            if (startFab == null || startGlobal == null) return;
            final delta = e.position - startGlobal;
            if (!_moved && delta.distance < 8) return;
            _moved = true;
            setState(() {
              _offset = _clamp(startFab + delta, size, padding);
            });
          },
          onPointerUp: (_) {
            if (_moved && _offset != null) {
              PrefUtils().setEditorFabOffset(_offset!);
            }
            _dragStartFab = null;
            _dragStartGlobal = null;
            _moved = false;
          },
          onPointerCancel: (_) {
            _dragStartFab = null;
            _dragStartGlobal = null;
            _moved = false;
          },
          child: MusamiEditorAiExpandableFab(
            fabKey: widget.fabKey,
            onOpenMode: widget.onOpenMode,
          ),
        ),
      ),
    );
  }
}
