import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../Components/toolbar_layout.dart';
import '../Components/CustomButton.dart';
import '../viewModel/login_view_model.dart';
import 'login.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String empId;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.empId,
    required this.otp,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
  TextEditingController();

  String? newPasswordError;
  String? confirmPasswordError;

  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _submit() async {
    setState(() {
      newPasswordError = null;
      confirmPasswordError = null;
    });

    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    bool hasError = false;

    if (newPassword.isEmpty) {
      setState(() => newPasswordError = "New password is required");
      hasError = true;
    } else if (newPassword.length < 6) {
      setState(() => newPasswordError = "Password must be at least 6 characters");
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Confirm password is required");
      hasError = true;
    } else if (newPassword.isNotEmpty && newPassword != confirmPassword) {
      setState(() => confirmPasswordError = "Passwords do not match");
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref
          .read(loginProvider.notifier)
          .resetPassword(
        empId: widget.empId.trim(),
        otp: widget.otp.trim(),
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (response["success"] == true) {
        newPasswordController.clear();
        confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"]?.toString().isNotEmpty == true
                  ? response["message"].toString()
                  : "Password reset successfully. Please login.",
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"]?.toString() ?? "Unable to reset password",
            ),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? errorText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          onChanged: (_) {
            setState(() {
              if (controller == newPasswordController) newPasswordError = null;
              if (controller == confirmPasswordController) confirmPasswordError = null;
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: errorText != null
                ? Colors.red.withOpacity(0.04)
                : Colors.grey.withOpacity(0.07),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                isVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: errorText != null ? Colors.red : Colors.grey.shade500,
              ),
              splashRadius: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(
                errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Reset Password",
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildLabeledField(
                        label: "New Password",
                        hint: "Enter new password",
                        controller: newPasswordController,
                        errorText: newPasswordError,
                        isVisible: _newPasswordVisible,
                        onToggleVisibility: () => setState(
                              () => _newPasswordVisible = !_newPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLabeledField(
                        label: "Confirm Password",
                        hint: "Re-enter new password",
                        controller: confirmPasswordController,
                        errorText: confirmPasswordError,
                        isVisible: _confirmPasswordVisible,
                        onToggleVisibility: () => setState(
                              () => _confirmPasswordVisible =
                          !_confirmPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isLoading ? "Please wait..." : "Reset Password",
                          onPressed: _isLoading ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}