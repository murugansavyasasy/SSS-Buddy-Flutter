import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/InfoRowData.dart';

class Importantinforow extends StatelessWidget {
  final InfoRowData data;
  final bool showDivider;
  const Importantinforow({required this.data, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(data.icon, color: data.iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final values = data.value.split(',');

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: values.map((v) {
                              return Text(
                                v.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: data.isLink || data.onTap != null
                                      ? const Color(0xFF185FA5)
                                      : const Color(0xFF1A1A1A),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (data.onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade300, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, color: Colors.black.withOpacity(0.07),
              indent: 62),
      ],
    );
  }
}