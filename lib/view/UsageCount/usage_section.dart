import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sssbuddy/view/UsageCount/value_chip.dart';

class UsageSection extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, String>> values;
  final Color borderColor;
  final bool isLast;

  const UsageSection({
    required this.sectionTitle,
    required this.values,
    required this.borderColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
          bottom: isLast ? BorderSide.none : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),


          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: values.length == 1

                ? ValueChip(
              title: values[0]['title']!,
              value: values[0]['value']!,
              fullWidth: true,
            )

                : Row(
              children: [
                Expanded(
                  child: ValueChip(
                    title: values[0]['title']!,
                    value: values[0]['value']!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueChip(
                    title: values[1]['title']!,
                    value: values[1]['value']!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}