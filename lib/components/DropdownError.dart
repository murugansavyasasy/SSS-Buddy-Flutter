import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DropdownError extends StatelessWidget {
  final String label;
  final VoidCallback onRetry;
  const DropdownError({required this.label, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Failed to load $label",
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Retry",
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}