import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewModel/circular_audio_viewmodel.dart';

/// Bottom-sheet style audio player popup with a seek bar and duration.
///
/// Opens, starts playing [url], and pauses playback when dismissed.
class VoicePlayerDialog extends ConsumerStatefulWidget {
  final String url;
  final String title;
  final Color color;

  const VoicePlayerDialog({
    super.key,
    required this.url,
    required this.title,
    this.color = const Color(0xFF1A3A5C),
  });

  static Future<void> show(
    BuildContext context, {
    required String url,
    required String title,
    Color color = const Color(0xFF1A3A5C),
  }) {
    return showDialog(
      context: context,
      builder: (_) => VoicePlayerDialog(url: url, title: title, color: color),
    );
  }

  @override
  ConsumerState<VoicePlayerDialog> createState() => _VoicePlayerDialogState();
}

class _VoicePlayerDialogState extends ConsumerState<VoicePlayerDialog> {
  // Local override while the user drags the slider.
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(circularAudioProvider.notifier).play(widget.url);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to play voice file')),
          );
          Navigator.of(context).pop();
        }
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(circularAudioProvider);
    final isActive = audio.currentUrl == widget.url;
    final isLoading = isActive && audio.isLoading;
    final isPlaying = isActive && audio.isPlaying;

    final durationMs = audio.duration.inMilliseconds;
    final positionMs = audio.position.inMilliseconds
        .clamp(0, durationMs == 0 ? 1 : durationMs)
        .toDouble();
    final maxMs = durationMs == 0 ? 1.0 : durationMs.toDouble();
    final sliderValue = (_dragValue ?? positionMs).clamp(0.0, maxMs);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.graphic_eq_rounded,
                      color: widget.color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: widget.color,
                inactiveTrackColor: widget.color.withOpacity(0.15),
                thumbColor: widget.color,
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: sliderValue,
                max: maxMs,
                onChanged: durationMs == 0
                    ? null
                    : (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) {
                  ref
                      .read(circularAudioProvider.notifier)
                      .seek(Duration(milliseconds: v.round()));
                  setState(() => _dragValue = null);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(Duration(milliseconds: sliderValue.round())),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    _fmt(audio.duration),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () =>
                    ref.read(circularAudioProvider.notifier).toggle(widget.url),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
