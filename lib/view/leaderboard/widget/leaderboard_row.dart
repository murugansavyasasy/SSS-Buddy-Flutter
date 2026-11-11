import 'package:flutter/material.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/LeaderboardModel.dart';
import 'leaderboard_common.dart';

class LeaderboardRow extends StatelessWidget {
  final RankedEntry item;
  final LbMetric metric;

  const LeaderboardRow({super.key, required this.item, required this.metric});

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final progress = e.progressFor(metric);
    final sub = metric == LbMetric.overall
        ? (e.member.role.isNotEmpty ? e.member.role : 'Sales')
        : targetLine(e, metric);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
      decoration: BoxDecoration(
        color: e.isMe ? const Color(0xFFEDF2FC) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.isMe
              ? AppColors.primary.withOpacity(0.35)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  '${item.rank}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                if (metric == LbMetric.overall)
                  RankChange(change: item.rankChange),
              ],
            ),
          ),
          const SizedBox(width: 6),
          MemberAvatar(name: e.member.name, size: 40, highlight: e.isMe),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (e.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 7),
                // Progress to target (single series → one hue, 4px rounded).
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE8EDF6),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMetricValue(e.valueFor(metric), metric),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (metric != LbMetric.overall)
                Text(
                  '${(e.scores[metric]?.ratio ?? 0) * 100 ~/ 1}%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
