import 'package:flutter/cupertino.dart';

class MenuItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget page;

  const MenuItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.page,
  });
}