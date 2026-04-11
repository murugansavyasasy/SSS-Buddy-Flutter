import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../auth/model/AlertModel.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;

  const AlertCard({required this.alert});

  bool get _isLowCredit =>
      alert.alertType.toLowerCase().contains('low credit');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isLowCredit
              ? Colors.red.shade100
              : Colors.orange.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isLowCredit
                    ? Colors.red.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _isLowCredit
                    ? Icons.credit_card_off_outlined
                    : Icons.search_off_rounded,
                color: _isLowCredit ? Colors.red : Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          alert.alertTitle,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _isLowCredit
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "#${alert.id}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    alert.alertContent,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        alert.createdOn,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                      const Spacer(),
                      const Icon(Icons.source_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          alert.createdFrom,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}