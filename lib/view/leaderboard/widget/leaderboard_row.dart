import 'package:flutter/material.dart';

import '../../../auth/model/LeaderboardModel.dart';
import 'leaderboard_common.dart';

/// One person below the podium: rank badge, avatar, name, progress to
/// target and the metric value.
class LeaderboardRow extends StatelessWidget {
  final RankedEntry item;
  final LbMetric metric;

  const LeaderboardRow({super.key, required this.item, required this.metric});

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final progress = e.progressFor(metric).clamp(0.0, 1.0).toDouble();
    final sub = metric == LbMetric.overall
        ? (e.member.role.isNotEmpty ? e.member.role : 'Sales')
        : targetLine(e, metric);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        color: e.isMe ? lbTint : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: e.isMe ? lbAccent.withValues(alpha: 0.35) : lbLine),
        boxShadow: lbShadow,
      ),
      child: Row(
        children: [
          // Rank badge (+ movement for Overall).
          SizedBox(
            width: 36,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e.isMe ? lbAccent : lbPage,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${item.rank}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: e.isMe ? Colors.white : lbInk,
                    ),
                  ),
                ),
                if (metric == LbMetric.overall) ...[
                  const SizedBox(height: 2),
                  RankChange(change: item.rankChange),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          MemberAvatar(name: e.member.name, size: 42, highlight: e.isMe),
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
                          fontWeight: FontWeight.w700,
                          color: lbInk,
                        ),
                      ),
                    ),
                    if (e.isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: lbProgress,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
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
                  style: const TextStyle(fontSize: 11.5, color: lbMuted),
                ),
                const SizedBox(height: 8),
                _ProgressBar(value: progress),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatMetricValue(e.valueFor(metric), metric),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: lbInk),
              ),
              if (metric != LbMetric.overall) ...[
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: lbTint, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    '${(e.scores[metric]?.ratio ?? 0) * 100 ~/ 1}%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: lbAccentDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// 6 px rounded progress bar with a gradient fill.
class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) => Container(
    height: 6,
    decoration: BoxDecoration(
      color: const Color(0xFFE8EDF6),
      borderRadius: BorderRadius.circular(6),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: value,
      child: Container(
        decoration: BoxDecoration(gradient: lbProgress, borderRadius: BorderRadius.circular(6)),
      ),
    ),
  );
}
