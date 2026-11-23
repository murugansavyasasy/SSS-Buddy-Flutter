import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/glass_card.dart';
import '../../utils/routes/routes_name.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import '../ticket/widget/ticket_common.dart' show TicketPersonAvatar;
import 'widget/teamwork_common.dart';

/// Admin assigns a task: Project → Module → Milestone (optional), what to
/// do, who does it, priority and dates. Pops with true when saved. Route
/// argument: an optional project id to start with.
class TaskFormView extends ConsumerStatefulWidget {
  final String? projectId;
  const TaskFormView({super.key, this.projectId});

  @override
  ConsumerState<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends ConsumerState<TaskFormView> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late String? _projectId = widget.projectId;
  String? _moduleId;
  String? _milestoneId;
  TeamMember? _assignee;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _start = DateUtils.dateOnly(DateTime.now());
  DateTime? _due;
  bool _tried = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool due}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final initial = (due ? _due : _start) ?? (due ? (_start ?? now).add(const Duration(days: 3)) : now);
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d == null) return;
    setState(() {
      if (due) {
        _due = d;
      } else {
        _start = d;
        if (_due != null && _due!.isBefore(d)) _due = d;
      }
    });
  }

  Future<void> _save(Project? project) async {
    setState(() => _tried = true);
    if (project == null || _moduleId == null || _title.text.trim().isEmpty || _assignee == null || _due == null) {
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(teamWorkActionsProvider).createTask(CreateTaskRequest(
            projectId: project.id,
            moduleId: _moduleId!,
            milestoneId: _milestoneId,
            title: _title.text.trim(),
            description: _desc.text.trim(),
            priority: _priority,
            assignee: _assignee!,
            startDate: _start,
            dueDate: _due,
          ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    return TeamPage(
      title: 'Assign Task',
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            TeamStateView.error(e, title: "Couldn't load projects", onRetry: () => ref.invalidate(projectsProvider)),
        data: (projects) {
          if (projects.isEmpty) {
            return TeamStateView(
              icon: Icons.create_new_folder_rounded,
              title: 'Create a project first',
              message: 'Tasks belong to a project and one of its modules.',
              action: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, RoutesName.projectForm),
                icon: const Icon(Icons.add_rounded),
                label: const Text('New project'),
              ),
            );
          }
          final project = projects.where((p) => p.id == _projectId).firstOrNull;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        _section(Icons.folder_rounded, 'Where'),
                        TeamFormField(
                          label: 'Project',
                          error: _tried && project == null ? 'Choose a project' : null,
                          child: TeamPickerBox(
                            icon: Icons.folder_rounded,
                            leading: project == null ? null : ProjectBadge(project: project, size: 24),
                            text: project?.name ?? 'Choose project',
                            placeholder: project == null,
                            onTap: () async {
                              final v = await pickTeamOption<String>(context,
                                  title: 'Project',
                                  current: _projectId,
                                  options: [for (final p in projects) (p.id, p.name)]);
                              if (v != null && v != _projectId) {
                                setState(() {
                                  _projectId = v;
                                  _moduleId = null;
                                  _milestoneId = null;
                                });
                              }
                            },
                          ),
                        ),
                        TeamFormField(
                          label: 'Module',
                          error: _tried && project != null && _moduleId == null
                              ? (project.modules.isEmpty ? 'Add a module to this project first' : 'Choose a module')
                              : null,
                          child: TeamPickerBox(
                            icon: Icons.widgets_rounded,
                            text: project?.module(_moduleId ?? '')?.name ?? 'Choose module',
                            placeholder: _moduleId == null,
                            onTap: project == null || project.modules.isEmpty
                                ? null
                                : () async {
                                    final v = await pickTeamOption<String>(context,
                                        title: 'Module',
                                        current: _moduleId,
                                        options: [for (final m in project.modules) (m.id, m.name)]);
                                    if (v != null) setState(() => _moduleId = v);
                                  },
                          ),
                        ),
                        if (project != null && project.milestones.isNotEmpty)
                          TeamFormField(
                            label: 'Milestone (optional)',
                            child: TeamPickerBox(
                              icon: Icons.outlined_flag_rounded,
                              text: project.milestone(_milestoneId)?.title ?? 'No milestone',
                              placeholder: _milestoneId == null,
                              onTap: () async {
                                final v = await pickTeamOption<String>(context,
                                    title: 'Milestone',
                                    current: _milestoneId ?? '',
                                    options: [
                                      ('', 'No milestone'),
                                      for (final m in project.milestones)
                                        (m.id, m.dueDate == null ? m.title : '${m.title} · due ${teamDate(m.dueDate)}'),
                                    ]);
                                if (v != null) setState(() => _milestoneId = v.isEmpty ? null : v);
                              },
                            ),
                          ),
                        const SizedBox(height: 6),
                        _section(Icons.edit_note_rounded, 'What'),
                        TeamFormField(
                          label: 'Task',
                          error: _tried && _title.text.trim().isEmpty ? 'Task title is required' : null,
                          child: TextField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => _tried ? setState(() {}) : null,
                            decoration: teamInput('e.g. Build the login screen API integration'),
                          ),
                        ),
                        TeamFormField(
                          label: 'Details (optional)',
                          child: TextField(
                            controller: _desc,
                            minLines: 3,
                            maxLines: 6,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: teamInput('Acceptance criteria, links, notes...'),
                          ),
                        ),
                        TeamFormField(
                          label: 'Priority',
                          child: Row(
                            children: [
                              for (final p in TaskPriority.values) ...[
                                if (p.index > 0) const SizedBox(width: 8),
                                Expanded(child: _priorityChip(p)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        _section(Icons.person_rounded, 'Who & when'),
                        TeamFormField(
                          label: 'Assign to',
                          error: _tried && _assignee == null ? 'Choose who does this task' : null,
                          child: TeamPickerBox(
                            icon: Icons.person_add_alt_1_rounded,
                            leading: _assignee == null ? null : TicketPersonAvatar(name: _assignee!.name, size: 26),
                            text: _assignee?.name ?? 'Choose person',
                            placeholder: _assignee == null,
                            onTap: () async {
                              final m = await pickTeamMember(context, currentId: _assignee?.id ?? '');
                              if (m != null) setState(() => _assignee = m);
                            },
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TeamFormField(
                                label: 'Start',
                                child: TeamPickerBox(
                                  icon: Icons.play_circle_outline_rounded,
                                  text: _start == null ? 'Start date' : teamDate(_start),
                                  placeholder: _start == null,
                                  onTap: () => _pickDate(due: false),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TeamFormField(
                                label: 'Due',
                                error: _tried && _due == null ? 'Due date is required' : null,
                                child: TeamPickerBox(
                                  icon: Icons.event_rounded,
                                  text: _due == null ? 'Due date' : teamDate(_due),
                                  placeholder: _due == null,
                                  onTap: () => _pickDate(due: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        _pointsHint(),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: teamBorder)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _save(project),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded),
                          label: Text(_saving ? 'Assigning…' : 'Assign Task',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
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

  Widget _section(IconData icon, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(title.toUpperCase(), style: teamSectionStyle),
          ],
        ),
      );

  Widget _priorityChip(TaskPriority p) {
    final on = p == _priority;
    return Material(
      color: on ? homePastel(p.color) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: on ? p.color : teamBorder, width: on ? 1.6 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _priority = p);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(Icons.flag_rounded, color: p.color, size: 20),
              const SizedBox(height: 3),
              Text(p.apiValue, style: TextStyle(fontWeight: FontWeight.w700, color: on ? homeDeep(p.color) : teamInk)),
              Text('${p.points} pts', style: const TextStyle(fontSize: 11, color: teamSubtle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pointsHint() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: homePastel(const Color(0xFFD97706)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Leaderboard: ${_priority.points} pts when done, +$kOnTimeBonus if finished by the due date, '
                '+$kMilestoneBonus when its milestone is completed.',
                style: const TextStyle(fontSize: 12.5, color: teamInk, height: 1.35),
              ),
            ),
          ],
        ),
      );
}
