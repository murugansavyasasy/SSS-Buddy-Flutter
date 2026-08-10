import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/CustomerdetailsModel.dart';

class HeaderCard extends StatelessWidget {
  final Customerdetailsmodel item;
  const HeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isActive = item.status.toLowerCase() == 'active';
    final customerName = item.customerName ?? '';
    final customerTypeName = item.customerTypeName ?? '';
    final customerBranchType = item.customerBranchType ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "STATUS: ${item.status.toUpperCase()}",
              style: TextStyle(
                fontSize: 11,
                color: isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.companyName,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.domain, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tags  (customerTypeName  +  customerBranchType) ───────
        Row(
          children: [
            if (customerTypeName.isNotEmpty)
              _TagChip(label: customerTypeName.toUpperCase()),
            const SizedBox(width: 8),
            if (customerBranchType.isNotEmpty)
              _TagChip(label: customerBranchType),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEFF8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF5C6BC0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}