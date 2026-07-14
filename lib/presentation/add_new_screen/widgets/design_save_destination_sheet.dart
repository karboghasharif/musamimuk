import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// User choice after export: device gallery, cloud workspace, or system share sheet.
enum DesignSaveDestination {
  gallery,
  workspace,
  share,
}

/// Bottom sheet presented after the editor completes export bytes.
Future<DesignSaveDestination?> showDesignSaveDestinationSheet(
  BuildContext context,
) {
  final t = Theme.of(context);
  return showAppModalBottomSheet<DesignSaveDestination>(
    context: context,
    builder: (ctx) {
      Widget option({
        required IconData icon,
        required String titleKey,
        required DesignSaveDestination dest,
      }) {
        return ListTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(
            titleKey.tr,
            style: t.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () => Navigator.of(ctx).pop(dest),
        );
      }

      return AppDarkSheetTheme(
        child: AppSheetPagePadding(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'msg_choose_save_destination'.tr,
                style: AppDs.sheetTitle(t, color: Colors.white),
              ),
              SizedBox(height: AppDs.space4.v),
              option(
                icon: Icons.photo_library_outlined,
                titleKey: 'lbl_save_to_gallery',
                dest: DesignSaveDestination.gallery,
              ),
              option(
                icon: Icons.cloud_upload_outlined,
                titleKey: 'lbl_save_to_workspace',
                dest: DesignSaveDestination.workspace,
              ),
              option(
                icon: Icons.share_outlined,
                titleKey: 'lbl_share_design',
                dest: DesignSaveDestination.share,
              ),
            ],
          ),
        ),
      );
    },
  );
}
