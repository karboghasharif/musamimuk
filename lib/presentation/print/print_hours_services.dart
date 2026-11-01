import 'package:flutter/material.dart';

import '../../core/app_export.dart';

const printShopServiceOptions = [
  'digital',
  'offset',
  'large_format',
  'business_cards',
  'banners',
  'stickers',
  'packaging',
  'finishing',
];

const printDayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// One open→close window (e.g. morning or evening shift).
class PrintHourShift {
  const PrintHourShift({
    required this.open,
    required this.close,
  });

  final String open;
  final String close;

  PrintHourShift copyWith({String? open, String? close}) {
    return PrintHourShift(
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }

  Map<String, String> toJson() => {'open': open, 'close': close};

  factory PrintHourShift.fromJson(Map<String, dynamic> json) {
    return PrintHourShift(
      open: json['open']?.toString() ?? '09:00',
      close: json['close']?.toString() ?? '13:00',
    );
  }
}

/// Build API `hours` payload — keeps legacy `open`/`close` + `shifts` for multi-window.
Map<String, dynamic> printHoursPayload({
  required List<PrintHourShift> shifts,
  required Set<int> days,
}) {
  final cleaned = shifts.isEmpty
      ? [const PrintHourShift(open: '09:00', close: '22:00')]
      : shifts;
  return {
    'open': cleaned.first.open,
    'close': cleaned.first.close,
    'days': (days.toList()..sort()),
    'shifts': cleaned.map((s) => s.toJson()).toList(),
  };
}

class PrintHoursEditor extends StatelessWidget {
  const PrintHoursEditor({
    super.key,
    required this.shifts,
    required this.days,
    required this.onShiftsChanged,
    required this.onDaysChanged,
  });

  final List<PrintHourShift> shifts;
  final Set<int> days;
  final ValueChanged<List<PrintHourShift>> onShiftsChanged;
  final ValueChanged<Set<int>> onDaysChanged;

  Future<void> _pickTime({
    required BuildContext context,
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onPicked('$hh:$mm');
  }

  void _updateShift(int index, PrintHourShift next) {
    final list = [...shifts];
    list[index] = next;
    onShiftsChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'lbl_print_hours'.tr,
                variant: AppTextVariant.caption,
              ),
            ),
            if (shifts.length < 2)
              TextButton.icon(
                onPressed: () {
                  onShiftsChanged([
                    ...shifts,
                    const PrintHourShift(open: '16:00', close: '22:00'),
                  ]);
                },
                icon: Icon(
                  Icons.add_rounded,
                  size: AppDs.iconSm.adaptSize,
                  color: AppDs.accentYellow,
                ),
                label: AppText(
                  'lbl_print_add_shift'.tr,
                  variant: AppTextVariant.accent,
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size(AppDs.minTap, AppDs.minTap),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        SizedBox(height: AppDs.space2.v),
        AppText(
          'msg_print_hours_shifts_hint'.tr,
          variant: AppTextVariant.caption,
          color: AppDs.textOnDarkSecondary,
        ),
        SizedBox(height: AppDs.space3.v),
        for (var i = 0; i < shifts.length; i++) ...[
          if (i > 0) SizedBox(height: AppDs.space3.v),
          Container(
            padding: EdgeInsets.all(AppDs.space3.h),
            decoration: BoxDecoration(
              color: AppDs.surfaceRaised,
              borderRadius: BorderRadius.circular(AppDs.radiusMd),
              border: Border.all(color: AppDs.atelierHairline(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shifts.length == 1
                            ? 'lbl_print_shift_hours'.tr
                            : 'lbl_print_shift_n'
                                .tr
                                .replaceAll('{n}', '${i + 1}'),
                        style: AppTypography.secondary(theme).copyWith(
                          color: AppDs.atelierBrass,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (shifts.length > 1)
                      IconButton(
                        tooltip: 'lbl_print_remove_shift'.tr,
                        onPressed: () {
                          final next = [...shifts]..removeAt(i);
                          onShiftsChanged(next);
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppDs.textOnDarkSecondary,
                          size: AppDs.iconMd.adaptSize,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: AppDs.space2.v),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(
                          context: context,
                          current: shifts[i].open,
                          onPicked: (v) =>
                              _updateShift(i, shifts[i].copyWith(open: v)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, AppDs.buttonHeight.v),
                          side: BorderSide(color: AppDs.atelierHairline(0.2)),
                        ),
                        child: Text(
                          '${'lbl_print_opens'.tr}: ${shifts[i].open}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDs.space2.h),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickTime(
                          context: context,
                          current: shifts[i].close,
                          onPicked: (v) =>
                              _updateShift(i, shifts[i].copyWith(close: v)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, AppDs.buttonHeight.v),
                          side: BorderSide(color: AppDs.atelierHairline(0.2)),
                        ),
                        child: Text(
                          '${'lbl_print_closes'.tr}: ${shifts[i].close}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: AppDs.space3.v),
        AppText(
          'lbl_print_open_days'.tr,
          variant: AppTextVariant.caption,
        ),
        SizedBox(height: AppDs.space2.v),
        Wrap(
          spacing: AppDs.space2.h,
          runSpacing: AppDs.space2.v,
          children: List.generate(7, (day) {
            final selected = days.contains(day);
            return FilterChip(
              label: Text(printDayLabels[day]),
              selected: selected,
              onSelected: (value) {
                final next = {...days};
                if (value) {
                  next.add(day);
                } else {
                  next.remove(day);
                }
                if (next.isEmpty) next.add(day);
                onDaysChanged(next);
              },
              selectedColor: AppDs.accentYellow,
              checkmarkColor: AppDs.onAccent,
              labelStyle: TextStyle(
                color: selected ? AppDs.onAccent : AppDs.textOnDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppDs.surfaceRaised,
              side: BorderSide(
                color: selected
                    ? AppDs.accentYellow
                    : AppDs.atelierHairline(0.16),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PrintServicesChips extends StatefulWidget {
  const PrintServicesChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<PrintServicesChips> createState() => _PrintServicesChipsState();
}

class _PrintServicesChipsState extends State<PrintServicesChips> {
  final _custom = TextEditingController();
  final Set<String> _extraOptions = {};

  @override
  void initState() {
    super.initState();
    _extraOptions.addAll(
      widget.selected.where((s) => !printShopServiceOptions.contains(s)),
    );
  }

  @override
  void didUpdateWidget(covariant PrintServicesChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    _extraOptions.addAll(
      widget.selected.where((s) => !printShopServiceOptions.contains(s)),
    );
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _toggle(String service, bool value) {
    final next = {...widget.selected};
    if (value) {
      next.add(service);
    } else {
      next.remove(service);
    }
    widget.onChanged(next);
  }

  void _addCustom() {
    final raw = _custom.text.trim().toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '_',
        );
    final cleaned = raw.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
    if (cleaned.length < 2) {
      return;
    }
    setState(() => _extraOptions.add(cleaned));
    widget.onChanged({...widget.selected, cleaned});
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    final extras = _extraOptions.toList()..sort();
    final allOptions = [
      ...printShopServiceOptions,
      ...extras,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          'lbl_print_services'.tr,
          variant: AppTextVariant.caption,
        ),
        SizedBox(height: AppDs.space2.v),
        Wrap(
          spacing: AppDs.space2.h,
          runSpacing: AppDs.space2.v,
          children: allOptions.map((service) {
            final active = widget.selected.contains(service);
            final isCustom = !printShopServiceOptions.contains(service);
            return FilterChip(
              label: Text(service.replaceAll('_', ' ')),
              selected: active,
              onSelected: (value) => _toggle(service, value),
              selectedColor: AppDs.accentYellow,
              checkmarkColor: AppDs.onAccent,
              deleteIcon: isCustom
                  ? Icon(
                      Icons.close_rounded,
                      size: 16.adaptSize,
                      color: active ? AppDs.onAccent : AppDs.textOnDarkSecondary,
                    )
                  : null,
              onDeleted: isCustom
                  ? () {
                      setState(() => _extraOptions.remove(service));
                      final next = {...widget.selected}..remove(service);
                      widget.onChanged(next);
                    }
                  : null,
              labelStyle: TextStyle(
                color: active ? AppDs.onAccent : AppDs.textOnDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppDs.surfaceRaised,
              side: BorderSide(
                color: active
                    ? AppDs.accentYellow
                    : AppDs.atelierHairline(0.16),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppDs.space3.v),
        AppText(
          'msg_print_add_custom_service_hint'.tr,
          variant: AppTextVariant.caption,
        ),
        SizedBox(height: AppDs.space2.v),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custom,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustom(),
                style: AppTypography.body(Theme.of(context)),
                decoration: InputDecoration(
                  hintText: 'lbl_print_custom_service_hint'.tr,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDs.space3.h,
                    vertical: AppDs.space3.v,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppDs.space2.h),
            SizedBox(
              height: AppDs.buttonHeight.v,
              child: FilledButton(
                onPressed: _addCustom,
                style: FilledButton.styleFrom(
                  backgroundColor: AppDs.accentYellow,
                  foregroundColor: AppDs.onAccent,
                  minimumSize: Size(AppDs.minTap.h, AppDs.buttonHeight.v),
                ),
                child: Text('lbl_print_add_service'.tr),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
