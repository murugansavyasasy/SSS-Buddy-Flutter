import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sssbuddy/auth/model/LocalConveyenceModel.dart';
import 'package:sssbuddy/components/LocalConveyenceActionButton.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Values/Colors/app_colors.dart';
import 'description_row_local.dart';
import 'detail_row.dart';
import 'info_tile_local.dart';

class LocalConveyenceCard extends StatelessWidget {
  final Localconveyencemodel item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDetails;
  final String? VimsUserTypeId;

  const LocalConveyenceCard({
    super.key,
    required this.item,
    this.VimsUserTypeId,
    this.onEdit,
    this.onDelete,
    this.onDetails,
  });

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF22C55E);
      case 'approved':
        return const Color(0xFF3B82F6);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFFDCFCE7);
      case 'approved':
        return const Color(0xFFDBEAFE);
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.access_time_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Future<void> _openFile(String filePath) async {
    if (filePath.isEmpty) return;
    final cleanedPath = filePath.replaceAll('\\', '/');
    final uri = Uri.parse(cleanedPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.Status);
    final statusBg = _statusBgColor(item.Status);
    final statusIcon = _statusIcon(item.Status);
    final hasFile = item.FilePath != null && item.FilePath!.isNotEmpty;



    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    _initials(item.Username),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.Username,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.RefId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        item.Status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    InfoTileLocal(
                      icon: Icons.calendar_month_rounded,
                      label: "Month",
                      value: item.monthOfClaim,
                    ),
                    const SizedBox(width: 12),
                    InfoTileLocal(
                      icon: Icons.currency_rupee_rounded,
                      label: "Total Expense",
                      value: "₹ ${item.TotalLocalExpense.toStringAsFixed(2)}",
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                DescriptionRow(description: item.Description),

                if (item.IsPaid == 1 && item.PaidDate.trim() != '-') ...[
                  const SizedBox(height: 10),
                  DetailRow(
                    icon: Icons.payments_rounded,
                    label: "Paid On",
                    value: item.PaidDate,
                    valueColor: const Color(0xFF22C55E),
                  ),
                ],

                if (item.Remarks != null && item.Remarks!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DetailRow(
                    icon: Icons.comment_rounded,
                    label: "Remarks",
                    value: item.Remarks!,
                  ),
                ],
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                if (VimsUserTypeId == 3 && item.IsApproved == 0)...[
                  Localconveyenceactionbutton(
                    icon: Icons.info_rounded,
                    label: "Details",
                    color: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                    onTap: onDetails,
                    borderRadius: hasFile
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  _VerticalDivider(),
                ] else if((VimsUserTypeId == 3 && item.IsApproved == 0) || (item.IsApproved ==2))...[
                  Localconveyenceactionbutton(
                    icon: Icons.info_rounded,
                    label: "Details",
                    color: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                    onTap: onDetails,
                    borderRadius: hasFile
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  _VerticalDivider(),
                  Localconveyenceactionbutton(
                    icon: Icons.edit_rounded,
                    label: "Edit",
                    color: const Color(0xFF3B82F6),
                    bgColor: const Color(0xFFEFF6FF),
                    onTap: onEdit,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                    ),
                  ),
                  _VerticalDivider(),
                  Localconveyenceactionbutton(
                    icon: Icons.delete_rounded,
                    label: "Delete",
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEF2F2),
                    onTap: onDelete,
                  ),
                  _VerticalDivider(),
                ] else ...[
                  Localconveyenceactionbutton(
                    icon: Icons.info_rounded,
                    label: "Details",
                    color: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF5F3FF),
                    onTap: onDetails,
                    borderRadius: hasFile
                        ? BorderRadius.zero
                        : const BorderRadius.only(
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                ]
              ],
            ),
          ),

          if (hasFile)
            InkWell(
              onTap: () => _openFile(item.FilePath!),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      "View Attachment",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;
}



class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.grey.shade100);
  }
}