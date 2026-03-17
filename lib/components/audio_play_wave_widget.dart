import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AudioPlayWaveWidget extends StatefulWidget {
  final bool isPlaying;

  const AudioPlayWaveWidget({super.key, required this.isPlaying});

  @override
  State<AudioPlayWaveWidget> createState() => _AudioPlayWaveWidgetState();
}

class _AudioPlayWaveWidgetState extends State<AudioPlayWaveWidget> {
  List<double> _heights = [];
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initBars();
  }

  void _initBars() {
    _heights = List.generate(60, (_) => 0.05); // 👈 full width feel
  }

  @override
  void didUpdateWidget(covariant AudioPlayWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      setState(() {
        for (int i = 0; i < _heights.length; i++) {
          _heights[i] = 0.05 + _random.nextDouble() * 0.25;
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      for (int i = 0; i < _heights.length; i++) {
        _heights[i] = 0.05;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = 3.0;
          final spacing = 2.0;

          final totalBars =
          (constraints.maxWidth / (barWidth + spacing)).floor();

          return Row(
            children: List.generate(totalBars, (index) {
              final height = _heights[index % _heights.length];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: barWidth,
                height: 40 * height,
                margin: EdgeInsets.only(right: spacing),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}