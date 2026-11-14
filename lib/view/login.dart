import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../Values/Strings/strings_value.dart';
import '../Components/CustomPasswordField.dart';
import '../Components/CustomButton.dart';
import '../Components/CustomTextField.dart';
import '../Components/header_container.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/login_view_model.dart';

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
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // MARK: - Header

              HeaderContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset("assets/images/logo.png"),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      Strings.welcometoSSSBuddy,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      Strings.logintocontinue,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // MARK: - Form

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Employee ID

                          CustomTextField(
                            controller: emailController,
                            labelText: Strings.empIDMobileNumber,
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

                          const SizedBox(height: 20),

                          // Password

                          CustomPasswordField(
                            controller: passwordController,
                            labelText: Strings.password,
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

                          Row(
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
                            ],
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