import 'package:flutter/material.dart';
import 'package:sssbuddy/auth/model/LocalConveyenceModel.dart';
import 'package:sssbuddy/components/LocalConveyenceActionButton.dart';
import 'package:url_launcher/url_launcher.dart';
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

  _StatusStyle _statusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return _StatusStyle(
          color: const Color(0xFF059669),
          bg: const Color(0xFFD1FAE5),
          icon: Icons.check_circle_rounded,
          gradient: [const Color(0xFF059669), const Color(0xFF10B981)],
        );
      case 'approved':
        return _StatusStyle(
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFDBEAFE),
          icon: Icons.verified_rounded,
          gradient: [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
        );
      case 'pending':
        return _StatusStyle(
          color: const Color(0xFFD97706),
          bg: const Color(0xFFFEF3C7),
          icon: Icons.schedule_rounded,
          gradient: [const Color(0xFFB45309), const Color(0xFFF59E0B)],
        );
      case 'rejected':
        return _StatusStyle(
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEE2E2),
          icon: Icons.cancel_rounded,
          gradient: [const Color(0xFFB91C1C), const Color(0xFFEF4444)],
        );
      default:
        return _StatusStyle(
          color: const Color(0xFF6B7280),
          bg: const Color(0xFFF3F4F6),
          icon: Icons.info_rounded,
          gradient: [const Color(0xFF4B5563), const Color(0xFF9CA3AF)],
        );
    }
  }

  Future<void> _openFile(String filePath) async {
    if (filePath.isEmpty) return;
    final uri = Uri.parse(filePath.replaceAll('\\', '/'));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(item.Status);
    final hasFile = item.FilePath != null && item.FilePath!.isNotEmpty;
    final userType = VimsUserTypeId ?? "";
    final approved = item.IsApproved;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: style.gradient),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(name: item.Username, gradient: style.gradient),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.Username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.RefId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),


                  _StatusBadge(
                    label: item.Status,
                    color: style.color,
                    bg: style.bg,
                    icon: style.icon,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InfoTileLocal(
                      icon: Icons.calendar_month_rounded,
                      label: "Month",
                      value: item.monthOfClaim,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InfoTileLocal(
                      icon: Icons.currency_rupee_rounded,
                      label: "Total Expense",
                      value: "₹ ${item.TotalLocalExpense.toStringAsFixed(2)}",
                      highlight: true,
                      accentGradient: style.gradient,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DescriptionRow(description: item.Description),
                  if (item.IsPaid == 1 && item.PaidDate.trim() != '-') ...[
                    const SizedBox(height: 10),
                    DetailRow(
                      icon: Icons.payments_rounded,
                      label: "Paid On",
                      value: item.PaidDate,
                      valueColor: const Color(0xFF059669),
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

            Container(height: 1, color: const Color(0xFFF1F5F9)),

            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildActionButtons(userType, approved),
              ),
            ),

            if (hasFile) ...[
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              _AttachmentButton(
                onTap: () => _openFile(item.FilePath!),
                gradient: style.gradient,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(String userType, int approved) {
    if (userType == "3" && approved == 0) {
      return [_detailsButton(isOnly: true)];
    } else if ((userType != "3" && approved == 0) || approved == 2) {
      return [
        _detailsButton(),
        _vDivider(),
        _editButton(),
        _vDivider(),
        _deleteButton(),
      ];
    }
    return [_detailsButton(isOnly: true)];
  }

  Widget _detailsButton({bool isOnly = false}) => Localconveyenceactionbutton(
    icon: Icons.info_outline_rounded,
    label: "Details",
    color: const Color(0xFF7C3AED),
    bgColor: const Color(0xFFF5F3FF),
    onTap: onDetails,
    isOnly: isOnly,
  );

  Widget _editButton() => Localconveyenceactionbutton(
    icon: Icons.edit_outlined,
    label: "Edit",
    color: const Color(0xFF2563EB),
    bgColor: const Color(0xFFEFF6FF),
    onTap: onEdit,
  );

  Widget _deleteButton() => Localconveyenceactionbutton(
    icon: Icons.delete_outline_rounded,
    label: "Delete",
    color: const Color(0xFFDC2626),
    bgColor: const Color(0xFFFEF2F2),
    onTap: onDelete,
  );

  Widget _vDivider() => Container(
    width: 1,
    color: const Color(0xFFF1F5F9),
  );
}

class _StatusStyle {
  final Color color;
  final Color bg;
  final IconData icon;
  final List<Color> gradient;
  const _StatusStyle({
    required this.color,
    required this.bg,
    required this.icon,
    required this.gradient,
  });
}

class _Avatar extends StatelessWidget {
  final String name;
  final List<Color> gradient;
  const _Avatar({required this.name, required this.gradient});

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final VoidCallback onTap;
  final List<Color> gradient;
  const _AttachmentButton({required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.map((c) => c.withOpacity(0.07)).toList(),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: gradient.first.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 14,
                color: gradient.first,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "View Attachment",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: gradient.first,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 10,
              color: gradient.first.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}