import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ShimmerBox.dart';

class StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final Color valueColor;

  const StatCell({
    this.valueColor = const Color(0xFF111827),
    required this.label,
    required this.value,
    required this.isLoading,
    required this.fadeAnim,
    required this.slideAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        isLoading
            ? ShimmerBox(width: 40, height: 28)
            : SlideTransition(
          position: slideAnim,
          child: FadeTransition(
            opacity: fadeAnim,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                height: 1.05,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
