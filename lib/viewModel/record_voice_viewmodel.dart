
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/InitiateDemoCallRequest.dart';
import '../auth/model/UploadState.dart';
import '../core/aws/aws_key.dart';
import '../provider/app_providers.dart';
import '../provider/user_session_provider.dart';

class RecordVoiceViewModel extends AsyncNotifier<UploadState> {

  String? _presignedUrl;
  String? _fileUrl;
  String? _audioPath;
  String? _demoId;
  int _durationSeconds = 0;

  @override
  Future<UploadState> build() async {
    return const UploadState(step: UploadStep.idle);
  }

  Future<void> createAndUpload({
    required String audioPath,
    required String demoId,
    required int durationSeconds,
  }) async {

    final user = ref.read(userSessionProvider).value;
    if (user == null) {
      state = AsyncData(const UploadState(
        step: UploadStep.failed,
        errorMessage: "Session expired. Please log in again.",
      ));
      return;
    }

    _audioPath = audioPath;
    _demoId = demoId;
    _durationSeconds = durationSeconds;

    final repo = ref.read(repositoryProvider);
    final loginId = user.VimsIdUser;


    if (_presignedUrl == null || _fileUrl == null) {
      try {
        state = AsyncData(const UploadState(step: UploadStep.gettingPresignedUrl));
        final now = DateTime.now();
        final bucketPath =
            "${now.year}-${_pad(now.month)}-${_pad(now.day)}_"
            "${_pad(now.hour)}-${_pad(now.minute)}-${_pad(now.second)}/$loginId";

        final fileName = "demoVoice.wav";
        // final fileName =
        //     '${loginId}_${demoId}_${DateTime.now().millisecondsSinceEpoch}.wav';

        final uploadResponse = await repo.getPresignedUrl(
          bucket: AwsKey.SCHOOL_CHIMES_COMMUNICATION,
          fileName: '${loginId}_${demoId}_${DateTime.now().millisecondsSinceEpoch}.m4a',
          bucketPath: bucketPath,
          fileType: 'audio/mp4',

        );

        _presignedUrl = uploadResponse.data?.presignedUrl;
        _fileUrl = uploadResponse.data?.fileUrl;

        if (_presignedUrl == null || _fileUrl == null) {
          throw Exception("Server did not return a valid upload URL.");
        }

      } catch (e) {

        state = AsyncData(UploadState(
          step: UploadStep.failed,
          errorMessage: "Could not prepare upload. Tap retry.\n${e.toString()}",
          failedStep: UploadStep.gettingPresignedUrl,
        ));
        return;
      }

    }

    try {
      state = AsyncData(const UploadState(step: UploadStep.uploadingToS3));

      final fileBytes = await File(audioPath).readAsBytes();
      final uploaded = await repo.uploadToS3(
        presignedUrl: _presignedUrl!,
        fileBytes: fileBytes,
        contentType: 'audio/mp4',
      );

      if (!uploaded) throw Exception("Upload returned a failure status.");

    } catch (e) {

      state = AsyncData(UploadState(
        step: UploadStep.failed,
        errorMessage: "Audio upload failed. Tap retry.\n${e.toString()}",
        failedStep: UploadStep.uploadingToS3,
      ));
      return;
    }

    try {
      state = AsyncData(const UploadState(step: UploadStep.initiatingCall));

      final request = InitiateDemoCallRequest(
        loginId: loginId,
        demoId: _demoId!,
        voiceUrl: _fileUrl!,
        duration: _durationSeconds,
        fileName: _fileUrl!.split('/').last,
      );

      final result = await repo.postInitiateDemoCall(request);

      _clearIntermediateState();

      state = AsyncData(UploadState(
        step: UploadStep.success,
        result: result,
      ));

    } catch (e) {

      state = AsyncData(UploadState(
        step: UploadStep.failed,
        errorMessage: "Could not initiate demo call. Tap retry.\n${e.toString()}",
        failedStep: UploadStep.initiatingCall,
      ));
    }
  }
  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> retry() async {
    if (_audioPath == null || _demoId == null) return;
    await createAndUpload(
      audioPath: _audioPath!,
      demoId: _demoId!,
      durationSeconds: _durationSeconds,
    );
  }

  void _clearIntermediateState() {
    _presignedUrl = null;
    _fileUrl = null;
    _audioPath = null;
    _demoId = null;
    _durationSeconds = 0;
  }
}

final recordVoiceViewModelProvider = AsyncNotifierProvider.autoDispose<
    RecordVoiceViewModel, UploadState>(
  RecordVoiceViewModel.new,
);