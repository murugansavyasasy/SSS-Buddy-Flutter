import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'chat_common.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String url;
  final int? durationMs;
  final bool isMine;

  const VoiceMessageBubble({
    super.key,
    required this.url,
    this.durationMs,
    required this.isMine,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  AudioPlayer? _player;
  final List<StreamSubscription> _subs = [];
  bool _playing = false;
  bool _loading = false;
  Duration _position = Duration.zero;
  Duration? _total;

  Duration get _length =>
      _total ?? Duration(milliseconds: widget.durationMs ?? 0);

  Future<void> _toggle() async {
    if (_player == null) {
      final p = AudioPlayer();
      _player = p;
      _subs.add(p.positionStream.listen((d) {
        if (mounted) setState(() => _position = d);
      }));
      _subs.add(p.playerStateStream.listen((s) {
        if (!mounted) return;
        if (s.processingState == ProcessingState.completed) {
          p.pause();
          p.seek(Duration.zero);
        }
        setState(() {
          _playing = s.playing && s.processingState != ProcessingState.completed;
          _loading = s.processingState == ProcessingState.loading ||
              s.processingState == ProcessingState.buffering;
        });
      }));
      setState(() => _loading = true);
      try {
        final u = widget.url;
        _total = (u.startsWith('/') || u.startsWith('file:'))
            ? await p.setFilePath(u.replaceFirst('file://', ''))
            : await p.setUrl(u);
      } catch (_) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play voice message')),
          );
        }
        return;
      }
    }
    final p = _player!;
    p.playing ? await p.pause() : await p.play();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isMine ? Colors.white : const Color(0xFF1C2340);
    final total = _length.inMilliseconds;
    final progress =
        total > 0 ? (_position.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          GestureDetector(
            onTap: _loading ? null : _toggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: fg.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                    )
                  : Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: fg,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: fg.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatDuration(_playing || _position > Duration.zero
                      ? _position
                      : _length),
                  style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
