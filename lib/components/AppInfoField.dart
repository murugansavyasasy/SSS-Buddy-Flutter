import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppInfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? prefixIcon;

  const AppInfoField({
    super.key,
    required this.label,
    required this.value,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 14, color: const Color(0xFF5C6BC0)),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}