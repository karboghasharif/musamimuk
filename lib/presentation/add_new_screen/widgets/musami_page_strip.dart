import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../data/models/musami_document.dart';
import '../utils/musami_document_controller.dart';

/// Compact horizontal page strip for multipage editor sessions.
class MusamiPageStrip extends StatelessWidget {
  const MusamiPageStrip({
    super.key,
    required this.controller,
    required this.onSelectPage,
    required this.onAddPage,
    required this.onDuplicatePage,
    required this.onDeletePage,
    required this.onMoveLeft,
    required this.onMoveRight,
  });

  final MusamiDocumentController controller;
  final ValueChanged<String> onSelectPage;
  final VoidCallback onAddPage;
  final VoidCallback onDuplicatePage;
  final VoidCallback onDeletePage;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final pages = controller.pages;
        final activeId = controller.activePageId;
        final busy = controller.isBusy;
        final canAdd = pages.length < kMusamiDocumentMaxPages;
        final canDelete = pages.length > 1;
        final activeIndex = controller.document.activeIndex;

        return Material(
          color: AppDs.surfaceElevated.withValues(alpha: 0.96),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              height: 64.v,
              child: Row(
                children: [
                  SizedBox(width: 8.h),
                  Text(
                    'lbl_pages'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.fSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8.h),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pages.length,
                      separatorBuilder: (_, _) => SizedBox(width: 6.h),
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        final selected = page.id == activeId;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: 'lbl_page_n'.tr.replaceAll(
                            '{n}',
                            '${index + 1}',
                          ),
                          child: InkWell(
                            onTap: busy
                                ? null
                                : () => onSelectPage(page.id),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: 44.h,
                              height: 52.v,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppDs.accentYellow
                                        .withValues(alpha: 0.22)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? AppDs.accentYellow
                                      : Colors.white.withValues(alpha: 0.18),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: selected
                                      ? AppDs.accentYellow
                                      : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.fSize,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _StripIconButton(
                    tooltip: 'lbl_page_move_left'.tr,
                    icon: Icons.chevron_left,
                    onPressed: busy || activeIndex <= 0
                        ? null
                        : onMoveLeft,
                  ),
                  _StripIconButton(
                    tooltip: 'lbl_page_move_right'.tr,
                    icon: Icons.chevron_right,
                    onPressed: busy || activeIndex >= pages.length - 1
                        ? null
                        : onMoveRight,
                  ),
                  _StripIconButton(
                    tooltip: 'lbl_add_page'.tr,
                    icon: Icons.add,
                    onPressed: busy || !canAdd ? null : onAddPage,
                  ),
                  _StripIconButton(
                    tooltip: 'lbl_duplicate_page'.tr,
                    icon: Icons.copy_outlined,
                    onPressed: busy || !canAdd ? null : onDuplicatePage,
                  ),
                  _StripIconButton(
                    tooltip: 'lbl_delete_page'.tr,
                    icon: Icons.delete_outline,
                    onPressed: busy || !canDelete ? null : onDeletePage,
                  ),
                  SizedBox(width: 4.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StripIconButton extends StatelessWidget {
  const _StripIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40.h,
      height: 40.v,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
          color: onPressed == null
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
