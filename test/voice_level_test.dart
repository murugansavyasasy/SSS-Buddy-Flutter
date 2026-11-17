import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/core/audio/voice_audio.dart';

void main() {
  test('normal speech with pauses is ok', () {
    // Speaking around -20 dBFS with silent gaps between words.
    final readings = [
      for (var i = 0; i < 25; i++) i % 3 == 0 ? -55.0 : -20.0,
    ];
    expect(voiceLevelOf(readings), VoiceLevel.ok);
  });

  test('far-away voice is quiet', () {
    final readings = [for (var i = 0; i < 25; i++) i.isEven ? -45.0 : -50.0];
    expect(voiceLevelOf(readings), VoiceLevel.quiet);
  });

  test('a peak near 0 dBFS is loud', () {
    final readings = [for (var i = 0; i < 24; i++) -18.0, -1.0];
    expect(voiceLevelOf(readings), VoiceLevel.loud);
  });

  test('no readings yet is ok', () {
    expect(voiceLevelOf(const []), VoiceLevel.ok);
  });
}
