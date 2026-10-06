import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Values/Colors/app_colors.dart';

/// A styled dropdown that lets the user pick a month to filter trips by.
/// Each entry is a first-of-month [DateTime] (day = 1, time = 00:00).
class MonthDropdown extends StatelessWidget {
  final List<DateTime> months;
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;

  const MonthDropdown({
    super.key,
    required this.months,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          isExpanded: true,
          isDense: true,
          hint: const Text(
            'Select Month',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          value: selected,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: months
              .map(
                (m) => DropdownMenuItem<DateTime>(
                  value: m,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM yyyy').format(m),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
