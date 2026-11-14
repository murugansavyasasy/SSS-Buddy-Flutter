import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final double height;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.height = 40,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.secondaryprimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryprimary,
            // Keep the brand colour while a spinner is showing.
            disabledBackgroundColor: isLoading
                ? AppColors.secondaryprimary.withValues(alpha: 0.7)
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    final Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: isOutlined ? AppColors.secondaryprimary : Colors.white,
            ),
          )
        : Text(
      text,
      style: TextStyle(
        fontSize: 15,
        color: isOutlined ? AppColors.secondaryprimary : Colors.white,
      ),
    );

    return SizedBox(
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed, // ← now safe (nullable → non-null coercion)
              style: buttonStyle,
              child: child,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: buttonStyle,
              child: child,
            ),
    );
  }
}
