import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ShimmerBox.dart';

class PillStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLoading;
  final Animation<double> fadeAnim;

  const PillStat({
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 7,
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
                        color: Colors.white,
                        fontSize: 13,
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