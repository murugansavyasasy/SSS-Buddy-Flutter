import 'package:flutter/material.dart';
import '../../../auth/model/UploadState.dart';


class UploadOverlayWidget extends StatelessWidget {
  final UploadStep step;
  final VoidCallback? onSuccessOkay;

  const UploadOverlayWidget({
    super.key,
    required this.step,
    this.onSuccessOkay,
  });

  String get _label {
    switch (step) {
      case UploadStep.gettingPresignedUrl:
        return "Preparing upload...";
      case UploadStep.uploadingToS3:
        return "Uploading audio...";
      case UploadStep.initiatingCall:
        return "Initiating demo call...";
      case UploadStep.success:
        return "Audio has been uploaded successfully!";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = step == UploadStep.success;

    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSuccess)
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                )
              else
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  strokeWidth: 3,
                ),

              const SizedBox(height: 20),

              Text(
                _label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 8),

              if (isSuccess) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSuccessOkay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Okay",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else
                _StepDots(currentStep: step),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  final UploadStep currentStep;

  const _StepDots({required this.currentStep});

  static const _steps = [
    UploadStep.gettingPresignedUrl,
    UploadStep.uploadingToS3,
    UploadStep.initiatingCall,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _steps.map((s) {
        final isActive = _steps.indexOf(s) <= _steps.indexOf(currentStep);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 10 : 8,
          height: isActive ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.orange : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
