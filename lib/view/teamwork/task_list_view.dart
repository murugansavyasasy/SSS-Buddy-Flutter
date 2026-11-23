import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/model/TeamWorkModel.dart';
import '../../components/ResponsiveCardList.dart';
import '../../components/app_motion.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import 'widget/teamwork_common.dart';

/// Tasks: Admin sees every task and assigns new ones; a developer sees the
/// tasks assigned to them. Route argument: an optional quick filter
/// ([fOpen], [fWeek], [fOverdue], [fDone]) from the dashboard cards.
class TaskListView extends ConsumerStatefulWidget {
  static const fOpen = 'open';
  static const fWeek = 'week';
  static const fOverdue = 'overdue';
  static const fDone = 'done';

  final String? filter;
  const TaskListView({super.key, this.filter});

  @override
  ConsumerState<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends ConsumerState<TaskListView> {
  late String? _quick = widget.filter;
  String? _projectId;
  String? _personId;
  String _query = '';

  Future<void> _assign() async {
    final ok = await Navigator.pushNamed(context, RoutesName.taskForm);
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task assigned.')));
    }
  }

  bool _matchQuick(WorkTask t, DateTime now) {
    final weekEnd = DateUtils.dateOnly(now).add(const Duration(days: 7));
    return switch (_quick) {
      TaskListView.fOpen => t.status.isOpen,
      TaskListView.fWeek => t.status.isOpen && t.dueDate != null && !t.dueDate!.isAfter(weekEnd) && !t.isOverdue(now),
      TaskListView.fOverdue => t.isOverdue(now),
      TaskListView.fDone => t.status == TaskStatus.done,
      'todo' => t.status == TaskStatus.todo,
      'inProgress' => t.status == TaskStatus.inProgress,
      'inReview' => t.status == TaskStatus.inReview,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tasksProvider);
    final isAdmin = ref.watch(teamWorkUserProvider).value?.isAdmin ?? false;
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];
    final byId = {for (final p in projects) p.id: p};

    return TeamPage(
      title: isAdmin ? 'Team Tasks' : 'My Tasks',
      searchHint: 'Search task, project, person...',
      onSearch: (q) => setState(() => _query = q.trim().toLowerCase()),
      onRefresh: () {
        ref.invalidate(tasksProvider);
        ref.invalidate(projectsProvider);
      },
      fab: isAdmin ? TeamFab(label: 'Assign Task', icon: Icons.add_task_rounded, onPressed: _assign) : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => TeamStateView.error(e, title: "Couldn't load tasks", onRetry: () => ref.invalidate(tasksProvider)),
        data: (all) {
          final now = DateTime.now();
          final people = <String, String>{
            for (final t in all)
              if (t.assigneeId.isNotEmpty) t.assigneeId: t.assigneeName,
          };
          final list = all.where((t) {
            if (!_matchQuick(t, now)) return false;
            if (_projectId != null && t.projectId != _projectId) return false;
            if (_personId != null && t.assigneeId != _personId) return false;
            if (_query.isEmpty) return true;
            final p = byId[t.projectId];
            return [t.title, t.description, t.assigneeName, p?.name ?? '', p?.module(t.moduleId)?.name ?? '']
                .any((s) => s.toLowerCase().contains(_query));
          }).toList();

          return Column(
            children: [
              const SizedBox(height: 14),
              TeamFilterChips<String>(
                selected: _quick,
                onChanged: (v) => setState(() => _quick = v),
                options: const [
                  (null, 'All'),
                  (TaskListView.fOpen, 'Open'),
                  ('todo', 'To do'),
                  ('inProgress', 'In progress'),
                  ('inReview', 'In review'),
                  (TaskListView.fWeek, 'Due this week'),
                  (TaskListView.fOverdue, 'Overdue'),
                  (TaskListView.fDone, 'Done'),
                ],
              ),
              if (projects.isNotEmpty || (isAdmin && people.length > 1)) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (projects.isNotEmpty)
                        Expanded(
                          child: TeamPickerBox(
                            icon: Icons.folder_rounded,
                            text: _projectId == null ? 'All projects' : byId[_projectId]?.name ?? 'Project',
                            placeholder: _projectId == null,
                            onTap: () async {
                              final v = await pickTeamOption<String>(context,
                                  title: 'Project',
                                  current: _projectId ?? '',
                                  options: [('', 'All projects'), for (final p in projects) (p.id, p.name)]);
                              if (v != null) setState(() => _projectId = v.isEmpty ? null : v);
                            },
                          ),
                        ),
                      if (isAdmin && people.length > 1) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: TeamPickerBox(
                            icon: Icons.person_rounded,
                            text: _personId == null ? 'Everyone' : people[_personId] ?? 'Person',
                            placeholder: _personId == null,
                            onTap: () async {
                              final v = await pickTeamOption<String>(context,
                                  title: 'Assigned to',
                                  current: _personId ?? '',
                                  options: [('', 'Everyone'), for (final e in people.entries) (e.key, e.value)]);
                              if (v != null) setState(() => _personId = v.isEmpty ? null : v);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(tasksProvider),
                  child: list.isEmpty
                      ? TeamStateView(
                          icon: all.isEmpty ? Icons.assignment_outlined : Icons.filter_alt_off_rounded,
                          title: all.isEmpty ? (isAdmin ? 'No tasks yet' : 'No tasks assigned to you') : 'No matching tasks',
                          message: all.isEmpty
                              ? (isAdmin
                                  ? 'Create a project, then assign the first task to your team.'
                                  : 'When your lead assigns you a task, it shows up here.')
                              : 'Try another filter or search.',
                        )
                      : ResponsiveCardList(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                          spacing: 12,
                          minItemWidth: 340,
                          itemCount: list.length,
                          itemBuilder: (_, i) => AppEntrance(
                            index: i.clamp(0, 8),
                            child: TaskCard(
                              task: list[i],
                              project: byId[list[i].projectId],
                              showAssignee: isAdmin,
                              onTap: () => Navigator.pushNamed(context, RoutesName.taskDetail, arguments: list[i].id),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
