import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../auth/model/ManagementInfo.dart';
import 'info_row.dart';

class MemberCard extends StatelessWidget {
  final Managementinfo member;
  final int index;
  const MemberCard({required this.member, required this.index});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1A3A5C);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: teal,
                  child: Text(
                    member.memberName.isNotEmpty
                        ? member.memberName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.memberName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (member.designation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          member.designation,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    member.memberType,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'Mobile',
                  value: member.mobileNumber.isNotEmpty
                      ? member.mobileNumber
                      : '-',
                ),
                if (member.appPassword.isNotEmpty) ...[
                  const Divider(height: 16),
                  InfoRow(
                    icon: Icons.lock_rounded,
                    label: 'App Password',
                    value: member.appPassword,
                  ),
                ],
                if (member.ivrPassword.isNotEmpty) ...[
                  const Divider(height: 16),
                  InfoRow(
                    icon: Icons.dialpad_rounded,
                    label: 'IVR Password',
                    value: member.ivrPassword,
                  ),
                ],
                const Divider(height: 16),
                InfoRow(
                  icon: Icons.badge_rounded,
                  label: 'Member ID',
                  value: member.memberId.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}