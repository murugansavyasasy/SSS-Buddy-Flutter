import 'package:flutter/material.dart';
import '../../../auth/model/UploadState.dart';


class UploadOverlayWidget extends StatelessWidget {
  final UploadStep step;
  final VoidCallback? onSuccessOkay;

  /// Shown on success: sends the demo video to the principal on WhatsApp.
  /// Null hides the button (no valid principal number).
  final VoidCallback? onWhatsApp;

  const UploadOverlayWidget({
    super.key,
    required this.step,
    this.onSuccessOkay,
    this.onWhatsApp,
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
        return "Voice has been sent successfully!";
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
                if (onWhatsApp != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onWhatsApp,
                      icon: const Icon(Icons.ondemand_video_rounded, size: 18),
                      label: const Text(
                        "Send demo video on WhatsApp",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF15803D)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
