import 'dart:async';
import 'package:flutter/material.dart';

class CustomRecordingWaveWidget extends StatefulWidget {
  const CustomRecordingWaveWidget({super.key});

  @override
  State<CustomRecordingWaveWidget> createState() => _RecordingWaveWidgetState();
}

class _RecordingWaveWidgetState extends State<CustomRecordingWaveWidget> {

  final List<double> _heights = [
    0.30, 0.50, 0.70, 0.90, 0.60,
    0.40, 0.80, 0.50, 0.30, 0.65,
    0.75, 0.45, 0.90, 0.55, 0.35,
    0.70, 0.50, 0.60, 0.40, 0.30,
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimating();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAnimating() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) {
        setState(() => _heights.add(_heights.removeAt(0)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: screenHeight * 0.08,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _heights.map((h) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 6,
            height: screenHeight * h * 0.08,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(50),
            ),
          );
        }).toList(),
      ),
    );
  }
}
