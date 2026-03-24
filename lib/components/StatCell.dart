import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ShimmerBox.dart';

class StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isLoading;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const StatCell({
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
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
