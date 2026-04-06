import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimeInfo extends StatelessWidget {
  final String label;
  final String? time;
  final IconData icon;
  final bool alignRight;

  const TimeInfo({
    required this.label,
    required this.time,
    required this.icon,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: alignRight
              ? [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 3),
            Icon(icon, size: 12, color: Colors.grey.shade500),
          ]
              : [
            Icon(icon, size: 12, color: Colors.grey.shade500),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        Text(
          time != null ? time!.trim() : '—',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}