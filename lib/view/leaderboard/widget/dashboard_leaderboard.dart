import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/LeaderboardModel.dart';
import '../../../utils/routes/routes_name.dart';
import '../../../viewModel/leaderboard_viewmodel.dart';
import 'leaderboard_common.dart';

/// Home page section: this month's top 3 plus the user's own rank.
class DashboardLeaderboard extends ConsumerWidget {
  const DashboardLeaderboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardLeaderboardProvider);

    // Hide the section entirely if it can't load; the rest of home still works.
    if (async.hasError) return const SizedBox.shrink();

    void openFull() {
      ref.read(leaderboardPeriodProvider.notifier).set(LbPeriod.month);
      ref.read(leaderboardMetricProvider.notifier).set(LbMetric.overall);
      Navigator.pushNamed(context, RoutesName.leaderboard);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text(
              '· This Month',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: openFull,
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: openFull,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: async.when(
              loading: () => const _Skeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (list) => _content(list),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(List<RankedEntry> list) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No leaderboard data yet'),
      );
    }
    final top = list.take(3).toList();
    final me = list.where((r) => r.entry.isMe).firstOrNull;
    final meInTop = me != null && top.any((r) => r.entry.isMe);

    return Column(
      children: [
        for (var i = 0; i < top.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _Row(item: top[i]),
        ],
        if (me != null && !meInTop) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.more_horiz_rounded,
                      size: 16, color: Colors.grey.shade400),
                ),
                const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
          ),
          _Row(item: me),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final RankedEntry item;
  const _Row({required this.item});

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final top3 = item.rank <= 3;
    final score = e.overallScore;

    return Container(
      margin: EdgeInsets.symmetric(vertical: e.isMe && !top3 ? 6 : 0),
      padding: EdgeInsets.symmetric(
          vertical: 10, horizontal: e.isMe && !top3 ? 10 : 0),
      decoration: e.isMe && !top3
          ? BoxDecoration(
              color: const Color(0xFFEDF2FC),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Row(
        children: [
          // Rank: medal for top 3, plain number otherwise
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: top3 ? medalFor(item.rank) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${item.rank}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: top3 ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 10),
          MemberAvatar(name: e.member.name, size: 34, highlight: e.isMe),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.isMe ? 'You' : e.member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: e.isMe ? FontWeight.w700 : FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE8EDF6),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.round()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                RankChange(change: item.rankChange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2F7),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                bar(26, 26),
                const SizedBox(width: 10),
                bar(34, 34),
                const SizedBox(width: 10),
                Expanded(child: bar(double.infinity, 12)),
                const SizedBox(width: 12),
                bar(40, 14),
              ],
            ),
          ),
      ],
    );
  }
}
