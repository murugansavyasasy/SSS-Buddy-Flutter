import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF4F6693);
  static const Color secondaryprimary = Color(0xFF2C4463);
  static const Color primaryDark = Color(0xFF24395A);
  static const Color accent = Color(0xFF5B7BD5);
  static const Color tint = Color(0xFFECF0FA);

  // Neutrals
  static const Color grey = Color(0xFFD6D6D6);
  static const Color secondary = Color(0xFF81ADFB);
  static const Color background = Color(0xFFF5F5F5);
  static const Color pageBg = Color(0xFFF4F6FA);
  static const Color white = Colors.white;
  static const Color ink = Color(0xFF1E2B45);
  static const Color subtle = Color(0xFF6B7280);
  static const Color border = Color(0xFFE3E7EF);

  // Status
  static const Color success = Color(0xFF1A9B5B);
  static const Color warning = Color(0xFFE08A1E);
  static const Color danger = Color(0xFFD93A3A);

  /// Screen header: deep navy at the top fading into [primary], so it joins
  /// the primary-coloured scaffold behind the rounded body seamlessly.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, Color(0xFF3A5383), primary],
    stops: [0.0, 0.55, 1.0],
  );
}
