import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';

class SalesSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const SalesSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item.salesPersonName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF5C6BC0),
            child: Text(
              initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ACCOUNT MANAGER",
                style: TextStyle(
                    fontSize: 10, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                name.isEmpty ? '-' : name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}