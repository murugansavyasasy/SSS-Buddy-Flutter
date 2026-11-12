import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: exBorder),
      ),
      child: Column(
        children: [
          if (_state == _RecState.denied) _denied() else ..._recorderBody(),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: exPageBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 17, color: exInk),
                SizedBox(width: 8),
                Flexible(
                  child: Text('Audio is saved as WAV, 8 kHz, mono',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: exInk)),
                ),
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

    if (recorded) {
      return [
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: exInk, shape: const CircleBorder()),
                tooltip: _playing ? 'Pause recording' : 'Play recording',
                onPressed: _togglePlay,
                icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_outlined,
                    color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: exBrand,
                      inactiveTrackColor: exBorder,
                      thumbColor: exBrand,
                      overlayColor: exIndicator.withValues(alpha: 0.3),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
                    ),
                    child: Slider(
                      value: _position.inMilliseconds
                          .clamp(0, math.max(1, _elapsed.inMilliseconds))
                          .toDouble(),
                      max: math.max(1, _elapsed.inMilliseconds).toDouble(),
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(exDuration(_position), style: exBodyMd),
                        Text(exDuration(_elapsed), style: exBodyMd),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: ExSecondaryButton(label: 'Re-record', onPressed: _start)),
            const SizedBox(width: 12),
            Expanded(
              child: ExSecondaryButton(label: 'Discard', color: exDanger, onPressed: _discard),
            ),
          ],
        ),
      ];
    }

    final heights = _barHeights();
    return [
      Text(
        exDuration(_elapsed),
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: recording ? exDanger : exInk,
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 44,
        child: recording
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < heights.length; i++)
                    Container(
                      width: 4,
                      height: 6 + 36 * heights[i],
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: exRecord,
                      ),
                    ),
                ],
              )
            : Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 24; i++)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(
                          color: exIndicator,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
      ),
      const SizedBox(height: 8),
      _RecordButton(recording: recording, onTap: recording ? _stop : _start),
      const SizedBox(height: 8),
      if (recording) ...[
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10, color: exRecord),
            SizedBox(width: 8),
            Text('Recording…',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: exDanger)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(width: 140, child: ExSecondaryButton(label: 'Stop', height: 44, onPressed: _stop)),
      ] else
        const Text('Tap to record', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    ];
  }

  Widget _denied() => Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: exDangerBg, shape: BoxShape.circle),
            child: const Icon(Icons.mic_off_outlined, size: 32, color: exDanger),
          ),
          const SizedBox(height: 16),
          const Text('Microphone access is off', style: exHeadingSm),
          const SizedBox(height: 6),
          const Text(
            'Allow access in Settings to record.',
            textAlign: TextAlign.center,
            style: exBodyMd,
          ),
          const SizedBox(height: 16),
          ExPrimaryButton(
            label: 'Open Settings',
            expand: false,
            height: 48,
            onPressed: () => openAppSettings(),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _state = _RecState.idle),
            style: TextButton.styleFrom(foregroundColor: exBrandBold, minimumSize: const Size(0, 48)),
            child: const Text('Try again',
                style: TextStyle(fontFamily: exFont, fontWeight: FontWeight.w600)),
          ),
        ],
      );
}

/// Idle: brand gradient mic. Recording: red stop with a pale halo.
class _RecordButton extends StatefulWidget {
  final bool recording;
  final VoidCallback onTap;

  const _RecordButton({required this.recording, required this.onTap});

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (widget.recording) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _RecordButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
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
    final rec = widget.recording;
    return Semantics(
      button: true,
      label: rec ? 'Stop recording' : 'Start recording',
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (rec)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 106 + 14 * _pulse.value,
                  height: 106 + 14 * _pulse.value,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDEEEE),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: rec ? 88 : 84,
                height: rec ? 88 : 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rec ? exRecord : null,
                  gradient: rec
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [exBrandBold, exBrand],
                        ),
                ),
                child: rec
                    ? Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      )
                    : const Icon(Icons.mic_none_rounded, color: Colors.white, size: 38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
