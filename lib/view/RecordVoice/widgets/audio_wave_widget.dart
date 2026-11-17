import 'package:flutter/material.dart';

class AudioWaveWidget extends StatelessWidget {
  final double progress;
  const AudioWaveWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    const totalBars = 30;

    // 30 bars need 120 dp; scale them down when the card is narrower
    // (small phones) instead of overflowing.
    return SizedBox(
      height: 28,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalBars, (index) {
          final isPlayed = index < (totalBars * progress);

          final heightFactor = (index % 5 == 0)
              ? 0.85
              : (index % 3 == 0)
              ? 0.60
              : 0.35;

          return Container(
            width: 2,
            height: 28 * heightFactor,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isPlayed ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
      ),
    );
  }
}
