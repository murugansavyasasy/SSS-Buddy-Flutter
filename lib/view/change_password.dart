import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../components/ChangePasswordDialog.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/changepassword_view_model.dart';
import 'dashboard.dart';
import 'package:sssbuddy/Components/CustomButton.dart';
import 'package:sssbuddy/components/custom_text_field.dart';
import '../viewModel/login_view_model.dart';

class ChangePassword extends ConsumerStatefulWidget {
  const ChangePassword({super.key});

  @override
  ConsumerState<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<ChangePassword> {
  final TextEditingController existingpasswordcontroller = TextEditingController();
  final TextEditingController newpasswordcontroller = TextEditingController();
  final TextEditingController confrimpasswordcontroller = TextEditingController();

  // Error state for each field
  String? existingPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

  void _validateAndSubmit() async {
    setState(() {
      existingPasswordError = null;
      newPasswordError = null;
      confirmPasswordError = null;
    });

    final oldPassword = existingpasswordcontroller.text.trim();
    final newPassword = newpasswordcontroller.text.trim();
    final confirmPassword = confrimpasswordcontroller.text.trim();

    bool hasError = false;

    if (oldPassword.isEmpty) {
      setState(() => existingPasswordError = "Existing password is required");
      hasError = true;
    }

    if (newPassword.isEmpty) {
      setState(() => newPasswordError = "New password is required");
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

    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;
    final idUser = loginData?.VimsIdUser;

    if (idUser == null || idUser.isEmpty) {
      ChangePasswordDialog.show(
        context,
        message: "User session not found. Please login again.",
        isSuccess: false,
      );
      return;
    }

    final response = await ref
        .read(changepasswordProvider.notifier)
        .changepassword(idUser, oldPassword, newPassword);

    if (response != null) {
      final isSuccess = response.result == 1;
      final message = response.resultMessage ?? "Something went wrong";

      ChangePasswordDialog.show(
        context,
        message: message,
        isSuccess: isSuccess,
        onClose: isSuccess
            ? () {
          existingpasswordcontroller.clear();
          newpasswordcontroller.clear();
          confrimpasswordcontroller.clear();
        }
            : null,
      );
    } else {
      ChangePasswordDialog.show(
        context,
        message: "Server error. Please try again.",
        isSuccess: false,
      );
    }
  }

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with mandatory star
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
        // Text field with error border
        TextField(
          controller: controller,
          obscureText: true,
          onChanged: (_) {
            // Clear error on typing
            setState(() {
              if (controller == existingpasswordcontroller) existingPasswordError = null;
              if (controller == newpasswordcontroller) newPasswordError = null;
              if (controller == confrimpasswordcontroller) confirmPasswordError = null;
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: errorText != null
                ? Colors.red.withOpacity(0.04)
                : Colors.grey.withOpacity(0.07),
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
        // Inline error message
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
              title: "Change Password",
              navigateTo: Dashboard(),
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
                        label: "Existing Password",
                        hint: "Enter existing password",
                        controller: existingpasswordcontroller,
                        errorText: existingPasswordError,
                      ),
                      const SizedBox(height: 20),
                      _buildLabeledField(
                        label: "New Password",
                        hint: "Enter new password",
                        controller: newpasswordcontroller,
                        errorText: newPasswordError,
                      ),
                      const SizedBox(height: 20),
                      _buildLabeledField(
                        label: "Confirm Password",
                        hint: "Enter confirm password",
                        controller: confrimpasswordcontroller,
                        errorText: confirmPasswordError,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Submit",
                          onPressed: _validateAndSubmit,
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