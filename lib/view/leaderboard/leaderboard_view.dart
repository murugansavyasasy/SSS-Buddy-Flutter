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
                  color: lbPage,
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
                            const Center(child: CircularProgressIndicator(color: lbAccent)),
                        error: (e, _) => Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 40, color: lbMuted),
                                const SizedBox(height: 8),
                                Text(
                                  '$e',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: lbMuted),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () => ref.invalidate(leaderboardProvider),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ),
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
    final index = LbPeriod.values.indexOf(period);
    final count = LbPeriod.values.length;
    return _Centered(
      maxWidth: lbMaxWidth + 32,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Column(
          children: [
            // Period: tabs with a sliding white pill.
            Container(
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDF4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(count == 1 ? 0 : -1 + 2 * index / (count - 1), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / count,
                      heightFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A111827),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final p in LbPeriod.values)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              ref.read(leaderboardPeriodProvider.notifier).set(p);
                            },
                            child: Center(
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: p == period ? FontWeight.w700 : FontWeight.w500,
                                  color: p == period ? lbInk : lbMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Metric chips.
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final m in LbMetric.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MetricChip(
                        metric: m,
                        selected: m == metric,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(leaderboardMetricProvider.notifier).set(m);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final LbMetric metric;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({required this.metric, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: selected ? lbProgress : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : lbLine),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x334F6693), blurRadius: 10, offset: Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(metric.icon, size: 16, color: selected ? Colors.white : lbMuted),
            const SizedBox(width: 6),
            Text(
              metric.label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : lbInk,
              ),
            ),
          ],
        ),
      ),
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 44, color: lbMuted),
            SizedBox(height: 8),
            Text('No data for this period', style: TextStyle(color: lbMuted, fontSize: 14)),
          ],
        ),
      );
    }
    final top = list.take(3).toList();
    final rest = list.skip(3).toList();
    final meIndex = list.indexWhere((r) => r.entry.isMe);
    final bottomPad = meIndex >= 0 ? 110.0 : 24.0;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            bottomPad + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Centered(
              child: Podium(top: top, metric: metric),
            ),
            const SizedBox(height: 18),
            if (metric == LbMetric.overall) const _Centered(child: _ScoreHint()),
            if (rest.isNotEmpty)
              const _Centered(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10, left: 2),
                  child: Text(
                    'Rankings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: lbInk),
                  ),
                ),
              ),
            for (final r in rest)
              _Centered(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: LeaderboardRow(item: r, metric: metric),
                ),
              ),
          ],
        ),
        if (meIndex >= 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MyRankBar(list: list, meIndex: meIndex, metric: metric),
          ),
      ],
    );
  }
}

/// Centres a full-width child and caps its width on tablets.
class _Centered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const _Centered({required this.child, this.maxWidth = lbMaxWidth});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class _ScoreHint extends StatelessWidget {
  const _ScoreHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: lbTint, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: lbAccent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Overall = average % of target across Demos, POs, PO Value and Collection',
              style: TextStyle(fontSize: 11.5, color: lbAccentDeep),
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

  const _MyRankBar({required this.list, required this.meIndex, required this.metric});

  @override
  Widget build(BuildContext context) {
    final me = list[meIndex];
    final ahead = list.take(meIndex).where((r) => r.rank < me.rank).lastOrNull;

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

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: lbMaxWidth + 32),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lbAccent, lbAccentDeep],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0x402C4463), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
                          color: Colors.white.withValues(alpha: 0.75),
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
                const SizedBox(width: 8),
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
          ),
        ),
      ),
    );
  }
}
