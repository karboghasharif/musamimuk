import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../core/utils/open_design_redesign.dart';

/// Deep-link landing that loads an existing design into the current editor.
class OpenDesignDeepLinkScreen extends StatefulWidget {
  const OpenDesignDeepLinkScreen({super.key, required this.designId});

  final int designId;

  static Widget builder(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    var designId = 0;
    if (args is Map) {
      final raw = args['designId'] ?? args['design_id'];
      if (raw is int) {
        designId = raw;
      } else if (raw is String) {
        designId = int.tryParse(raw) ?? 0;
      }
    }
    return OpenDesignDeepLinkScreen(designId: designId);
  }

  @override
  State<OpenDesignDeepLinkScreen> createState() =>
      _OpenDesignDeepLinkScreenState();
}

class _OpenDesignDeepLinkScreenState extends State<OpenDesignDeepLinkScreen> {
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (!mounted) return;
    if (widget.designId < 1) {
      await NavigatorService.pushNamedAndRemoveUntil(
        AppRoutes.screen18MyDesignsScreen,
        routePredicate: false,
      );
      return;
    }

    await openDesignForRedesign(context, designId: widget.designId);
    if (!mounted) return;
    if (Navigator.of(context).canPop()) return;
    await NavigatorService.pushNamedAndRemoveUntil(
      AppRoutes.screen1HomeScreen,
      routePredicate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF252A30),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
