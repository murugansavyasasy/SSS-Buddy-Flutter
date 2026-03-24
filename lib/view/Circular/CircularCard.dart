import 'package:flutter/material.dart';
import '../../../auth/model/CircularModel.dart';
import 'stat-chip.dart';

class Circularcard extends StatelessWidget {
  final Circularmodel item;
  const Circularcard({super.key, required this.item});

  String get _messageLabel {
    final raw = item.MessageId;
    final afterDash = raw.contains('--') ? raw.split('--')[1] : raw;
    final beforeTilde = afterDash.contains('~~')
        ? afterDash.split('~~')[0]
        : afterDash;
    return beforeTilde.trim();
  }

  Color get _messageColor {
    switch (_messageLabel.toLowerCase()) {
      case 'management':
        return const Color(0xFF1A3A5C);
      case 'absentees call':
        return Colors.orange.shade700;
      case 'staff call':
        return Colors.teal.shade700;
      default:
        return Colors.purple.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1A3A5C);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.SchoolName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _messageColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _messageLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tag_rounded, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'ID: ${item.SchoolId}',
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.Time,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.call_rounded,
                      size: 13,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Total Calls: ${item.TotalCalls}',
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: StatChip(
                        label: 'Connected',
                        value: item.Connected.toString(),
                        color: Colors.green.shade600,
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatChip(
                        label: 'Requested',
                        value: item.Requested.toString(),
                        color: Colors.orange.shade600,
                        icon: Icons.pending_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatChip(
                        label: 'Missed',
                        value: item.Missed.toString(),
                        color: Colors.red.shade400,
                        icon: Icons.call_missed_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
