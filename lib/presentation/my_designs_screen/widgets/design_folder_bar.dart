import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/design_folder.dart';
import '../../../data/services/design_folder_store.dart';
import '../bloc/screen_18_my_designs_bloc.dart';

/// Horizontal folder chips: All · Unfiled · user folders + manage actions.
class DesignFolderBar extends StatelessWidget {
  const DesignFolderBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Screen18MyDesignsBloc, Screen18MyDesignsState>(
      buildWhen: (prev, next) =>
          prev.folders != next.folders ||
          prev.selectedFolderId != next.selectedFolderId,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44.v,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FolderChip(
                    label: 'lbl_folder_all'.tr,
                    selected: state.selectedFolderId == null,
                    onTap: () => context.read<Screen18MyDesignsBloc>().add(
                          Screen18MyDesignsSelectFolderEvent(null),
                        ),
                  ),
                  SizedBox(width: 8.h),
                  _FolderChip(
                    label: 'lbl_folder_unfiled'.tr,
                    selected:
                        state.selectedFolderId == DesignFolderStore.unfiledId,
                    onTap: () => context.read<Screen18MyDesignsBloc>().add(
                          Screen18MyDesignsSelectFolderEvent(
                            DesignFolderStore.unfiledId,
                          ),
                        ),
                  ),
                  for (final folder in state.folders) ...[
                    SizedBox(width: 8.h),
                    _FolderChip(
                      label: folder.name,
                      selected: state.selectedFolderId == folder.id,
                      onTap: () => context.read<Screen18MyDesignsBloc>().add(
                            Screen18MyDesignsSelectFolderEvent(folder.id),
                          ),
                      onLongPress: () =>
                          _showFolderActions(context, folder),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 8.v),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: state.folders.length >= DesignFolderStore.maxFolders
                    ? null
                    : () => _promptCreateFolder(context),
                icon: const Icon(Icons.create_new_folder_outlined, size: 20),
                label: Text('lbl_folder_create'.tr),
                style: TextButton.styleFrom(
                  minimumSize: Size(48.h, 44.v),
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptCreateFolder(BuildContext context) async {
    final name = await _promptFolderName(
      context,
      title: 'lbl_folder_create'.tr,
    );
    if (name == null || !context.mounted) return;
    context.read<Screen18MyDesignsBloc>().add(
          Screen18MyDesignsCreateFolderEvent(name),
        );
  }

  Future<void> _showFolderActions(
    BuildContext context,
    DesignFolder folder,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppDs.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.h)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text('lbl_folder_rename'.tr),
                minVerticalPadding: 16,
                onTap: () => Navigator.of(ctx).pop('rename'),
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'lbl_folder_delete'.tr,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                minVerticalPadding: 16,
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || action == null) return;
    if (action == 'rename') {
      final name = await _promptFolderName(
        context,
        title: 'lbl_folder_rename'.tr,
        initial: folder.name,
      );
      if (name == null || !context.mounted) return;
      context.read<Screen18MyDesignsBloc>().add(
            Screen18MyDesignsRenameFolderEvent(
              folderId: folder.id,
              name: name,
            ),
          );
      return;
    }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('lbl_folder_delete'.tr),
          content: Text('msg_folder_delete_warning'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('lbl_cancel'.tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text('lbl_delete'.tr),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      context.read<Screen18MyDesignsBloc>().add(
            Screen18MyDesignsDeleteFolderEvent(folder.id),
          );
    }
  }
}

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Material(
      color: selected
          ? primary.withValues(alpha: 0.22)
          : AppDs.surfaceElevated,
      borderRadius: BorderRadius.circular(20.h),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20.h),
        child: Container(
          constraints: BoxConstraints(minHeight: 40.v, minWidth: 48.h),
          padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 8.v),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.h),
            border: Border.all(
              color: selected
                  ? primary.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primary : AppDs.textOnDarkSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13.fSize,
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _promptFolderName(
  BuildContext context, {
  required String title,
  String? initial,
}) async {
  // Own the controller inside the dialog route so dispose waits for the
  // exit animation (disposing right after pop races TextField listeners).
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => _FolderNameDialog(title: title, initial: initial),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({
    required this.title,
    this.initial,
  });

  final String title;
  final String? initial;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: DesignFolderStore.maxNameLength,
        decoration: InputDecoration(
          hintText: 'lbl_folder_name_hint'.tr,
          counterText: '',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('lbl_cancel'.tr),
        ),
        TextButton(
          onPressed: _submit,
          child: Text('lbl_save'.tr),
        ),
      ],
    );
  }
}

/// Bottom sheet to move a design into a folder / Unfiled.
Future<void> showMoveDesignFolderSheet({
  required BuildContext context,
  required String designId,
  required bool isLocal,
  String? currentFolderId,
}) async {
  final bloc = context.read<Screen18MyDesignsBloc>();
  final folders = bloc.state.folders;
  final chosen = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppDs.surfaceElevated,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.h)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 16.v, 16.h, 8.v),
              child: Text(
                'lbl_folder_move_to'.tr,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: Icon(
                currentFolderId == null
                    ? Icons.check_circle
                    : Icons.folder_off_outlined,
              ),
              title: Text('lbl_folder_unfiled'.tr),
              minVerticalPadding: 16,
              onTap: () => Navigator.of(ctx).pop(DesignFolderStore.unfiledId),
            ),
            for (final folder in folders)
              ListTile(
                leading: Icon(
                  currentFolderId == folder.id
                      ? Icons.check_circle
                      : Icons.folder_outlined,
                ),
                title: Text(folder.name),
                minVerticalPadding: 16,
                onTap: () => Navigator.of(ctx).pop(folder.id),
              ),
          ],
        ),
      );
    },
  );
  if (chosen == null || !context.mounted) return;
  bloc.add(
    Screen18MyDesignsMoveDesignEvent(
      designId: designId,
      isLocal: isLocal,
      folderId: chosen == DesignFolderStore.unfiledId ? null : chosen,
    ),
  );
}
