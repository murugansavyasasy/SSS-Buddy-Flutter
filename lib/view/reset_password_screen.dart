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

  // Same look as the Change Password screen.
  static const Color _ink = Color(0xFF1C2340);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _fieldBorder = Color(0xFFE2E6EE);
  static const Color _fieldFill = Color(0xFFF7F8FB);

  OutlineInputBorder _border(Color color, [double width = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _buildLabeledField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? errorText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
    String? helperText,
    Widget? trailingHint,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
            children: const [
              TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          textInputAction: textInputAction,
          onSubmitted: (_) => onSubmitted?.call(),
          style: const TextStyle(fontSize: 15, color: _ink),
          onChanged: (_) {
            setState(() {
              if (controller == newPasswordController) newPasswordError = null;
              if (controller == confirmPasswordController) confirmPasswordError = null;
            });
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            filled: true,
            fillColor: hasError ? Colors.red.withValues(alpha: 0.04) : _fieldFill,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: hasError ? Colors.red : _muted,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingHint != null) trailingHint,
                IconButton(
                  tooltip: isVisible ? "Hide password" : "Show password",
                  onPressed: onToggleVisibility,
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: hasError ? Colors.red : _muted,
                  ),
                ),
              ],
            ),
            enabledBorder: _border(hasError ? Colors.red : _fieldBorder),
            focusedBorder:
                _border(hasError ? Colors.red : AppColors.primary, 1.6),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline, color: Colors.red, size: 14),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  errorText,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  /// Green tick inside the confirm field once both passwords match.
  Widget? _matchIndicator() {
    final newPassword = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();
    if (confirm.isEmpty || newPassword != confirm) return null;
    return const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20);
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── intro ──
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          "Create a new password",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          widget.empId.trim().isEmpty
                              ? "Choose a new password for your account."
                              : "Choose a new password for Employee ID ${widget.empId.trim()}.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: _muted, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── fields ──
                      _buildLabeledField(
                        label: "New Password",
                        hint: "Enter new password",
                        icon: Icons.key_rounded,
                        controller: newPasswordController,
                        errorText: newPasswordError,
                        helperText: "At least 6 characters",
                        isVisible: _newPasswordVisible,
                        onToggleVisibility: () => setState(
                              () => _newPasswordVisible = !_newPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildLabeledField(
                        label: "Confirm Password",
                        hint: "Re-enter new password",
                        icon: Icons.key_rounded,
                        controller: confirmPasswordController,
                        errorText: confirmPasswordError,
                        isVisible: _confirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _isLoading ? null : _submit,
                        trailingHint: _matchIndicator(),
                        onToggleVisibility: () => setState(
                              () => _confirmPasswordVisible =
                          !_confirmPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: "Reset Password",
                          height: 50,
                          isLoading: _isLoading,
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
