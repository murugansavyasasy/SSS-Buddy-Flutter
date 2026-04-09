import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide VerticalDivider;
import 'package:sssbuddy/auth/model/AdvanceTourExpenseModel.dart';
import 'package:sssbuddy/view/move_to_toursettlement.dart';

import '../Values/Colors/app_colors.dart';
import '../view/ManagementInfo/info_row.dart';
import '../view/advance_tour_expense_detail.dart';
import '../view/local_conveyence_detail.dart';
import 'AmountTile.dart';

class TourExpenseCard extends StatelessWidget {
  final Advancetourexpensemodel item;
  final String directorLogin;

  const TourExpenseCard({super.key, required this.item,required this.directorLogin});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF22C55E);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String empName = item.EmpName ?? '-';
    final String tourId = item.TourId ?? '-';
    final String tourName = item.TourName ?? '-';
    final String tourPurpose = item.TourPurpose ?? '-';
    final String date = item.Date ?? '-';
    final String tourPlace = item.TourPlace ?? '-';
    final String totalExpense = item.TotalTourExpense ?? '0.00';
    final String paidAmount = item.PaidAmount ?? '0.00';
    final String balanceAmount = item.BalanceAmount ?? '0.00';
    final String description = item.Description ?? '-';
    final String monthOfClaim = item.monthOfClaim ?? '-';
    final String status = item.Status ?? 'Unknown';
    final helper = ButtonVisibilityHelper(item, directorLogin);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    empName.isNotEmpty ? empName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + Tour ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        empName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tourId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor(status).withOpacity(0.4)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tour Name
                InfoRow(
                  icon: Icons.map_outlined,
                  label: "Tour",
                  value: tourName,
                ),
                const SizedBox(height: 6),
                // Purpose
                InfoRow(
                  icon: Icons.flag_outlined,
                  label: "Purpose",
                  value: tourPurpose,
                ),
                const SizedBox(height: 6),
                // Date
                InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: "Date",
                  value: date,
                ),
                const SizedBox(height: 6),
                // Tour Place
                InfoRow(
                  icon: Icons.location_on_outlined,
                  label: "Place",
                  value: tourPlace,
                ),
                const SizedBox(height: 6),
                // Description
                InfoRow(
                  icon: Icons.notes_outlined,
                  label: "Description",
                  value: description,
                ),
                const SizedBox(height: 6),
                // Month of Claim
                InfoRow(
                  icon: Icons.event_note_outlined,
                  label: "Month",
                  value: monthOfClaim,
                ),

                const SizedBox(height: 12),

                // ── Amount Row ──────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AmountTile(
                        label: "Total",
                        amount: totalExpense,
                        color: AppColors.primary,
                      ),
                      VerticalDivider(),
                      AmountTile(
                        label: "Paid",
                        amount: paidAmount,
                        color: const Color(0xFF22C55E),
                      ),
                      VerticalDivider(),
                      AmountTile(
                        label: "Balance",
                        amount: balanceAmount,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    // Move to Tour Settlement
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MoveToToursettlement(item: item),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text(
                          "Move to Settlement",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Details Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdavanceTourExpenseDetail(item: item),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          "Details",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Wrap(
                //   spacing: 8,
                //   runSpacing: 8,
                //   children: [
                //
                //     if (helper.canEditDelete)
                //       _actionButton(
                //         icon: Icons.edit,
                //         text: "Edit",
                //         color: Colors.blue,
                //         onTap: () {
                //           print("Edit Clicked");
                //         },
                //       ),
                //
                //     if (helper.canEditDelete)
                //       _actionButton(
                //         icon: Icons.delete,
                //         text: "Delete",
                //         color: Colors.red,
                //         onTap: () {
                //           print("Delete Clicked");
                //         },
                //       ),
                //
                //     if (helper.canMove)
                //       _actionButton(
                //         icon: Icons.swap_horiz,
                //         text: "Move to Settlement",
                //         color: AppColors.primary,
                //         onTap: () {
                //           Navigator.of(context).push(
                //             MaterialPageRoute(
                //               builder: (_) => MoveToToursettlement(item: item),
                //             ),
                //           );
                //         },
                //       ),
                //     _actionButton(
                //       icon: Icons.info_outline,
                //       text: "Details",
                //       color: AppColors.primary,
                //       isFilled: true,
                //       onTap: () {
                //         Navigator.of(context).push(
                //           MaterialPageRoute(
                //             builder: (_) => AdavanceTourExpenseDetail(item: item),
                //           ),
                //         );
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
Widget _actionButton({
  required IconData icon,
  required String text,
  required Color color,
  required VoidCallback onTap,
  bool isFilled = false,
}) {
  return SizedBox(
    height: 36,
    child: isFilled
        ? ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    )
        : OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    ),
  );
}