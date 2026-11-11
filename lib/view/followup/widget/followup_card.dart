import 'package:flutter/material.dart';

import '../../../auth/model/FollowUpModel.dart';
import 'followup_common.dart';

class FollowUpCard extends StatelessWidget {
  final FollowUp item;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onDone;
  final VoidCallback? onReschedule;

  const FollowUpCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onCall,
    this.onDone,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = followUpDueLabel(item);
    final type = item.type;
    final hasPhone = item.contactPhone.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status stripe
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(type.icon, color: type.color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.schoolName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      type.label,
                                      if (item.contactName.isNotEmpty)
                                        item.contactName,
                                      if (hasPhone) item.contactPhone,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              item.isPending
                                  ? Icons.schedule_rounded
                                  : Icons.check_circle_rounded,
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (item.isPending && item.remindBefore >= 0)
                              const Icon(Icons.notifications_active_outlined,
                                  size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                        if (item.note.isNotEmpty || item.outcome.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            item.isPending || item.outcome.isEmpty
                                ? item.note
                                : 'Outcome: ${item.outcome}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (item.isPending) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (hasPhone)
                                _action(Icons.call_rounded, 'Call',
                                    const Color(0xFF15803D), onCall),
                              _action(Icons.update_rounded, 'Reschedule',
                                  upcomingColor, onReschedule),
                              _action(Icons.check_rounded, 'Done', doneColor,
                                  onDone,
                                  filled: true),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback? onTap,
      {bool filled = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: filled ? Colors.white : color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: filled ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
