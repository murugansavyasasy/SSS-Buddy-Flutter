import 'package:flutter/material.dart';

import '../values/colors/app_colors.dart';

class CustomPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;

  /// When set, shown as a title above the field and [hintText] becomes the
  /// placeholder (no floating label).
  final String? title;
  final String? hintText;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomPasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.prefixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.title,
    this.hintText,
  });

  @override
  State<CustomPasswordField> createState() => _CustomPasswordFieldState();
}

class _CustomPasswordFieldState extends State<CustomPasswordField> {
  bool isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      obscureText: isPasswordHidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.title == null ? widget.labelText : null,
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Color(0xFF9AA3B2), fontWeight: FontWeight.w400),
        prefixIcon:
            widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: AppColors.grey),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordHidden ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              isPasswordHidden = !isPasswordHidden;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
    if (widget.title == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            widget.title!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        field,
      ],
    );
  }
}
