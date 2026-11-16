import 'package:flutter/material.dart';

import '../../../auth/model/LeaderboardModel.dart';
import 'leaderboard_common.dart';

/// Top three as a podium: 2nd · 1st · 3rd, on a light card with
/// medal-tinted steps.
class Podium extends StatelessWidget {
  final List<RankedEntry> top;
  final LbMetric metric;

  const Podium({super.key, required this.top, required this.metric});

  @override
  Widget build(BuildContext context) {
    RankedEntry? at(int i) => i < top.length ? top[i] : null;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lbLine),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8E6), Colors.white],
        ),
        boxShadow: lbShadow,
      ),
      child: Stack(
        children: [
          // Soft decorative bubbles.
          Positioned(top: -40, left: -30, child: _bubble(120, medalGold, 0.10)),
          Positioned(top: 30, right: -24, child: _bubble(80, lbAccent, 0.08)),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _Step(item: at(1), metric: metric, height: 64),
                ),
                Expanded(
                  child: _Step(item: at(0), metric: metric, height: 92, first: true),
                ),
                Expanded(
                  child: _Step(item: at(2), metric: metric, height: 48),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color c, double a) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: a),
    ),
  );
}

class _Step extends StatelessWidget {
  final RankedEntry? item;
  final LbMetric metric;
  final double height;
  final bool first;

  const _Step({required this.item, required this.metric, required this.height, this.first = false});

  @override
  Widget build(BuildContext context) {
    final r = item;
    if (r == null) return const SizedBox.shrink();
    final e = r.entry;
    final medal = medalFor(r.rank);
    final avatar = first ? 70.0 : 56.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (first)
            const Icon(Icons.workspace_premium_rounded, color: medalGold, size: 30)
          else
            const SizedBox(height: 30),
          const SizedBox(height: 2),
          // Avatar with a soft medal glow.
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: medal.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
              ],
            ),
            child: MemberAvatar(name: e.member.name, size: avatar, ring: medal, highlight: e.isMe),
          ),
          const SizedBox(height: 8),
          Text(
            e.isMe ? 'You' : e.member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lbInk,
              fontWeight: FontWeight.w700,
              fontSize: first ? 14.5 : 13.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: medal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formatMetricValue(e.valueFor(metric), metric),
              style: TextStyle(
                color: Color.lerp(medal, Colors.black, 0.35),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Podium step.
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(medal, Colors.white, 0.45)!,
                  Color.lerp(medal, Colors.white, 0.80)!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                Text(
                  '${r.rank}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: first ? 30 : 24,
                    height: 1.1,
                    shadows: [Shadow(color: medal.withValues(alpha: 0.6), blurRadius: 6)],
                  ),
                ),
                if (metric == LbMetric.overall && height > 60) _PodiumChange(change: r.rankChange),
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
    return RankChange(change: c);
  }
}
