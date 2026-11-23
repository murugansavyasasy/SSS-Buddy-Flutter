import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/TeamWorkModel.dart';
import '../../components/glass_card.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import 'widget/teamwork_common.dart';

/// One project: overall progress, milestones (with progress and due
/// dates), modules with their task counts, and the project's tasks.
class ProjectDetailView extends ConsumerWidget {
  final String projectId;
  const ProjectDetailView({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(projectsProvider);
    final allTasks = ref.watch(allTasksProvider).value ?? const <WorkTask>[];
    final user = ref.watch(teamWorkUserProvider).value;
    final isAdmin = user?.isAdmin ?? false;

    return TeamPage(
      title: 'Project',
      onRefresh: () {
        ref.invalidate(projectsProvider);
        ref.invalidate(allTasksProvider);
      },
      fab: isAdmin
          ? TeamFab(
              label: 'Assign Task',
              icon: Icons.add_task_rounded,
              onPressed: () => Navigator.pushNamed(context, RoutesName.taskForm, arguments: projectId),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            TeamStateView.error(e, title: "Couldn't load project", onRetry: () => ref.invalidate(projectsProvider)),
        data: (projects) {
          final p = projects.where((x) => x.id == projectId).firstOrNull;
          if (p == null) return const TeamStateView(icon: Icons.search_off_rounded, title: 'Project not found');
          final tasks = allTasks.where((t) => t.projectId == p.id).toList();
          // Developers only see their own tasks in the list below.
          final visible = isAdmin ? tasks : tasks.where((t) => t.assigneeId == user?.id).toList();
          final done = tasks.where((t) => t.status == TaskStatus.done).length;
          final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;
          final wide = MediaQuery.sizeOf(context).width >= 700;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(projectsProvider);
              ref.invalidate(allTasksProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 18, wide ? 24 : 16, 96),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [homeDeep(p.color), p.color],
                    ),
                    boxShadow: [BoxShadow(color: p.color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(p.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                          if (isAdmin)
                            IconButton(
                              tooltip: 'Edit project',
                              onPressed: () => Navigator.pushNamed(context, RoutesName.projectForm, arguments: p.id),
                              icon: const Icon(Icons.edit_rounded, color: Colors.white),
                            ),
                        ],
                      ),
                      if (p.description.isNotEmpty)
                        Text(p.description,
                            style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85), height: 1.4)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('${(ratio * 100).round()}%',
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('$done of ${tasks.length} tasks done',
                                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: ratio),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text('MILESTONES', style: teamSectionStyle),
                const SizedBox(height: 10),
                if (p.milestones.isEmpty)
                  SoftCard(radius: 16, child: Text('No milestones in this project.', style: teamBodyStyle))
                else
                  SoftCard(
                    radius: 18,
                    child: Column(
                      children: [
                        for (final (i, m) in p.milestones.indexed)
                          _MilestoneRow(
                            m: m,
                            tasks: tasks.where((t) => t.milestoneId == m.id).toList(),
                            color: p.color,
                            last: i == p.milestones.length - 1,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                const Text('MODULES', style: teamSectionStyle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final m in p.modules)
                      () {
                        final mt = tasks.where((t) => t.moduleId == m.id).toList();
                        final md = mt.where((t) => t.status == TaskStatus.done).length;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.color.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.widgets_rounded, size: 16, color: p.color),
                              const SizedBox(width: 6),
                              Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, color: teamInk)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: homePastel(p.color), borderRadius: BorderRadius.circular(10)),
                                child: Text('$md/${mt.length}',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: homeDeep(p.color))),
                              ),
                            ],
                          ),
                        );
                      }(),
                  ],
                ),
                const SizedBox(height: 22),
                Text(isAdmin ? 'TASKS' : 'MY TASKS HERE', style: teamSectionStyle),
                const SizedBox(height: 10),
                if (visible.isEmpty)
                  SoftCard(radius: 16, child: Text('No tasks yet.', style: teamBodyStyle))
                else
                  for (final t in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskCard(
                        task: t,
                        project: p,
                        showAssignee: isAdmin,
                        onTap: () => Navigator.pushNamed(context, RoutesName.taskDetail, arguments: t.id),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final Milestone m;
  final List<WorkTask> tasks;
  final Color color;
  final bool last;
  const _MilestoneRow({required this.m, required this.tasks, required this.color, required this.last});

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;
    final late = !m.isCompleted && m.dueDate != null && DateUtils.dateOnly(m.dueDate!).isBefore(DateUtils.dateOnly(DateTime.now()));
    final c = m.isCompleted ? HomeGlass.green : color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: m.isCompleted ? c : homePastel(c), shape: BoxShape.circle),
                child: Icon(m.isCompleted ? Icons.check_rounded : Icons.flag_rounded,
                    size: 16, color: m.isCompleted ? Colors.white : homeDeep(c)),
              ),
              if (!last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 3), color: teamBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(m.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: teamInk))),
                      Text(
                        m.isCompleted ? 'Done ${teamDate(m.completedAt)}' : 'Due ${teamDate(m.dueDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: m.isCompleted ? HomeGlass.green : late ? const Color(0xFFD93A3A) : teamSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: homePastel(c),
                            color: c,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$done/${tasks.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teamSubtle)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
