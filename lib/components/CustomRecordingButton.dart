import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomRecordingButton extends StatelessWidget {
  const CustomRecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
  });

  final bool isRecording;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          height: 110,
          width: 110,
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.all(isRecording ? 25 : 15),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: isRecording ? 8 : 3),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            ),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(50),
              child: Center(
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            isRecording ? "Tap to Stop" : "Tap to Record",
            key: ValueKey(isRecording),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
