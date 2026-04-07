import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final bool isClosed;

  const StatusBadge({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isClosed
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isClosed ? 'Closed' : 'Open',
        style: TextStyle(
          color: isClosed ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}