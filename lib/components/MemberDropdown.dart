import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/ReportingMembersModel.dart';
import 'UserTypeBadge.dart';

class MemberDropdown extends StatelessWidget {
  final List<Reportingmembersmodel> members;
  final Reportingmembersmodel? selected;
  final ValueChanged<Reportingmembersmodel?> onChanged;

  const MemberDropdown({
    required this.members,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Reportingmembersmodel>(
          isExpanded: true,
          hint: const Text(
            'Select Member',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          value: selected,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: members
              .map(
                (m) => DropdownMenuItem<Reportingmembersmodel>(
                  value: m,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: Text(
                          m.membername.isNotEmpty
                              ? m.membername[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m.membername,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // UserTypeBadge(usertype: m.usertype),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
