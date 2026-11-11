import 'package:flutter/material.dart';

import '../../../auth/model/LeaderboardModel.dart';
import 'leaderboard_common.dart';

/// Top three as a podium: 2nd · 1st · 3rd.
class Podium extends StatelessWidget {
  final List<RankedEntry> top;
  final LbMetric metric;

  const Podium({super.key, required this.top, required this.metric});

  @override
  Widget build(BuildContext context) {
    RankedEntry? at(int i) => i < top.length ? top[i] : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F6693), Color(0xFF2C4463)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Step(item: at(1), metric: metric, height: 70)),
          Expanded(child: _Step(item: at(0), metric: metric, height: 96, first: true)),
          Expanded(child: _Step(item: at(2), metric: metric, height: 54)),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final RankedEntry? item;
  final LbMetric metric;
  final double height;
  final bool first;

  const _Step({
    required this.item,
    required this.metric,
    required this.height,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = item;
    if (r == null) return const SizedBox.shrink();
    final e = r.entry;
    final medal = medalFor(r.rank);
    final avatar = first ? 64.0 : 52.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (first)
            const Icon(Icons.workspace_premium_rounded, color: medalGold, size: 26)
          else
            const SizedBox(height: 26),
          const SizedBox(height: 2),
          MemberAvatar(
            name: e.member.name,
            size: avatar,
            ring: medal,
            highlight: e.isMe,
          ),
          const SizedBox(height: 8),
          Text(
            e.isMe ? 'You' : e.member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatMetricValue(e.valueFor(metric), metric),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(first ? 0.22 : 0.14),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: medal, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    '${r.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (metric == LbMetric.overall && height > 60) ...[
                  const SizedBox(height: 4),
                  _PodiumChange(change: r.rankChange),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumChange extends StatelessWidget {
  final int? change;

  const _PodiumChange({required this.change});

  @override
  Widget build(BuildContext context) {
    final c = change;
    if (c == null || c == 0) return const SizedBox.shrink();
    return Text(
      c > 0 ? '▲ ${c.abs()}' : '▼ ${c.abs()}',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: c > 0 ? const Color(0xFF9BE8B8) : const Color(0xFFFFB4B4),
      ),
    );
  }
}
