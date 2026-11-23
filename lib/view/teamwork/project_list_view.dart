import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/TeamWorkModel.dart';
import '../../components/ResponsiveCardList.dart';
import '../../components/app_motion.dart';
import '../../components/glass_card.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import 'widget/teamwork_common.dart';

/// Projects with their task and milestone progress. Admin creates them.
class ProjectListView extends ConsumerStatefulWidget {
  const ProjectListView({super.key});

  @override
  ConsumerState<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends ConsumerState<ProjectListView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectsProvider);
    final tasks = ref.watch(allTasksProvider).value ?? const <WorkTask>[];
    final isAdmin = ref.watch(teamWorkUserProvider).value?.isAdmin ?? false;

    return TeamPage(
      title: 'Projects',
      searchHint: 'Search projects...',
      onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
      onRefresh: () {
        ref.invalidate(projectsProvider);
        ref.invalidate(allTasksProvider);
      },
      fab: isAdmin
          ? TeamFab(
              label: 'New Project',
              icon: Icons.create_new_folder_rounded,
              onPressed: () => Navigator.pushNamed(context, RoutesName.projectForm),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            TeamStateView.error(e, title: "Couldn't load projects", onRetry: () => ref.invalidate(projectsProvider)),
        data: (all) {
          final list = all
              .where((p) =>
                  _query.isEmpty ||
                  p.name.toLowerCase().contains(_query) ||
                  p.modules.any((m) => m.name.toLowerCase().contains(_query)))
              .toList();
          if (list.isEmpty) {
            return TeamStateView(
              icon: Icons.folder_open_rounded,
              title: all.isEmpty ? 'No projects yet' : 'No matching projects',
              message: all.isEmpty
                  ? (isAdmin
                      ? 'Create a project with its modules and milestones, then assign tasks.'
                      : 'Your lead hasn\'t created any projects yet.')
                  : 'Try another search.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ResponsiveCardList(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
              spacing: 12,
              minItemWidth: 340,
              itemCount: list.length,
              itemBuilder: (_, i) => AppEntrance(
                index: i.clamp(0, 8),
                child: ProjectCard(
                  project: list[i],
                  tasks: tasks.where((t) => t.projectId == list[i].id).toList(),
                  onTap: () => Navigator.pushNamed(context, RoutesName.projectDetail, arguments: list[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final List<WorkTask> tasks;
  final VoidCallback onTap;
  const ProjectCard({super.key, required this.project, required this.tasks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.status == TaskStatus.done).length;
    final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;
    final msDone = project.milestones.where((m) => m.isCompleted).length;
    final next = project.milestones.where((m) => !m.isCompleted && m.dueDate != null).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProjectBadge(project: project, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: teamTitleStyle),
                    Text(
                      project.description.isEmpty
                          ? '${project.modules.length} modules · ${project.milestones.length} milestones'
                          : project.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: teamSubtle),
                    ),
                  ],
                ),
              ),
              Text('${(ratio * 100).round()}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: homeDeep(project.color))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: homePastel(project.color),
              color: project.color,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _meta(Icons.task_alt_rounded, '$done/${tasks.length} tasks'),
              _meta(Icons.outlined_flag_rounded, '$msDone/${project.milestones.length} milestones'),
              if (next.isNotEmpty) _meta(Icons.event_rounded, 'Next: ${next.first.title} · ${teamDate(next.first.dueDate)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: teamSubtle),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: teamSubtle)),
          ),
        ],
      );
}
