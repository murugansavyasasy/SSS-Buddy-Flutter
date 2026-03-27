import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DescriptionRow extends StatelessWidget {
  final String description;
  const DescriptionRow({required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded,
            size: 14, color: Color(0xFFCBD5E1)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}