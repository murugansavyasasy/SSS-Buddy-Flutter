import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ShimmerBox.dart';

class PillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;
  final Animation<double> fadeAnim;
  final Color accent;

  const PillStat({
    this.accent = const Color(0xFF4F6693),
    required this.icon,
    required this.label,
    required this.value,
    required this.isLoading,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.12), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  isLoading
                      ? ShimmerBox(width: 28, height: 12)
                      : FadeTransition(
                    opacity: fadeAnim,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}