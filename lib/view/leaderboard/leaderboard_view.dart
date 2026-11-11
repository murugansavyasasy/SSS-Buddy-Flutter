import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/LeaderboardModel.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/leaderboard_viewmodel.dart';
import 'widget/leaderboard_common.dart';
import 'widget/leaderboard_row.dart';
import 'widget/podium.dart';

class LeaderboardView extends ConsumerWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranked = ref.watch(rankedLeaderboardProvider);
    final metric = ref.watch(leaderboardMetricProvider);
    final period = ref.watch(leaderboardPeriodProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: 'Leaderboard',
              onRefresh: () => ref.invalidate(leaderboardProvider),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _Filters(period: period, metric: metric),
                    Expanded(
                      child: ranked.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (list) => _Board(list: list, metric: metric),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  final LbPeriod period;
  final LbMetric metric;

  const _Filters({required this.period, required this.metric});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: [
          // Period: segmented control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                for (final p in LbPeriod.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(leaderboardPeriodProvider.notifier).set(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: p == period
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: p == period
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Metric chips (few, so built eagerly in a scrolling row)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in LbMetric.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _metricChip(ref, m, m == metric),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _metricChip(WidgetRef ref, LbMetric m, bool selected) {
  return ChoiceChip(
    showCheckmark: false,
    avatar: Icon(m.icon,
        size: 16,
        color: selected ? AppColors.primary : const Color(0xFF64748B)),
    label: Text(m.label),
    selected: selected,
    onSelected: (_) => ref.read(leaderboardMetricProvider.notifier).set(m),
    selectedColor: AppColors.primary.withOpacity(0.12),
    backgroundColor: Colors.white,
    side: BorderSide(
      color: selected
          ? AppColors.primary.withOpacity(0.4)
          : const Color(0xFFE2E8F0),
    ),
    labelStyle: TextStyle(
      fontSize: 12.5,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      color: selected ? AppColors.primary : const Color(0xFF475569),
    ),
  );
}

class _Board extends StatelessWidget {
  final List<RankedEntry> list;
  final LbMetric metric;

  const _Board({required this.list, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Text('No data for this period',
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    final top = list.take(3).toList();
    final rest = list.skip(3).toList();
    final meIndex = list.indexWhere((r) => r.entry.isMe);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Podium(top: top, metric: metric),
              const SizedBox(height: 14),
              if (metric == LbMetric.overall) const _ScoreHint(),
              for (final r in rest)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardRow(item: r, metric: metric),
                ),
            ],
          ),
        ),
        if (meIndex >= 0) _MyRankBar(list: list, meIndex: meIndex, metric: metric),
      ],
    );
  }
}

class _ScoreHint extends StatelessWidget {
  const _ScoreHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Overall = average % of target across Demos, POs, PO Value and Collection',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRankBar extends StatelessWidget {
  final List<RankedEntry> list;
  final int meIndex;
  final LbMetric metric;

  const _MyRankBar({
    required this.list,
    required this.meIndex,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final me = list[meIndex];
    final ahead = list
        .take(meIndex)
        .where((r) => r.rank < me.rank)
        .lastOrNull;

    final String message;
    if (me.rank == 1) {
      message = "You're leading — keep it up! 🏆";
    } else if (ahead != null) {
      final gap = ahead.entry.valueFor(metric) - me.entry.valueFor(metric);
      message =
          '${formatGap(gap, metric)} behind #${ahead.rank} ${ahead.entry.member.name.split(' ').first}';
    } else {
      message = '';
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.secondaryprimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${me.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your rank · ${list.length} people',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatMetricValue(me.entry.valueFor(metric), metric),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
