import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/app_motion.dart';
import '../../components/glass_card.dart';
import '../../components/header_toolbar.dart';
import '../../components/toolbar_layout.dart';
import '../../core/notifications/local_notifications.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import '../../viewModel/ticket_viewmodel.dart';
import 'task_list_view.dart';
import 'widget/teamwork_common.dart';

/// Team Work hub. Developers (roleCode "Developer") land here instead of
/// the sales dashboard; Admin opens it from the "Team Work" menu to assign
/// tasks, manage projects and post announcements.
class DevDashboardView extends ConsumerWidget {
  const DevDashboardView({super.key});

  Future<void> _confirmExit(BuildContext context) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (exit == true) SystemNavigator.pop();
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(tasksProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(announcementsProvider);
    ref.invalidate(ticketsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(teamWorkUserProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    // Home for developers: run the notification checks the sales dashboard
    // normally runs, and open a tapped notification.
    ref.watch(teamNotificationWatchProvider);
    if (!isAdmin) {
      ref.watch(ticketCompletionWatchProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) => LocalNotifications.instance.flushPending());
    }

    final tasksAsync = ref.watch(tasksProvider);
    final body = tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => TeamStateView.error(e, title: "Couldn't load your work", onRetry: () => _refresh(ref)),
      data: (tasks) => RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: _Content(tasks: tasks, isAdmin: isAdmin, name: user?.name ?? ''),
      ),
    );

    return PopScope(
      canPop: isAdmin,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              if (isAdmin)
                ToolbarLayout(title: 'Team Work', onRefresh: () => _refresh(ref))
              else
                const AppEntrance(offsetY: -14, child: HeaderToolbar()),
              Expanded(
                child: AppEntrance(
                  offsetY: 60,
                  child: Container(
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: teamPageBg,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                    ),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  final List<WorkTask> tasks;
  final bool isAdmin;
  final String name;
  const _Content({required this.tasks, required this.isAdmin, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final byId = {for (final p in projects) p.id: p};
    final board = ref.watch(devLeaderboardProvider).value ?? const <RankedDev>[];
    final me = ref.watch(teamWorkUserProvider).value?.id ?? '';
    final myRank = board.where((r) => r.score.member.id == me).firstOrNull;
    final announcements = ref.watch(announcementsProvider).value ?? const <Announcement>[];
    final read = ref.watch(announcementReadProvider).value ?? const <String>{};
    final unread = ref.watch(unreadAnnouncementCountProvider);
    final openTickets = ref.watch(openTicketCountProvider);

    final open = tasks.where((t) => t.status.isOpen).toList();
    final weekEnd = DateUtils.dateOnly(now).add(const Duration(days: 7));
    final dueWeek = open.where((t) => t.dueDate != null && !t.dueDate!.isAfter(weekEnd) && !t.isOverdue(now)).length;
    final overdue = open.where((t) => t.isOverdue(now)).length;
    final monthStart = DevPeriod.month.start(now);
    final doneMonth =
        tasks.where((t) => t.status == TaskStatus.done && t.completedAt != null && !t.completedAt!.isBefore(monthStart)).length;
    final upNext = [...open]..sort((a, b) {
        final ad = a.dueDate ?? DateTime(9999), bd = b.dueDate ?? DateTime(9999);
        final c = ad.compareTo(bd);
        return c != 0 ? c : b.priority.index.compareTo(a.priority.index);
      });

    final wide = MediaQuery.sizeOf(context).width >= 700;
    void openTasks([String? filter]) => Navigator.pushNamed(context, RoutesName.tasks, arguments: filter);

    final stats = [
      _Stat('Open tasks', open.length, Icons.assignment_rounded, HomeGlass.blue, () => openTasks(TaskListView.fOpen)),
      _Stat('Due this week', dueWeek, Icons.event_rounded, const Color(0xFF7C3AED), () => openTasks(TaskListView.fWeek)),
      _Stat('Overdue', overdue, Icons.warning_amber_rounded, AppColors.danger, () => openTasks(TaskListView.fOverdue)),
      _Stat('Done this month', doneMonth, Icons.task_alt_rounded, HomeGlass.green, () => openTasks(TaskListView.fDone)),
    ];

    final tiles = [
      _Tile('Tasks', isAdmin ? 'Assign & track' : 'My work', Icons.view_kanban_rounded, HomeGlass.blue, open.length,
          () => openTasks()),
      _Tile('Projects', 'Modules & milestones', Icons.folder_copy_rounded, const Color(0xFF0891B2), 0,
          () => Navigator.pushNamed(context, RoutesName.projects)),
      _Tile('Tickets', 'Raise & resolve', Icons.confirmation_number_rounded, HomeGlass.orange, openTickets,
          () => Navigator.pushNamed(context, RoutesName.tickets)),
      _Tile('Leaderboard', 'Tasks & milestones', Icons.emoji_events_rounded, const Color(0xFFD97706), 0,
          () => Navigator.pushNamed(context, RoutesName.devLeaderboard)),
      _Tile('Announcements', isAdmin ? 'Post to the team' : 'From your lead', Icons.campaign_rounded,
          const Color(0xFFDB2777), unread, () => Navigator.pushNamed(context, RoutesName.announcements)),
    ];

    final latest = announcements.firstOrNull;
    var k = 0;
    Widget enter(Widget child) => AppEntrance(index: k++, child: child);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 20, wide ? 24 : 16, 32),
          children: [
            enter(_Hero(
              isAdmin: isAdmin,
              name: name,
              open: open.length,
              dueWeek: dueWeek,
              overdue: overdue,
              projects: projects.length,
              rank: myRank,
              onRank: () => Navigator.pushNamed(context, RoutesName.devLeaderboard),
            )),
            const SizedBox(height: 16),
            enter(LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 600 ? 4 : 2;
              const gap = 12.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final s in stats) SizedBox(width: w, child: _StatCard(stat: s))],
              );
            })),
            if (latest != null) ...[
              const SizedBox(height: 16),
              enter(_AnnouncementBanner(
                a: latest,
                unread: !read.contains(latest.id),
                onTap: () => Navigator.pushNamed(context, RoutesName.announcements),
              )),
            ],
            const SizedBox(height: 22),
            enter(const Text('WORKSPACE', style: teamSectionStyle)),
            const SizedBox(height: 10),
            enter(LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 820 ? 5 : box.maxWidth >= 520 ? 3 : 2;
              const gap = 12.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [for (final t in tiles) SizedBox(width: w, child: _TileCard(tile: t))],
              );
            })),
            const SizedBox(height: 22),
            enter(Row(
              children: [
                Text(isAdmin ? 'TEAM · UP NEXT' : 'UP NEXT', style: teamSectionStyle),
                const Spacer(),
                if (open.isNotEmpty)
                  TextButton(onPressed: () => openTasks(TaskListView.fOpen), child: const Text('See all')),
              ],
            )),
            const SizedBox(height: 6),
            if (upNext.isEmpty)
              enter(SoftCard(
                radius: 18,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: homePastelGradient(HomeGlass.green), shape: BoxShape.circle),
                      child: Icon(Icons.celebration_rounded, color: homeDeep(HomeGlass.green)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isAdmin
                            ? 'No open tasks. Assign one from Tasks to get the team moving.'
                            : 'All caught up! New tasks from your lead will show here.',
                        style: teamBodyStyle,
                      ),
                    ),
                  ],
                ),
              ))
            else
              for (final t in upNext.take(wide ? 6 : 4))
                enter(Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TaskCard(
                    task: t,
                    project: byId[t.projectId],
                    showAssignee: isAdmin,
                    onTap: () => Navigator.pushNamed(context, RoutesName.taskDetail, arguments: t.id),
                  ),
                )),
            if (projects.isNotEmpty) ...[
              const SizedBox(height: 10),
              enter(const Text('PROJECTS', style: teamSectionStyle)),
              const SizedBox(height: 10),
              enter(SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _ProjectProgressCard(
                    project: projects[i],
                    tasks: tasks.where((t) => t.projectId == projects[i].id).toList(),
                    onTap: () => Navigator.pushNamed(context, RoutesName.projectDetail, arguments: projects[i].id),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool isAdmin;
  final String name;
  final int open;
  final int dueWeek;
  final int overdue;
  final int projects;
  final RankedDev? rank;
  final VoidCallback onRank;

  const _Hero({
    required this.isAdmin,
    required this.name,
    required this.open,
    required this.dueWeek,
    required this.overdue,
    required this.projects,
    required this.rank,
    required this.onRank,
  });

  @override
  Widget build(BuildContext context) {
    final first = name.trim().split(RegExp(r'\s+')).first;
    final line = isAdmin
        ? '$open open tasks across $projects project${projects == 1 ? '' : 's'}${overdue > 0 ? ' · $overdue overdue' : ''}'
        : open == 0
            ? 'No open tasks right now.'
            : '$open open task${open == 1 ? '' : 's'}${dueWeek > 0 ? ' · $dueWeek due this week' : ''}${overdue > 0 ? ' · $overdue overdue' : ''}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeGlass.navy, Color(0xFF2E4A86)],
        ),
        boxShadow: [BoxShadow(color: HomeGlass.navy.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -50,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.code_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(isAdmin ? 'TEAM LEAD' : 'DEVELOPER',
                          style: const TextStyle(
                              fontSize: 10.5, letterSpacing: 1, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(isAdmin ? 'Team overview' : 'Hi ${first.isEmpty ? 'there' : first} 👋',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Text(line, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
                if (!isAdmin) ...[
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: onRank,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 18, color: Color(0xFFD97706)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                rank == null
                                    ? 'Finish a task to join the leaderboard'
                                    : 'Rank #${rank!.rank} · ${rank!.score.points} pts this month',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: HomeGlass.navy),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: HomeGlass.navy),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Stat(this.label, this.value, this.icon, this.color, this.onTap);
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final deep = homeDeep(stat.color);
    return SoftCard(
      radius: 18,
      gradient: homePastelGradient(stat.color),
      borderColor: stat.color.withValues(alpha: 0.15),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      onTap: stat.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
                child: Icon(stat.icon, size: 17, color: deep),
              ),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, size: 15, color: deep.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: stat.value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) =>
                Text('$v', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: deep, height: 1)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(stat.label,
                maxLines: 1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: deep)),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  final Announcement a;
  final bool unread;
  final VoidCallback onTap;
  const _AnnouncementBanner({required this.a, required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const c = Color(0xFFDB2777);
    return SoftCard(
      radius: 18,
      gradient: homePastelGradient(a.important ? AppColors.danger : c),
      borderColor: c.withValues(alpha: 0.18),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [c, Color.lerp(c, Colors.white, 0.3)!]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.campaign_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(a.important ? 'IMPORTANT' : 'ANNOUNCEMENT',
                        style: TextStyle(
                            fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w800, color: homeDeep(c))),
                    if (unread) ...[
                      const SizedBox(width: 6),
                      Container(width: 7, height: 7, decoration: const BoxDecoration(color: c, shape: BoxShape.circle)),
                    ],
                    const Spacer(),
                    Text(teamDate(a.createdAt), style: const TextStyle(fontSize: 11, color: teamSubtle)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: teamTitleStyle),
                if (a.body.isNotEmpty)
                  Text(a.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: teamBodyStyle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: teamSubtle),
        ],
      ),
    );
  }
}

class _Tile {
  final String title;
  final String sub;
  final IconData icon;
  final Color color;
  final int badge;
  final VoidCallback onTap;
  const _Tile(this.title, this.sub, this.icon, this.color, this.badge, this.onTap);
}

class _TileCard extends StatelessWidget {
  final _Tile tile;
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final c = tile.color;
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      onTap: () {
        HapticFeedback.selectionClick();
        tile.onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(c, Colors.white, 0.2)!, c],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(tile.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              if (tile.badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(20)),
                  child: Text('${tile.badge}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(tile.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: teamTitleStyle),
          const SizedBox(height: 2),
          Text(tile.sub,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: teamSubtle)),
        ],
      ),
    );
  }
}

class _ProjectProgressCard extends StatelessWidget {
  final Project project;
  final List<WorkTask> tasks;
  final VoidCallback onTap;
  const _ProjectProgressCard({required this.project, required this.tasks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;
    final ms = project.milestones;
    final msDone = ms.where((m) => m.isCompleted).length;
    return SizedBox(
      width: 230,
      child: SoftCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProjectBadge(project: project, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: teamTitleStyle)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text('${(ratio * 100).round()}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: homeDeep(project.color))),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('$done/${tasks.length} tasks · $msDone/${ms.length} milestones',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: teamSubtle)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 7,
                  backgroundColor: homePastel(project.color),
                  color: project.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
