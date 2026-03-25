import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/CustomerdetailsModel.dart';
import 'info_tilecustomer.dart';

class CustomerCardDetails extends StatelessWidget {
  final Customerdetailsmodel item;

  const CustomerCardDetails({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String customerName = item.customerName;
    final String billingCity = item.billingCity;
    final String billingPerson = item.billingPersonName;
    final String tallyId = item.tallyCustomerId;
    final String salesPerson = item.salesPersonName;
    final bool isActive = item.isActive;

    final String initials = customerName.trim().isNotEmpty
        ? customerName.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '??';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 13, color: Color(0xFF8E8EA0)),
                          const SizedBox(width: 3),
                          Text(
                            tallyId,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8EA0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'City',
                    value: billingCity,
                    iconColor: const Color(0xFFEF5350),
                  ),
                ),

                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFF0F0F5),
                ),

                Expanded(
                  child: InfoTile(
                    icon: Icons.person_outline,
                    label: 'Billing Person',
                    value: billingPerson,
                    iconColor: const Color(0xFF5C6BC0),
                  ),
                ),

                Container(
                  width: 1,
                  height: 36,
                  color: const Color(0xFFF0F0F5),
                ),

                Expanded(
                  child: InfoTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Sales Person',
                    value: salesPerson,
                    iconColor: const Color(0xFF26A69A),
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

