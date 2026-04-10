import 'package:flutter/material.dart';
import 'audio_wave_widget.dart';

class PlaybackCardWidget extends StatelessWidget {
  final bool isPlaying;
  final double progress;
  final Duration position;
  final Duration totalDuration;
  final VoidCallback onTogglePlay;

  const PlaybackCardWidget({
    super.key,
    required this.isPlaying,
    required this.progress,
    required this.position,
    required this.totalDuration,
    required this.onTogglePlay,
  });

  String _formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Guard: shows "--:--" placeholders until duration is loaded
    final hasTotal = totalDuration > Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          // ── Play / Pause button ──────────────────────────────────────────
          GestureDetector(
            onTap: onTogglePlay,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  key: ValueKey(isPlaying),
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // ── Waveform ─────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: AudioWaveWidget(progress: progress),
          ),

          const SizedBox(width: 8),

          // ── Time display ─────────────────────────────────────────────────
          // ✅ Fixed width prevents overflow into waveform area
          SizedBox(
            width: 90,
            child: Text(
              hasTotal
                  ? "${_formatTime(position)} / ${_formatTime(totalDuration)}"
                  : "--:-- / --:--",
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),

        ],
      ),
    );
  }
}
