import 'InitiateDemoCall.dart';

enum UploadStep {
  idle,
  gettingPresignedUrl,
  uploadingToS3,
  initiatingCall,
  success,
  failed,
}

class UploadState {
  final UploadStep step;
  final String? errorMessage;
  final List<Initiatedemocall>? result;
  final UploadStep? failedStep;

  const UploadState({
    this.step = UploadStep.idle,
    this.errorMessage,
    this.result,
    this.failedStep,
  });

  UploadState copyWith({
    UploadStep? step,
    String? errorMessage,
    List<Initiatedemocall>? result,
  }) {
    return UploadState(
      step: step ?? this.step,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}
