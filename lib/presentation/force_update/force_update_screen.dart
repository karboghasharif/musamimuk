import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../core/utils/app_toast.dart';
import '../../data/repositories/app_version_repository.dart';

/// Full-screen, non-dismissible gate when the installed build is below
/// the server minimum (`GET /public/app-version`).
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({
    super.key,
    required this.decision,
  });

  final AppVersionGateDecision decision;

  Future<void> _openStore(BuildContext context) async {
    final raw = decision.storeUrl.trim();
    if (raw.isEmpty) {
      showAppToast('msg_update_store_unavailable'.tr);
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      showAppToast('msg_update_store_unavailable'.tr);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showAppToast('msg_update_store_unavailable'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final buildHint = 'lbl_update_build_hint'.tr
        .replaceAll('{current}', '${decision.currentBuild}')
        .replaceAll('{required}', '${decision.minBuild}');

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppDs.surfaceBase,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.h, vertical: 24.v),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.system_update_alt_rounded,
                  size: 72.adaptSize,
                  color: cs.primary,
                ),
                SizedBox(height: 24.v),
                Text(
                  'lbl_update_required_title'.tr,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.v),
                Text(
                  decision.message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                if (decision.minBuild > 0) ...[
                  SizedBox(height: 16.v),
                  Text(
                    buildHint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openStore(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 14.v),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.adaptSize),
                      ),
                    ),
                    child: Text(
                      'lbl_update_now'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12.v),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: Text(
                    'lbl_exit_app'.tr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
