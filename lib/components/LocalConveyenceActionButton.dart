import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class Localconveyenceactionbutton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;
  final bool isOnly;

  const Localconveyenceactionbutton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.onTap,
    this.isOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: bgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}