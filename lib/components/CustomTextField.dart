import 'package:flutter/material.dart';

import '../values/colors/app_colors.dart';

/// Field title shown above a text field (e.g. "Employee ID").
Widget _fieldTitle(String text) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;

  /// When set, shown as a title above the field and [hintText] becomes the
  /// placeholder (no floating label).
  final String? title;
  final String? hintText;
  final TextInputType? keyboardType;
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
    this.title,
    this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: title == null ? labelText : null,
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.w400),
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
    if (title == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_fieldTitle(title!), field],
    );
  }
}
