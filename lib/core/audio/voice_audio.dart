import 'package:audio_session/audio_session.dart';
import 'package:record/record.dart';

/// Recorder settings shared by every voice recording in the app.
///
/// - M4A / AAC-LC, mono, 44.1 kHz, 64 kbps (~1.4 MB for 3 minutes): plays on
///   Android and iOS, and keeps the full speech range so the server can make
///   its own 8 kHz copy for the dialer.
/// - Android records from the speech-tuned microphone source with the
///   platform noise suppressor on, which cuts crowd and fan noise without
///   the heavy call-style processing of `voiceCommunication`.
/// - Auto gain stays off: it pumps the volume up and down on some phones.
///   The level hint in the recorder asks the speaker to move closer instead.
/// - iOS ignores these effect flags for file recording, which is fine: its
///   built-in microphone processing is already tuned for speech.
const voiceRecordConfig = RecordConfig(
  encoder: AudioEncoder.aacLc,
  sampleRate: 44100,
  numChannels: 1,
  bitRate: 64000,
  noiseSuppress: true,
  androidConfig: AndroidRecordConfig(
    audioSource: AndroidAudioSource.voiceRecognition,
  ),
);

/// Below this level (dBFS) the voice is too quiet to be clear.
const voiceQuietDbfs = -38.0;

/// Above this level (dBFS) the voice is close to clipping.
const voiceLoudDbfs = -3.0;

/// How the speaker's volume sounds over the last moment of recording.
enum VoiceLevel { ok, quiet, loud }

/// Classifies recent amplitude readings (dBFS). Short pauses between words
/// are ignored: only the loudest readings count.
VoiceLevel voiceLevelOf(List<double> recentDbfs) {
  if (recentDbfs.isEmpty) return VoiceLevel.ok;
  final sorted = [...recentDbfs]..sort();
  final peak = sorted.last;
  // Loudest quarter of the readings: what the voice sounds like while speaking.
  final speaking = sorted[(sorted.length * 3) ~/ 4];
  if (peak >= voiceLoudDbfs) return VoiceLevel.loud;
  if (speaking < voiceQuietDbfs) return VoiceLevel.quiet;
  return VoiceLevel.ok;
}

/// Puts iOS/Android audio into plain playback mode before a voice plays.
///
/// The recorder leaves the session in play-and-record mode, which on iPhone
/// can route audio to the quiet earpiece and lowers the volume. Calling this
/// before every play keeps recorded voices loud and on the loudspeaker.
Future<void> prepareVoicePlayback() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  } catch (_) {
    // Playback still works with the default session.
  }
}
