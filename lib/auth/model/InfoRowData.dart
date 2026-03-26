import 'package:flutter/cupertino.dart';

class InfoRowData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  InfoRowData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });
}