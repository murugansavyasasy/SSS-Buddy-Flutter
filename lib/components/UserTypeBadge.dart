import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserTypeBadge extends StatelessWidget {
  final int usertype;

  const UserTypeBadge({required this.usertype});

  @override
  Widget build(BuildContext context) {
    final isManager = usertype == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isManager
            ? Colors.blue.withOpacity(0.1)
            : Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isManager ? 'Manager' : 'Field',
        style: TextStyle(
          fontSize: 10,
          color: isManager ? Colors.blue.shade700 : Colors.purple.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}