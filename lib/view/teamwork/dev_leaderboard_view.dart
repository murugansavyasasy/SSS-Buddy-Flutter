import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/app_motion.dart';
import '../../components/glass_card.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import '../ticket/widget/ticket_common.dart' show TicketPersonAvatar, TicketPillSwitch;
import 'widget/teamwork_common.dart';

const _gold = Color(0xFFF2B01E);
const _silver = Color(0xFF9AA5B8);
const _bronze = Color(0xFFCD7F4A);

/// Developer leaderboard: points from finished tasks (priority, on time)
/// and completed milestones. The sales leaderboard stays separate.
class DevLeaderboardView extends ConsumerWidget {
  const DevLeaderboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(devPeriodProvider);
    final async = ref.watch(devLeaderboardProvider);
    final me = ref.watch(teamWorkUserProvider).value?.id ?? '';

    return TeamPage(
      title: 'Leaderboard',
      onRefresh: () {
        ref.invalidate(allTasksProvider);
        ref.invalidate(projectsProvider);
      },
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: TicketPillSwitch(
                  labels: [for (final p in DevPeriod.values) p.label],
                  selected: period.index,
                  onChanged: (i) => ref.read(devPeriodProvider.notifier).set(DevPeriod.values[i]),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      TeamStateView.error(e, title: "Couldn't load leaderboard", onRetry: () => ref.invalidate(allTasksProvider)),
                  data: (board) {
                    if (board.isEmpty) {
                      return const TeamStateView(
                        icon: Icons.emoji_events_outlined,
                        color: _gold,
                        title: 'No scores yet',
                        message: 'Finish tasks and milestones to climb the board.',
                      );
                    }
                    final top = board.take(3).toList();
                    final rest = board.skip(3).toList();
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(allTasksProvider),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          AppEntrance(child: _Podium(top: top, me: me)),
                          const SizedBox(height: 16),
                          const AppEntrance(index: 1, child: _HowPoints()),
                          const SizedBox(height: 16),
                          for (final (i, r) in rest.indexed)
                            AppEntrance(
                              index: 2 + i.clamp(0, 8),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RankRow(r: r, isMe: r.score.member.id == me),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<RankedDev> top;
  final String me;
  const _Podium({required this.top, required this.me});

  @override
  Widget build(BuildContext context) {
    // Order on screen: 2nd, 1st, 3rd.
    final slots = <(RankedDev?, Color, double)>[
      (top.length > 1 ? top[1] : null, _silver, 92),
      (top.isNotEmpty ? top[0] : null, _gold, 122),
      (top.length > 2 ? top[2] : null, _bronze, 72),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeGlass.navy, Color(0xFF2E4A86)],
        ),
        boxShadow: [BoxShadow(color: HomeGlass.navy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (r, c, h) in slots)
            Expanded(
              child: r == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        if (r.rank == 1) const Icon(Icons.workspace_premium_rounded, color: _gold, size: 28),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 3)),
                          child: CircleAvatar(
                            radius: r.rank == 1 ? 30 : 24,
                            backgroundColor: Colors.white,
                            child: TicketPersonAvatar(name: r.score.member.name, size: r.rank == 1 ? 58 : 46),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          r.score.member.id == me ? 'You' : r.score.member.name.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        Text('${r.score.points} pts',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 20, end: h),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          builder: (_, v, child) => Container(
                            height: v,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [c, c.withValues(alpha: 0.55)],
                              ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            ),
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.only(top: 8),
                            child: child,
                          ),
                          child: Text('${r.rank}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _HowPoints extends StatelessWidget {
  const _HowPoints();

  @override
  Widget build(BuildContext context) {
    Widget chip(IconData icon, String text, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: homePastel(c), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: homeDeep(c)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: homeDeep(c))),
              ),
            ],
          ),
        );
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How points work', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: teamInk)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              chip(Icons.flag_rounded, 'High 15 · Medium 10 · Low 5', HomeGlass.blue),
              chip(Icons.schedule_rounded, '+$kOnTimeBonus on time', HomeGlass.green),
              chip(Icons.running_with_errors_rounded, '−$kLatePenalty late', AppColors.danger),
              chip(Icons.outlined_flag_rounded, '+$kMilestoneBonus milestone', const Color(0xFFD97706)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final RankedDev r;
  final bool isMe;
  const _RankRow({required this.r, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final s = r.score;
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      color: isMe ? AppColors.tint : Colors.white,
      borderColor: isMe ? AppColors.primary.withValues(alpha: 0.4) : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${r.rank}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: teamSubtle)),
          ),
          const SizedBox(width: 6),
          TicketPersonAvatar(name: s.member.name, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '${s.member.name} (You)' : s.member.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: teamTitleStyle),
                const SizedBox(height: 2),
                Text(
                  '${s.tasksDone} done · ${(s.onTimeRate * 100).round()}% on time · ${s.milestones} milestones',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: teamSubtle),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${s.points}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: teamInk)),
              const Text('pts', style: TextStyle(fontSize: 11, color: teamSubtle)),
            ],
          ),
        ],
      ),
    );
  }
}
