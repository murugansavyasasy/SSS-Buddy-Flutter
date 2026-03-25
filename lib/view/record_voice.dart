import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';

import '../Values/Colors/app_colors.dart';

import '../components/CustomRecordingButton.dart';
import '../components/CustomRecordingWaveWidget.dart';
import '../components/toolbar_layout.dart';
import 'dashboard.dart';
import 'demo_list.dart';

class RecordVoice extends ConsumerStatefulWidget {
  const RecordVoice({super.key});

  @override
  ConsumerState<RecordVoice> createState() => _RecordVoiceState();
}

class _RecordVoiceState extends ConsumerState<RecordVoice> {
  bool isRecording = false;
  bool _isBusy = false;
  bool isPlaying = false;

  late final AudioRecorder _audioRecorder;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _audioPath;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${_generateRandomId()}.wav';


      setState(() {
        _audioPath = null;
        isPlaying = false;
      });

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() => _audioPath = path);
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;

    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() => isPlaying = false);
    } else {
      await _audioPlayer.setFilePath(_audioPath!);
      _audioPlayer.play();
      setState(() => isPlaying = true);

      _audioPlayer.durationStream.listen((d) {
        if (d != null) setState(() => _duration = d);
      });

      _audioPlayer.positionStream.listen((p) {
        setState(() => _position = p);
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => isPlaying = false);
        }
      });
    }
  }

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  String formatTime(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  Future<void> _record() async {
    if (_isBusy) return;
    _isBusy = true;

    HapticFeedback.mediumImpact();

    if (!isRecording) {
      final status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        setState(() => isRecording = true);
        await _startRecording();
      } else if (status == PermissionStatus.permanentlyDenied) {
        openAppSettings();
      }
    } else {
      await _stopRecording();
      setState(() => isRecording = false);
    }

    _isBusy = false;
  }


  Widget audioWave() {
    const totalBars = 40;

    return SizedBox(
      height: 30,
      child: Row(
        children: List.generate(totalBars, (index) {
          final isPlayed = index < (totalBars * progress);

          double heightFactor = (index % 5 == 0)
              ? 1.0
              : (index % 3 == 0)
              ? 0.7
              : 0.4;

          return Container(
            width: 3,
            height: 30 * heightFactor,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isPlayed ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   return WillPopScope(
      onWillPop: () async {
        print("Back pressed");
        // custom logic here
        return true; // allow back
      },
    child:  AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Record Voice",
              navigateTo: Dashboard(),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),

                child: Column(
                  children: [

                    const SizedBox(height: 40),


                    if (isRecording)
                      const CustomRecordingWaveWidget(),

                    const SizedBox(height: 20),

                    CustomRecordingButton(
                      isRecording: isRecording,
                      onPressed: _record,
                    ),

                    const SizedBox(height: 20),


                    if (_audioPath != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [


                            GestureDetector(
                              onTap: _togglePlay,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),


                            Expanded(child: audioWave()),

                            const SizedBox(width: 12),


                            Text(
                              formatTime(_position),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),


                      Center(
                        child: SizedBox(
                          width: 160,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: () {
                              debugPrint("Audio path: $_audioPath");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Create"),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}