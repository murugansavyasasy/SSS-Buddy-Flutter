import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sssbuddy/view/RecordVoice/widgets/create_button_widget.dart';
import 'package:sssbuddy/view/RecordVoice/widgets/playback_card_widget.dart';
import 'package:sssbuddy/view/RecordVoice/widgets/upload_overlay_widget.dart';
import '../../Values/Colors/app_colors.dart';
import '../../auth/model/Demolist.dart';
import '../../auth/model/UploadState.dart';
import '../../components/CustomRecordingButton.dart';
import '../../components/CustomRecordingWaveWidget.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/record_voice_viewmodel.dart';
import '../dashboard.dart';

class RecordVoiceScreen extends ConsumerStatefulWidget {
  final Demolist item;
  const RecordVoiceScreen({super.key, required this.item});

  @override
  ConsumerState<RecordVoiceScreen> createState() => _RecordVoiceScreenState();
}

class _RecordVoiceScreenState extends ConsumerState<RecordVoiceScreen> {

  bool isRecording = false;
  bool _isPlaying  = false;
  bool _isBusy     = false;

  late final AudioRecorder _audioRecorder;
  String? _audioPath;
  DateTime? _recordingStart;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  int get _recordedDurationSeconds {
    if (_recordingStart == null) return 0;
    return DateTime.now().difference(_recordingStart!).inSeconds;
  }

  double get _progress {
    if (_duration.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();

    _audioPlayer.durationStream.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state.playing;
      });

      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.stop();
        _audioPlayer.seek(Duration.zero);
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final id  = List.generate(10, (_) =>
      'abcdefghijklmnopqrstuvwxyz0123456789'[Random().nextInt(36)]).join();

      setState(() {
        _audioPath      = null;
        _isPlaying      = false;
        _duration       = Duration.zero;
        _position       = Duration.zero;
        _recordingStart = null;
      });

      _recordingStart = DateTime.now();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${dir.path}/$id.m4a',
      );
    } catch (e) {
      debugPrint("Recording error: $e");
    }
  }

  Future<void> _loadDuration(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
    } catch (e) {
      debugPrint("Duration load error: $e");
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() => _audioPath = path);
      await _loadDuration(path);
    }
  }

  Future<void> _record() async {
    if (_isBusy) return;
    _isBusy = true;

    HapticFeedback.mediumImpact();

    // 🔥 FORCE request directly (no status check first time)
    final result = await Permission.microphone.request();
    print("Permission result: $result");

    if (result.isGranted) {
      if (!isRecording) {
        setState(() => isRecording = true);
        await _startRecording();
      } else {
        await _stopRecording();
        setState(() => isRecording = false);
      }
    }
    else if (result.isPermanentlyDenied) {
      showMicPermissionDialog(context);
    }
    else {
      _showSnackBar("Microphone permission denied", isError: true);
    }

    _isBusy = false;
  }
  void showMicPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Microphone Access Required"),
        content: const Text(
          "Please allow microphone access in Settings to record audio.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings(); // 🔥 opens iOS settings
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }
  // void _showPermissionDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Microphone Permission"),
  //       content: const Text(
  //         "Microphone access is permanently denied.\n\nPlease enable it from Settings.",
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             openAppSettings();
  //           },
  //           child: const Text("Open Settings"),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Future<void> _togglePlay() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        // ✅ Always reload path — needed after stop() clears the source
        await _audioPlayer.setFilePath(_audioPath!);

        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();

        setState(() => _isPlaying = true);
      } catch (e) {
        debugPrint("Playback error: $e");
      }
    }
  }

  Future<void> _onCreatePressed() async {
    if (_audioPath == null) return;
    await ref.read(recordVoiceViewModelProvider.notifier).createAndUpload(
      audioPath: _audioPath!,
      demoId: widget.item.demoId.toString(),
      durationSeconds: _recordedDurationSeconds,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showRetrySnackBar({
    required String message,
    UploadStep? failedStep,
  }) {
    if (!mounted) return;

    final stepLabel = switch (failedStep) {
      UploadStep.gettingPresignedUrl => "Step 1 (Preparing) failed",
      UploadStep.uploadingToS3       => "Step 2 (Uploading) failed",
      UploadStep.initiatingCall      => "Step 3 (Initiating call) failed",
      _                              => "Upload failed",
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$stepLabel — $message"),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: "RETRY",
          textColor: Colors.white,
          onPressed: () {
            ref.read(recordVoiceViewModelProvider.notifier).retry();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UploadState>>(recordVoiceViewModelProvider, (_, next) {
      final state = next.value;
      if (state == null) return;
      if (state.step == UploadStep.success) {
        _showSnackBar("Demo call initiated successfully!");
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else if (state.step == UploadStep.failed) {
        _showRetrySnackBar(
          message: state.errorMessage ?? "Something went wrong.",
          failedStep: state.failedStep,
        );
      }
    });

    final uploadState = ref.watch(recordVoiceViewModelProvider).value;
    final isUploading = uploadState != null && [
      UploadStep.gettingPresignedUrl,
      UploadStep.uploadingToS3,
      UploadStep.initiatingCall,
    ].contains(uploadState.step);

    return WillPopScope(
      onWillPop: () async => !isUploading,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Stack(
            children: [
              Column(
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          if (isRecording) const CustomRecordingWaveWidget(),
                          const SizedBox(height: 20),

                          CustomRecordingButton(
                            isRecording: isRecording,
                            onPressed: isUploading ? () {} : _record,
                          ),
                          const SizedBox(height: 20),

                          if (_audioPath != null) ...[
                            PlaybackCardWidget(
                              isPlaying:     _isPlaying,
                              progress:      _progress,
                              position:      _position,
                              totalDuration: _duration,
                              onTogglePlay:  _togglePlay,
                            ),
                            const SizedBox(height: 40),
                            CreateButtonWidget(
                              isLoading: isUploading,
                              onPressed: _onCreatePressed,
                            ),
                          ],

                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (isUploading)
                UploadOverlayWidget(step: uploadState!.step),
            ],
          ),
        ),
      ),
    );
  }
}
