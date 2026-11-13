import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Puts iOS/Android audio into plain playback mode before a voice plays.
///
/// The recorder switches the session to play-and-record, which on iPhone
/// routes audio to the quiet earpiece and obeys the silent switch. Calling
/// this before every play keeps demo voices on the loudspeaker.
Future<void> exPreparePlayback() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  } catch (_) {
    // Playback still works with the default session.
  }
}

/// A voice downloaded to the device, with its total length.
class LocalAudio {
  final String path;
  final Duration? duration;
  const LocalAudio(this.path, this.duration);
}

// Downloads run one at a time so a long demo list doesn't flood the network.
Future<void> _queue = Future.value();

/// Downloads the voice at [url] once into the app cache (reused across
/// launches) and reads its length. Kept for the whole session, so expanding a
/// demo again plays the local file instantly. Null when it can't be fetched.
final localAudioProvider = FutureProvider.family<LocalAudio?, String>((ref, url) {
  if (url.trim().isEmpty) return Future.value(null);
  final done = Completer<LocalAudio?>();
  _queue = _queue.then((_) async {
    try {
      final path = await _download(url);
      Duration? d;
      final p = AudioPlayer();
      try {
        d = await p.setFilePath(path).timeout(const Duration(seconds: 10));
      } catch (_) {
      } finally {
        unawaited(p.dispose());
      }
      done.complete(LocalAudio(path, d));
    } catch (_) {
      done.complete(null);
    }
  });
  return done.future;
});

/// Total length of the voice at [url]; null when unknown.
final audioDurationProvider = FutureProvider.family<Duration?, String>(
  (ref, url) async => (await ref.watch(localAudioProvider(url).future))?.duration,
);

Future<String> _download(String url) async {
  final dir = Directory('${(await getTemporaryDirectory()).path}/demo_audio');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final ext = RegExp(r'\.(wav|mp3|m4a|aac|ogg)$', caseSensitive: false)
          .firstMatch(Uri.tryParse(url)?.path ?? '')
          ?.group(0)
          ?.toLowerCase() ??
      '.wav';
  final file = File('${dir.path}/${_hash(url)}$ext');
  if (file.existsSync() && file.lengthSync() > 0) return file.path;

  final part = File('${file.path}.part');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final sink = part.openWrite();
    await res.timeout(const Duration(seconds: 60)).pipe(sink);
    await part.rename(file.path);
    return file.path;
  } catch (_) {
    if (part.existsSync()) part.deleteSync();
    rethrow;
  } finally {
    client.close();
  }
}

/// Stable file name for a URL (FNV-1a, 64-bit).
String _hash(String s) {
  var h = 0xcbf29ce484222325;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return h.toUnsigned(64).toRadixString(16);
}
