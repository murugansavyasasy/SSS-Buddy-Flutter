import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/OverallTripDetailsModel.dart';

class VisitTile extends StatelessWidget {
  final VisitDetail visit; // ← change from dynamic

  const VisitTile({required this.visit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              visit.school_name ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (visit.reason_of_visit != null &&
                visit.reason_of_visit!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      visit.reason_of_visit!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}