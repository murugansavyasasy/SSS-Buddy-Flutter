import 'package:flutter/material.dart';
import 'audio_wave_widget.dart';

class PlaybackCardWidget extends StatelessWidget {
  final bool isPlaying;
  final double progress;
  final Duration position;
  final VoidCallback onTogglePlay;

  const PlaybackCardWidget({
    super.key,
    required this.isPlaying,
    required this.progress,
    required this.position,
    required this.onTogglePlay,
  });

  String _formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [

          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(child: AudioWaveWidget(progress: progress)),

          const SizedBox(width: 12),


          Text(
            _formatTime(position),
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}