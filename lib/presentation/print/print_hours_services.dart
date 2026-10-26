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

class PrintHoursEditor extends StatelessWidget {
  const PrintHoursEditor({
    super.key,
    required this.open,
    required this.close,
    required this.days,
    required this.onOpenChanged,
    required this.onCloseChanged,
    required this.onDaysChanged,
  });

  final String open;
  final String close;
  final Set<int> days;
  final ValueChanged<String> onOpenChanged;
  final ValueChanged<String> onCloseChanged;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lbl_print_hours'.tr,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.v),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(
                  context: context,
                  current: open,
                  onPicked: onOpenChanged,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                  side: const BorderSide(color: Colors.white24),
                ),
                child: Text(
                  '${'lbl_print_opens'.tr}: $open',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 8.h),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickTime(
                  context: context,
                  current: close,
                  onPicked: onCloseChanged,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                  side: const BorderSide(color: Colors.white24),
                ),
                child: Text(
                  '${'lbl_print_closes'.tr}: $close',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.v),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
              selectedColor: AppDs.printGold,
              labelStyle: TextStyle(
                color: selected ? Colors.black : Colors.white,
              ),
              backgroundColor: AppDs.surfaceRaised,
            );
          }),
        ),
      ],
    );
  }
}

class PrintServicesChips extends StatelessWidget {
  const PrintServicesChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'lbl_print_services'.tr,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.v),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: printShopServiceOptions.map((service) {
            final active = selected.contains(service);
            return FilterChip(
              label: Text(service.replaceAll('_', ' ')),
              selected: active,
              onSelected: (value) {
                final next = {...selected};
                if (value) {
                  next.add(service);
                } else {
                  next.remove(service);
                }
                onChanged(next);
              },
              selectedColor: AppDs.printGold,
              labelStyle: TextStyle(
                color: active ? Colors.black : Colors.white,
              ),
              backgroundColor: AppDs.surfaceRaised,
            );
          }).toList(),
        ),
      ],
    );
  }
}
