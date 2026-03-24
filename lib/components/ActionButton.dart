import 'package:flutter/cupertino.dart';

import 'ActionButtonState.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  State<ActionButton> createState() => ActionButtonState();
}