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
    this.message = "",
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
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

    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid 4-digit OTP"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /*
       * If backend has separate OTP verification API,
       * call that API here.
       *
       * Currently OTP is passed to Change Password screen.
       */

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        RoutesName.changepassword,
        arguments: {
          "empId": widget.empId,
          "otp": otp,
        },
      );
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
          _isLoading = false;
        });
      }
    }
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
      // Same Forgot Password API call
      // using the Employee ID received from Login screen.

      final response = await ref
          .read(loginProvider.notifier)
          .forgotPassword(
        empId: widget.empId.trim(),
      );

      if (!mounted) return;

      if (response["success"] == true) {
        // Restart 60 seconds timer
        _startTimer();

        // Clear old OTP
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
    return SizedBox(
      width: 65,
      height: 65,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        maxLength: 1,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primary,
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
          if (value.isNotEmpty && index < 3) {
            FocusScope.of(context).requestFocus(
              _focusNodes[index + 1],
            );
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

    return "$mins : $secs";
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),

                    // MARK: - Title

                    const Text(
                      "Verify your email",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // MARK: - Description

                    Text(
                      widget.message.isNotEmpty
                          ? widget.message
                          : "We just sent a 4-digit OTP to your registered email address.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Please enter the OTP to continue.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // MARK: - OTP Fields

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        _otpBox,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // MARK: - Continue Button

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                        _isLoading || _isResending
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          AppColors.primary,
                          disabledBackgroundColor:
                          AppColors.primary
                              .withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          "Continue",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // MARK: - Resend

                    const Text(
                      "Didn't receive code?",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap:
                          _seconds == 0 &&
                              !_isResending
                              ? _resendOtp
                              : null,
                          child: _isResending
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                              AppColors.primary,
                            ),
                          )
                              : Text(
                            "Resend",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              FontWeight.bold,
                              color: _seconds == 0
                                  ? const Color(
                                0xFF5C5CE0,
                              )
                                  : Colors.grey,
                            ),
                          ),
                        ),

                        if (_seconds > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            _timerText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // MARK: - Email Information

                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary
                              .withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding:
                            const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.email_outlined,
                              color:
                              AppColors.primary,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Check your registered email",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "The OTP has been sent to your registered email address. Please check your inbox and spam folder.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}