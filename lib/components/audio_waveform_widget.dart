import 'package:flutter/material.dart';

class AudioWaveformWidget extends StatelessWidget {
  final int totalBars;
  final double progress; // 0.0 → 1.0

  const AudioWaveformWidget({
    super.key,
    this.totalBars = 40,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: List.generate(totalBars, (index) {
          final isPlayed = index < (totalBars * progress);

          // 🔥 Create center wave effect
          double heightFactor = (index % 5 == 0)
              ? 1.0
              : (index % 3 == 0)
              ? 0.7
              : 0.4;

          return Container(
            width: 3,
            height: 30 * heightFactor,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isPlayed ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}