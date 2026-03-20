import 'package:flutter/material.dart';
import '../Values/Colors/app_colors.dart';

class ChangePasswordDialog {
  static void show(
      BuildContext context, {
        required String message,
        required bool isSuccess,
        VoidCallback? onClose,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon Circle
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: isSuccess
                          ? [Colors.green.shade100, Colors.green.shade50]
                          : [Colors.red.shade100, Colors.red.shade50],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: isSuccess
                            ? Colors.green.withOpacity(0.25)
                            : Colors.red.withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  isSuccess ? "Success!" : "Error",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),

                const SizedBox(height: 10),

                // Divider
                Container(
                  height: 1,
                  width: 50,
                  color: Colors.grey.shade200,
                ),

                const SizedBox(height: 14),

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? Colors.green.shade600
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onClose?.call(); // Clear fields only on success
                    },
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}