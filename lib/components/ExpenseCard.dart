import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ExpenseItem.dart';
import 'ExpenseRow.dart';

class ExpenseCard extends StatelessWidget {
  final List<ExpenseItem> items;
  final String totalLabel;
  final double total;
  final Color accentColor;

  const ExpenseCard({
    required this.items,
    required this.totalLabel,
    required this.total,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems =
    items.where((e) => e.amount > 0).toList();
    final displayItems = visibleItems.isEmpty ? items : visibleItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ...displayItems.asMap().entries.map((entry) {
            final isLast = entry.key == displayItems.length - 1;
            return ExpenseRow(
              item: entry.value,
              isLast: isLast,
            );
          }),

          Container(
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalLabel,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
                Text(
                  "₹ ${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
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