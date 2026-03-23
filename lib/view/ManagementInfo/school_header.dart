import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SchoolHeader extends StatelessWidget {
  final String schoolName;
  const SchoolHeader({required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C).withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A3A5C), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded,
              color: Color(0xFF1A3A5C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              schoolName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A3A5C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}