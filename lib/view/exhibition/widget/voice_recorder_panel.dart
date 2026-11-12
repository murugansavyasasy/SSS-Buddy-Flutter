import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../Values/Colors/app_colors.dart';
import 'exhibition_common.dart';

enum _RecState { idle, recording, recorded, denied }

/// Records the custom demo voice as WAV, 8 kHz, mono (what the dialer needs).
/// Reports the file via [onChanged]; `null` means nothing usable is recorded.
class VoiceRecorderPanel extends StatefulWidget {
  final String? initialPath;
  final Duration initialDuration;
  final void Function(String? path, Duration duration) onChanged;

  const VoiceRecorderPanel({
    super.key,
    this.initialPath,
    this.initialDuration = Duration.zero,
    required this.onChanged,
  });

  @override
  State<VoiceRecorderPanel> createState() => _VoiceRecorderPanelState();
}

class _VoiceRecorderPanelState extends State<VoiceRecorderPanel> {
  static const _maxLength = Duration(minutes: 3);
  static const _bars = 40;

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _RecState _state = _RecState.idle;
  String? _path;
  Duration _elapsed = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _busy = false;
  final List<double> _levels = [];

  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<PlayerState>? _playerSub;
  StreamSubscription<Duration>? _posSub;

  @override
  void initState() {
    super.initState();
    _playerSub = _player.playerStateStream.listen((s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      } else {
        setState(() => _playing = s.playing);
      }
    });
    _posSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    if (widget.initialPath != null && File(widget.initialPath!).existsSync()) {
      _path = widget.initialPath;
      _elapsed = widget.initialDuration;
      _state = _RecState.recorded;
      _player.setFilePath(_path!).catchError((_) => null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _playerSub?.cancel();
    _posSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_busy) return;
    _busy = true;
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() => _state = _RecState.denied);
        return;
      }
      if (!await _recorder.isEncoderSupported(AudioEncoder.wav)) {
        if (mounted) exToast(context, 'This device cannot record WAV audio.', error: true);
        return;
      }
      await _player.stop();
      await _deleteFile();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/exhibition_demo_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 8000,
          numChannels: 1,
        ),
        path: path,
      );
      HapticFeedback.mediumImpact();
      _levels.clear();
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((a) {
        // dBFS (-60..0) to 0..1
        final v = ((a.current + 60) / 60).clamp(0.06, 1.0).toDouble();
        if (mounted) setState(() => _levels.add(v));
      });
      final started = DateTime.now();
      _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final e = DateTime.now().difference(started);
        if (!mounted) return;
        setState(() => _elapsed = e);
        if (e >= _maxLength) {
          _stop();
          exToast(context, 'Maximum length (3 minutes) reached');
        }
      });
      setState(() {
        _path = path;
        _elapsed = Duration.zero;
        _state = _RecState.recording;
      });
      widget.onChanged(null, Duration.zero);
    } catch (e) {
      if (mounted) exToast(context, 'Could not start recording: $e', error: true);
    } finally {
      _busy = false;
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;
    await _ampSub?.cancel();
    _ampSub = null;
    final path = await _recorder.stop();
    HapticFeedback.lightImpact();
    if (!mounted) return;
    if (path == null || _elapsed < const Duration(seconds: 1)) {
      setState(() => _state = _RecState.idle);
      exToast(context, 'Recording too short. Hold on a little longer.', error: true);
      return;
    }
    setState(() {
      _path = path;
      _state = _RecState.recorded;
      _position = Duration.zero;
    });
    try {
      await _player.setFilePath(path);
    } catch (_) {}
    widget.onChanged(path, _elapsed);
  }

  Future<void> _togglePlay() async {
    if (_path == null) return;
    if (_playing) {
      await _player.pause();
    } else {
      if (_player.audioSource == null) await _player.setFilePath(_path!);
      _player.play();
    }
  }

  Future<void> _deleteFile() async {
    final p = _path;
    if (p == null) return;
    try {
      final f = File(p);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> _discard() async {
    await _player.stop();
    await _deleteFile();
    setState(() {
      _path = null;
      _elapsed = Duration.zero;
      _position = Duration.zero;
      _levels.clear();
      _state = _RecState.idle;
    });
    widget.onChanged(null, Duration.zero);
  }

  List<double> _barHeights() {
    if (_state == _RecState.recording) {
      final recent = _levels.length > _bars ? _levels.sublist(_levels.length - _bars) : _levels;
      return [
        ...List.filled(_bars - recent.length, 0.06),
        ...recent,
      ];
    }
    if (_state == _RecState.recorded && _levels.isNotEmpty) {
      // Downsample the whole take to the bar count.
      return List.generate(_bars, (i) {
        final start = (i * _levels.length / _bars).floor();
        final end = math.max(start + 1, ((i + 1) * _levels.length / _bars).floor());
        final slice = _levels.sublist(start, math.min(end, _levels.length));
        return slice.isEmpty ? 0.06 : slice.reduce(math.max);
      });
    }
    if (_state == _RecState.recorded) {
      return List.generate(_bars, (i) => 0.2 + 0.6 * (math.sin(i * 0.55) * math.cos(i * 0.21)).abs());
    }
    return List.filled(_bars, 0.06);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: exBorder),
      ),
      child: Column(
        children: [
          if (_state == _RecState.denied) _denied() else ..._recorderBody(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: exInk),
                SizedBox(width: 8),
                Text('Audio is saved as WAV, 8 kHz, mono',
                    style: TextStyle(fontSize: 12.5, color: exInk)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _recorderBody() {
    final recording = _state == _RecState.recording;
    final recorded = _state == _RecState.recorded;
    final heights = _barHeights();
    final progress = recorded && _elapsed.inMilliseconds > 0
        ? _position.inMilliseconds / _elapsed.inMilliseconds
        : 0.0;

    return [
      Text(
        exDuration(recorded ? _elapsed : _elapsed),
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: recording ? exDanger : exInk,
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < heights.length; i++)
              Container(
                width: 4,
                height: 6 + 54 * heights[i],
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: recording
                      ? const Color(0xFFE7000B)
                      : recorded && i / heights.length < progress
                          ? AppColors.primary
                          : exStrongBorder,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      if (!recorded) ...[
        _RecordButton(recording: recording, onTap: recording ? _stop : _start),
        const SizedBox(height: 12),
        Text(
          recording ? 'Recording… tap to stop' : 'Tap to record',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: recording ? exDanger : exInk,
          ),
        ),
        if (recording) ...[
          const SizedBox(height: 12),
          ExSecondaryButton(label: 'Stop', icon: Icons.stop_rounded, onPressed: _stop),
        ],
      ] else ...[
        Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: exInk),
                tooltip: _playing ? 'Pause recording' : 'Play recording',
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Slider(
                    value: _position.inMilliseconds
                        .clamp(0, math.max(1, _elapsed.inMilliseconds))
                        .toDouble(),
                    max: math.max(1, _elapsed.inMilliseconds).toDouble(),
                    activeColor: AppColors.primary,
                    onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(exDuration(_position),
                            style: const TextStyle(fontSize: 12, color: exSubtle)),
                        Text(exDuration(_elapsed),
                            style: const TextStyle(fontSize: 12, color: exSubtle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ExSecondaryButton(
                  label: 'Re-record', icon: Icons.refresh_rounded, onPressed: _start),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExSecondaryButton(
                label: 'Discard',
                icon: Icons.delete_outline_rounded,
                color: exDanger,
                onPressed: _discard,
              ),
            ),
          ],
        ),
      ],
    ];
  }

  Widget _denied() => Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFFFDECEC), shape: BoxShape.circle),
            child: const Icon(Icons.mic_off_rounded, size: 36, color: exDanger),
          ),
          const SizedBox(height: 12),
          const Text('Microphone access is off',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: exInk)),
          const SizedBox(height: 6),
          const Text(
            'Allow microphone access in Settings to record a custom voice.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: exSubtle),
          ),
          const SizedBox(height: 16),
          ExPrimaryButton(
            label: 'Open Settings',
            icon: Icons.settings_outlined,
            onPressed: () => openAppSettings(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _state = _RecState.idle),
            child: const Text('Try again'),
          ),
        ],
      );
}

class _RecordButton extends StatefulWidget {
  final bool recording;
  final VoidCallback onTap;

  const _RecordButton({required this.recording, required this.onTap});

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didUpdateWidget(covariant _RecordButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.recording && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.recording ? const Color(0xFFE7000B) : AppColors.primary;
    return Semantics(
      button: true,
      label: widget.recording ? 'Stop recording' : 'Start recording',
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.recording
                ? [
                    BoxShadow(
                      color: const Color(0xFFE7000B).withOpacity(0.35 * (1 - _pulse.value)),
                      spreadRadius: 26 * _pulse.value,
                    ),
                  ]
                : const [
                    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
                  ],
          ),
          child: child,
        ),
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: SizedBox(
              width: 112,
              height: 112,
              child: Icon(
                widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
