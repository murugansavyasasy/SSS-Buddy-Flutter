import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final Widget child;

  const AppCard({super.key, this.icon, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEFF8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                    Icon(icon, color: const Color(0xFF5C6BC0), size: 18),
                  ),
                const SizedBox(width: 8),
                Text(title!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20,color: const Color(0xFFD1D1D6)),
          ],
          child,
        ],
      ),
    );
  }
}