import 'package:flutter/cupertino.dart';

import '../Values/Colors/app_colors.dart';

import 'package:flutter/material.dart';
import '../Values/Colors/app_colors.dart';

class InfoTileLocal extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
  final List<Color>? accentGradient;

  const InfoTileLocal({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.accentGradient,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentGradient?.first ?? Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight ? accent.withOpacity(0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? accent.withOpacity(0.18)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: highlight
                  ? accent.withOpacity(0.12)
                  : const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 14,
              color: highlight ? accent : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ✅
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: highlight ? accent : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}