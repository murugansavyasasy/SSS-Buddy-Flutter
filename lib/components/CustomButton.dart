import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // ← keep it nullable
  final bool isOutlined;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.height = 48,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    final child = Text(
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
