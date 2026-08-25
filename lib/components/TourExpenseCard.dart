import 'package:flutter/material.dart' hide VerticalDivider;
import 'package:sssbuddy/auth/model/AdvanceTourExpenseModel.dart';
import 'package:sssbuddy/view/move_to_toursettlement.dart';

import '../Values/Colors/app_colors.dart';
import '../view/ManagementInfo/widget/info_row.dart';
import '../view/advance_tour_expense_detail.dart';
import 'AmountTile.dart';

// ── Visibility Helper (mirrors Java logic exactly) ──────────────────────────
class ButtonVisibilityHelper {
  final Advancetourexpensemodel item;
  final String directorLogin;

  ButtonVisibilityHelper(this.item, this.directorLogin);

  String get _approved => item.isApproved.toString() ?? '';
  String get _claim    => item.isClaimed.toString()   ?? '';

  bool get canEditDelete =>
      (directorLogin != "3" && _approved == "0") || _approved == "2";

  bool get canMove => _claim == "1";
}

class TourExpenseCard extends StatelessWidget {
  final Advancetourexpensemodel item;
  final String directorLogin;

  const TourExpenseCard({
    super.key,
    required this.item,
    required this.directorLogin,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':     return const Color(0xFF22C55E);
      case 'pending':  return const Color(0xFFF59E0B);
      case 'rejected': return const Color(0xFFEF4444);
      default:         return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String empName      = item.EmpName          ?? '-';
    final String tourId       = item.TourId           ?? '-';
    final String tourName     = item.TourName         ?? '-';
    final String tourPurpose  = item.TourPurpose      ?? '-';
    final String date         = item.Date             ?? '-';
    final String tourPlace    = item.TourPlace        ?? '-';
    final String totalExpense =
        '${item.TotalTourExpense.toStringAsFixed(2)}';

    final String paidAmount =
        '${item.PaidAmount.toStringAsFixed(2)}';

    final String balanceAmount =
        '${item.BalanceAmount.toStringAsFixed(2)}';
    final String description  = item.Description      ?? '-';
    final String monthOfClaim = item.monthOfClaim     ?? '-';
    final String status       = item.Status           ?? 'Unknown';

    // ✅ Compute button visibility once
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withOpacity(0.4)),
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

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(icon: Icons.map_outlined,          label: "Tour",        value: tourName),
                const SizedBox(height: 6),
                InfoRow(icon: Icons.flag_outlined,         label: "Purpose",     value: tourPurpose),
                const SizedBox(height: 6),
                InfoRow(icon: Icons.calendar_today_outlined,label: "Date",       value: date),
                const SizedBox(height: 6),
                InfoRow(icon: Icons.location_on_outlined,  label: "Place",       value: tourPlace),
                const SizedBox(height: 6),
                InfoRow(icon: Icons.notes_outlined,        label: "Description", value: description),
                const SizedBox(height: 6),
                InfoRow(icon: Icons.event_note_outlined,   label: "Month",       value: monthOfClaim),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AmountTile(label: "Total",   amount: totalExpense,  color: AppColors.primary),
                      VerticalDivider(),
                      AmountTile(label: "Paid",    amount: paidAmount,    color: const Color(0xFF22C55E)),
                      VerticalDivider(),
                      AmountTile(label: "Balance", amount: balanceAmount, color: const Color(0xFFEF4444)),
                    ],
                  ),
                ),

                const SizedBox(height: 12),


                if (false && helper.canEditDelete) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {

                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text("Edit", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: handle delete
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 16),
                          label: const Text("Delete", style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    if (helper.canMove) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MoveToToursettlement(item: item),
                              ),
                            );
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text("Move to Settlement", style: TextStyle(fontSize: 12)),
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
                    ],

                    // Expanded(
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.of(context).push(
                    //         MaterialPageRoute(
                    //           builder: (_) => AdavanceTourExpenseDetail(item: item),
                    //         ),
                    //       );
                    //     },
                    //     icon: const Icon(Icons.info_outline_rounded, size: 16),
                    //     label: const Text("Details", style: TextStyle(fontSize: 12)),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: AppColors.primary,
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 10),
                    //       elevation: 0,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}