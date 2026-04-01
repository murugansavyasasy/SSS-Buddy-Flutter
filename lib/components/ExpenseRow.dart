import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ExpenseItem.dart';

class ExpenseRow extends StatelessWidget {
  final ExpenseItem item;
  final bool isLast;

  const ExpenseRow({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF444444),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "₹ ${item.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: item.amount > 0
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}