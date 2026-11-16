import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../components/ChangePasswordDialog.dart';
import '../components/toolbar_layout.dart';
import '../core/storage/secure_storage.dart';
import '../main.dart';
import '../viewModel/changepassword_view_model.dart';
import 'dashboard.dart';
import '../viewModel/login_view_model.dart';
import 'login.dart';

class ChangePassword extends ConsumerStatefulWidget {
  const ChangePassword({super.key});

  @override
  ConsumerState<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends ConsumerState<ChangePassword> {
  final TextEditingController existingpasswordcontroller =
  TextEditingController();
  final TextEditingController newpasswordcontroller = TextEditingController();
  final TextEditingController confrimpasswordcontroller =
  TextEditingController();

  String? existingPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

  // ── visibility toggles ──
  bool _existingPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

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

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                "Change Password",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to change your password? You will be logged out after the change.",
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                "Yes, Change",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;
    final idUser = loginData?.userId;

    if (idUser == null) {
      ChangePasswordDialog.show(
        context,
        message: "User session not found. Please login again.",
        isSuccess: false,
      );
      return;
    }

    final response = await ref
        .read(changepasswordProvider.notifier)
        .changepassword(oldPassword, newPassword);

    if (response != null) {
      final isSuccess = response.result == 1;
      final message = response.resultMessage ?? "Something went wrong";

      ChangePasswordDialog.show(
        context,
        message: message,
        isSuccess: isSuccess,
        onClose: isSuccess
            ? () async {
          existingpasswordcontroller.clear();
          newpasswordcontroller.clear();
          confrimpasswordcontroller.clear();
          await SecureStorage.clearLoginData();
          AppRoot.restartApp(context);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
          );
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
              if (controller == existingpasswordcontroller)
                existingPasswordError = null;
              if (controller == newpasswordcontroller) newPasswordError = null;
              if (controller == confrimpasswordcontroller)
                confirmPasswordError = null;
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
        ],
      ],
    );
  }

  /// Green tick inside the confirm field once both new passwords match.
  Widget? _matchIndicator() {
    final newPassword = newpasswordcontroller.text.trim();
    final confirm = confrimpasswordcontroller.text.trim();
    if (confirm.isEmpty || newPassword != confirm) return null;
    return const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(changepasswordProvider).isLoading;

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
                          "Update your password",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          "Enter your current password, then choose a new one.\nYou'll be signed out after the change.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _muted, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── fields ──
                      _buildLabeledField(
                        label: "Existing Password",
                        hint: "Enter current password",
                        icon: Icons.lock_outline_rounded,
                        controller: existingpasswordcontroller,
                        errorText: existingPasswordError,
                        isVisible: _existingPasswordVisible,
                        onToggleVisibility: () => setState(
                              () => _existingPasswordVisible =
                          !_existingPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: _fieldBorder),
                      const SizedBox(height: 18),
                      _buildLabeledField(
                        label: "New Password",
                        hint: "Enter new password",
                        icon: Icons.key_rounded,
                        controller: newpasswordcontroller,
                        errorText: newPasswordError,
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
                        controller: confrimpasswordcontroller,
                        errorText: confirmPasswordError,
                        isVisible: _confirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: isSubmitting ? null : _validateAndSubmit,
                        trailingHint: _matchIndicator(),
                        onToggleVisibility: () => setState(
                              () =>
                          _confirmPasswordVisible = !_confirmPasswordVisible,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _validateAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryprimary,
                            disabledBackgroundColor:
                                AppColors.secondaryprimary.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Update Password",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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
