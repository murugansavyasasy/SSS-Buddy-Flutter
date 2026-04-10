import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1A3A5C);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: teal),
        ),
        const SizedBox(width: 8),

        Text(
          '$label :',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            softWrap: true,
            maxLines: null,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              height: 1.4, // ✅ better readability
            ),
          ),
        ),
      ],
    );
  }
}