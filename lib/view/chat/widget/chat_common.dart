import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Values/Colors/app_colors.dart';

const _avatarColors = [
  Color(0xFF4F6693),
  Color(0xFF2E7D6B),
  Color(0xFFB5651D),
  Color(0xFF7B5EA7),
  Color(0xFFC0475A),
  Color(0xFF2C7DA0),
];

String chatInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
}

class ChatAvatar extends StatelessWidget {
  final String name;
  final bool isGroup;
  final double size;

  const ChatAvatar({
    super.key,
    required this.name,
    this.isGroup = false,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGroup
        ? AppColors.secondaryprimary
        : _avatarColors[name.hashCode.abs() % _avatarColors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isGroup
          ? Icon(Icons.groups_rounded, color: color, size: size * 0.5)
          : Text(
              chatInitials(name),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
    );
  }
}

class UnreadBadge extends StatelessWidget {
  final int count;

  const UnreadBadge({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF25A35A),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "10:42 AM" today, "Yesterday", weekday within a week, else date.
String chatListTime(int ms) {
  if (ms == 0) return '';
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  if (_sameDay(t, now)) return DateFormat('h:mm a').format(t);
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  if (now.difference(t).inDays < 7) return DateFormat('EEE').format(t);
  return DateFormat('dd/MM/yy').format(t);
}

String chatDayLabel(DateTime t) {
  final now = DateTime.now();
  if (_sameDay(t, now)) return 'Today';
  if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  return DateFormat('d MMMM yyyy').format(t);
}

bool chatIsSameDay(DateTime a, DateTime b) => _sameDay(a, b);

String formatDuration(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(1, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

String formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
