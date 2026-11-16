import 'package:flutter/material.dart';

import '../values/colors/app_colors.dart';
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(
          color: AppColors.grey,
        ),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}