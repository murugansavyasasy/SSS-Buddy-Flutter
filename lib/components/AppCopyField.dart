import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppCopyField extends StatelessWidget {
  final String label;
  final String value;

  const AppCopyField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (value.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$label copied"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Icon(Icons.copy_outlined,
                size: 18, color: Color(0xFF5C6BC0)),
          ),
        ],
      ),
    );
  }
}