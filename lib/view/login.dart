import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../Values/Strings/strings_value.dart';
import '../Components/CustomPasswordField.dart';
import '../Components/CustomButton.dart';
import '../Components/CustomTextField.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/login_view_model.dart';
import '../components/form_width.dart';
import '../components/app_motion.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _forgotPasswordLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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

  // MARK: - Forgot Password

// MARK: - Forgot Password

  Future<void> _forgotPassword() async {
    if (_forgotPasswordLoading) return;

    final empId = emailController.text.trim();

    // Employee ID mandatory
    if (empId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your Employee ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _forgotPasswordLoading = true;
    });

    try {
      final result = await ref
          .read(loginProvider.notifier)
          .forgotPassword(
        empId: empId,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        Navigator.pushNamed(
          context,
          RoutesName.otp,
          arguments: {
            "empId": empId,
            "message": result["message"]?.toString() ?? "",
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result["message"]?.toString() ??
                  "Unable to send OTP",
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
          _forgotPasswordLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordConfirmation() {
    final empId = emailController.text.trim();
    if (empId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your Employee ID first"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Forgot Password?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "An OTP will be sent to the registered email address "
                "for Employee ID $empId. Do you want to continue?",
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryprimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _forgotPassword();
              },
              child: const Text("Send OTP"),
            ),
          ],
        );
      },
    );
  }

  // MARK: - Login

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(loginProvider.notifier)
        .login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        RoutesName.dashboard,
      );
      return;
    }

    final error = ref.read(loginProvider).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _extractErrorMessage(error),
        ),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  // MARK: - Clear

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    final isLoginLoading = loginState.isLoading;

    final isLoading =
        isLoginLoading || _forgotPasswordLoading;

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF4F6FA),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // MARK: - Header + form card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _LoginHeader(),
                      // Form card overlaps the header and rises in.
                      Transform.translate(
                        offset: const Offset(0, -46),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: formSidePadding(context, 18),
                          ),
                          child: AppEntrance(
                            delay: const Duration(milliseconds: 180),
                            offsetY: 40,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x1A1E2B45), blurRadius: 30, offset: Offset(0, 12)),
                                  BoxShadow(color: Color(0x0A1E2B45), blurRadius: 4, offset: Offset(0, 1)),
                                ],
                              ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Employee ID

                          AppEntrance(
                            index: 0,
                            delay: const Duration(milliseconds: 300),
                            child: CustomTextField(
                            controller: emailController,
                            labelText: Strings.empIDMobileNumber,
                            title: Strings.employeeId,
                            hintText: Strings.enterEmployeeId,
                            prefixIcon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return "Please enter Employee ID";
                              }

                              return null;
                            },
                          ),
                          ),

                          const SizedBox(height: 20),

                          // Password

                          AppEntrance(
                            index: 1,
                            delay: const Duration(milliseconds: 300),
                            child: CustomPasswordField(
                            controller: passwordController,
                            labelText: Strings.password,
                            title: Strings.password,
                            hintText: Strings.enteryourpassword,
                            prefixIcon: Icons.lock_outline_rounded,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!isLoading) _login();
                            },
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty) {
                                return Strings.enteryourpassword;
                              }

                              if (value.length < 1) {
                                return Strings
                                    .passwordmustbeatleastcharacters;
                              }

                              return null;
                            },
                          ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : _showForgotPasswordConfirmation,
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: AppColors.secondaryprimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // MARK: - Login Buttons

                          AppEntrance(
                            index: 2,
                            delay: const Duration(milliseconds: 300),
                            child: Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: Strings.clear,
                                  isOutlined: true,
                                  height: 50,
                                  onPressed: isLoading
                                      ? null
                                      : _clearFields,
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                flex: 2,
                                child: PressableScale(
                                  enabled: !isLoading,
                                  child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      AppColors
                                          .secondaryprimary,
                                      disabledBackgroundColor:
                                      AppColors
                                          .secondaryprimary
                                          .withOpacity(0.5),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : _login,
                                    child: isLoginLoading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      Strings.login,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ],
                          ),
                          ),

                          // Forgot Password Loading

                          if (_forgotPasswordLoading) ...[
                            const SizedBox(height: 20),
                            const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Sending OTP...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // MARK: - Footer

              if (!keyboardOpen)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/savyasasy.webp",
                      width: 36,
                      height: 36,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      Strings.poweredbySavyasasy,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient header with soft bubbles; the logo pops in and the greeting
/// slides up.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    Widget bubble(double size, double alpha, {double? top, double? left, double? right}) => Positioned(
          top: top,
          left: left,
          right: right,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ),
        );
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          bubble(220, 0.06, top: -80, right: -70),
          bubble(120, 0.07, top: 90, right: 40),
          bubble(70, 0.05, top: top + 10, left: -20),
          Padding(
            padding: EdgeInsets.fromLTRB(28, top + 48, 28, 92),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppEntrance(
                  fromScale: 0.6,
                  offsetY: 0,
                  child: Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Image.asset("assets/images/logo.png"),
                  ),
                ),
                const SizedBox(height: 22),
                const AppEntrance(
                  index: 1,
                  child: Text(
                    Strings.welcometoSSSBuddy,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppEntrance(
                  index: 2,
                  child: Text(
                    Strings.logintocontinue,
                    style: TextStyle(fontSize: 15.5, color: Colors.white.withValues(alpha: 0.78)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
