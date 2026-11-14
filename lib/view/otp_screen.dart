import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../utils/routes/routes_name.dart';
import '../Components/toolbar_layout.dart';
import '../viewModel/login_view_model.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String empId;
  final String message;

  const OtpScreen({
    super.key,
    required this.empId,
    required this.message
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _otpControllers =
  List.generate(_otpLength, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(_otpLength, (_) => FocusNode());

  bool _isResending = false;

  int _seconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  // MARK: - Timer

  void _startTimer() {
    _seconds = 60;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        return false;
      }

      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });

        return true;
      }

      return false;
    });
  }

  // MARK: - OTP Code

  String get _otpCode {
    return _otpControllers
        .map((controller) => controller.text)
        .join();
  }

  // MARK: - Verify OTP

  Future<void> _verifyOtp() async {
    final otp = _otpCode;

    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid 6-digit OTP"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    Navigator.pushNamed(
      context,
      RoutesName.resetpassword,
      arguments: {
        "empId": widget.empId,
        "otp": otp,
      },
    );
  }

  // MARK: - Resend OTP

  Future<void> _resendOtp() async {
    if (_seconds > 0 || _isResending) {
      return;
    }

    if (widget.empId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Employee ID is missing"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final response = await ref
          .read(loginProvider.notifier)
          .forgotPassword(
        empId: widget.empId.trim(),
      );

      if (!mounted) return;

      if (response["success"] == true) {
        _startTimer();
        for (final controller in _otpControllers) {
          controller.clear();
        }

        // Focus first OTP box
        FocusScope.of(context).requestFocus(
          _focusNodes[0],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"]?.toString().isNotEmpty == true
                  ? response["message"].toString()
                  : "OTP has been resent to your registered email.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"]?.toString() ??
                  "Unable to resend OTP",
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _extractErrorMessage(e),
          ),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  // MARK: - Error Message

  String _extractErrorMessage(Object? error) {
    if (error == null) {
      return "Something went wrong. Please try again.";
    }

    final raw = error.toString();

    if (raw.startsWith("Exception: ")) {
      return raw.substring("Exception: ".length);
    }

    return raw;
  }

  // MARK: - OTP Box

  Widget _otpBox(int index) {
    final filled = _otpControllers[index].text.isNotEmpty;
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        autofocus: index == 0,
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C2340),
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: filled
              ? AppColors.primary.withValues(alpha: 0.06)
              : const Color(0xFFF7F8FB),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: filled ? AppColors.primary : const Color(0xFFD9DEE8),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.isNotEmpty && index < _otpLength - 1) {
            FocusScope.of(context).requestFocus(
              _focusNodes[index + 1],
            );
          } else if (value.isNotEmpty) {
            FocusScope.of(context).unfocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(
              _focusNodes[index - 1],
            );
          }
        },
      ),
    );
  }

  // MARK: - Timer Text

  String get _timerText {
    final mins =
    (_seconds ~/ 60).toString().padLeft(2, '0');

    final secs =
    (_seconds % 60).toString().padLeft(2, '0');

    return "$mins:$secs";
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  // MARK: - UI

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF1C2340);
    const muted = Color(0xFF6B7280);
    final canResend = _seconds == 0 && !_isResending;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // MARK: - Toolbar

          const ToolbarLayout(
            title: "OTP",
          ),

          Expanded(
            child: SafeArea(
              top: false,
              // Scrolls when the keyboard is up; the info card stays at the
              // bottom when there is room.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 28),

                          // MARK: - Icon

                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // MARK: - Title

                          const Text(
                            "Verify your OTP",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // MARK: - Description

                          Text(
                            widget.message.isNotEmpty
                                ? widget.message
                                : "We just sent a 6-digit OTP to your registered email address.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: muted,
                              height: 1.5,
                            ),
                          ),

                          if (widget.empId.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F3F8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Employee ID: ${widget.empId.trim()}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // MARK: - OTP Boxes (equal width, edge to edge)

                          Row(
                            children: [
                              for (var i = 0; i < _otpLength; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: _otpBox(i)),
                              ],
                            ],
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isResending ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // MARK: - Resend

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive code?",
                                style: TextStyle(fontSize: 14, color: muted),
                              ),
                              if (_isResending)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: canResend ? _resendOtp : null,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  child: Text(
                                    _seconds > 0
                                        ? "Resend in $_timerText"
                                        : "Resend",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // MARK: - Email Information

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Check your registered email",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: ink,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Please check your inbox and spam folder.",
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: muted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
