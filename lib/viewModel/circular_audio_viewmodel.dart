import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Playback state for the currently selected circular voice file.
///
/// Only one voice file can play at a time across the whole Circular List,
/// so we key everything off [currentUrl].
class CircularAudioState {
  final String? currentUrl;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;

  const CircularAudioState({
    this.currentUrl,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  CircularAudioState copyWith({
    String? currentUrl,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
  }) {
    return CircularAudioState(
      currentUrl: currentUrl ?? this.currentUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class CircularAudioNotifier extends Notifier<CircularAudioState> {
  final AudioPlayer _player = AudioPlayer();

  @override
  CircularAudioState build() {
    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _player.pause();
        _player.seek(Duration.zero);
        state = state.copyWith(isPlaying: false, isLoading: false);
        return;
      }

      final isLoading =
          playerState.processingState == ProcessingState.loading ||
              playerState.processingState == ProcessingState.buffering;

      state = state.copyWith(
        isPlaying: playerState.playing && !isLoading,
        isLoading: isLoading,
      );
    });

    _player.positionStream.listen((p) {
      state = state.copyWith(position: p);
    });

    _player.durationStream.listen((d) {
      state = state.copyWith(duration: d ?? Duration.zero);
    });

    ref.onDispose(() => _player.dispose());

    return const CircularAudioState();
  }

  /// Ensures [url] is loaded and playing. Used when opening the player popup.
  Future<void> play(String url) async {
    if (url.trim().isEmpty) return;

    if (url == state.currentUrl) {
      if (!_player.playing) await _player.play();
      return;
    }

    await _load(url);
  }

  /// Play/pause toggle for the button inside the popup.
  Future<void> toggle(String url) async {
    if (url.trim().isEmpty) return;

    if (url == state.currentUrl) {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
      return;
    }

    await _load(url);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> pause() async {
    if (_player.playing) await _player.pause();
  }

  Future<void> _load(String url) async {
    try {
      state = CircularAudioState(
        currentUrl: url,
        isPlaying: false,
        isLoading: true,
      );
      final duration = await _player.setUrl(url);
      state = state.copyWith(duration: duration ?? Duration.zero);
      await _player.play();
    } catch (e) {
      state = const CircularAudioState();
      throw Exception('Unable to play voice file: $e');
    }
  }
}

final circularAudioProvider =
    NotifierProvider<CircularAudioNotifier, CircularAudioState>(
  () => CircularAudioNotifier(),
);
