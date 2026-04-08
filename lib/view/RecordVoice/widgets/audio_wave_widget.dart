import 'package:flutter/material.dart';


class AudioWaveWidget extends StatelessWidget {
  final double progress;
  const AudioWaveWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    const totalBars = 40;

    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalBars, (index) {
          final isPlayed = index < (totalBars * progress);

          final heightFactor = (index % 5 == 0)
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