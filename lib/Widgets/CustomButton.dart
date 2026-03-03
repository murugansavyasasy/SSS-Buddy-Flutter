import 'package:flutter/material.dart';
import '../Values/Colors/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        height: height,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}