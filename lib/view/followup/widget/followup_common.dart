import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/FollowUpModel.dart';

const overdueColor = Color(0xFFD64545);
const todayColor = Color(0xFFE08A1E);
const upcomingColor = Color(0xFF4F6693);
const doneColor = Color(0xFF25A35A);

DateTime _at(DateTime day, int hour, [int minute = 0]) =>
    DateTime(day.year, day.month, day.day, hour, minute);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// One-tap time choices used by the form, reschedule and "next follow-up".
List<(String, DateTime)> followUpQuickPicks() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final daysToMonday = (DateTime.monday - now.weekday + 7) % 7;
  final nextMonday = today.add(Duration(days: daysToMonday == 0 ? 7 : daysToMonday));
  final inHour = now.add(const Duration(hours: 1));
  return [
    ('In 1 hour', DateTime(inHour.year, inHour.month, inHour.day, inHour.hour, inHour.minute)),
    if (now.hour < 16) ('Today 5 PM', _at(today, 17)),
    ('Tomorrow 10 AM', _at(tomorrow, 10)),
    ('In 3 days', _at(today.add(const Duration(days: 3)), 10)),
    ('Next Monday', _at(nextMonday, 10)),
  ];
}

Future<DateTime?> pickFollowUpDateTime(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial.isBefore(now) ? now : initial,
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 365)),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String formatDue(DateTime t) {
  final now = DateTime.now();
  final time = DateFormat('h:mm a').format(t);
  if (_sameDay(t, now)) return 'Today, $time';
  if (_sameDay(t, now.add(const Duration(days: 1)))) return 'Tomorrow, $time';
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday, $time';
  if (t.year == now.year) return '${DateFormat('EEE, d MMM').format(t)} · $time';
  return '${DateFormat('d MMM yyyy').format(t)} · $time';
}

/// Short status line for a card, with the colour to show it in.
(String, Color) followUpDueLabel(FollowUp f) {
  if (f.status == FollowUpStatus.done) {
    final at = f.completedAt;
    return (at == null ? 'Done' : 'Done · ${formatDue(at)}', doneColor);
  }
  if (f.isOverdue) {
    final late = DateTime.now().difference(f.dueAt);
    final by = late.inDays >= 1
        ? '${late.inDays}d'
        : late.inHours >= 1
            ? '${late.inHours}h'
            : '${late.inMinutes}m';
    return ('Overdue by $by · ${formatDue(f.dueAt)}', overdueColor);
  }
  if (f.isToday) return (formatDue(f.dueAt), todayColor);
  return (formatDue(f.dueAt), upcomingColor);
}

class QuickPickChips extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime> onPicked;
  final VoidCallback onCustom;

  const QuickPickChips({
    super.key,
    required this.selected,
    required this.onPicked,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final picks = followUpQuickPicks();
    final customSelected =
        selected != null && !picks.any((p) => p.$2 == selected);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in picks)
          ChoiceChip(
            label: Text(p.$1),
            selected: selected == p.$2,
            onSelected: (_) => onPicked(p.$2),
            selectedColor: AppColors.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              fontSize: 12.5,
              color: selected == p.$2 ? AppColors.primary : Colors.black87,
              fontWeight: selected == p.$2 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ActionChip(
          avatar: const Icon(Icons.event_rounded, size: 16),
          label: Text(
            customSelected ? formatDue(selected!) : 'Pick date & time',
            style: TextStyle(
              fontSize: 12.5,
              color: customSelected ? AppColors.primary : Colors.black87,
              fontWeight: customSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          backgroundColor:
              customSelected ? AppColors.primary.withOpacity(0.15) : null,
          onPressed: onCustom,
        ),
      ],
    );
  }
}
