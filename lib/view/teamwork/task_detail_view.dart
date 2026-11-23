import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../auth/model/TeamWorkModel.dart';
import '../../components/glass_card.dart';
import '../../core/notifications/local_notifications.dart';
import '../../viewModel/teamwork_viewmodel.dart';
import '../ticket/widget/ticket_common.dart' show TicketPersonAvatar;
import 'widget/teamwork_common.dart';

/// One task: details, progress stepper, status actions and the timeline.
/// The assignee moves it forward; Admin approves, reopens or reassigns.
class TaskDetailView extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailView({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends ConsumerState<TaskDetailView> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    LocalNotifications.instance.activeScreen = 'task:${widget.taskId}';
  }

  @override
  void dispose() {
    if (LocalNotifications.instance.activeScreen == 'task:${widget.taskId}') {
      LocalNotifications.instance.activeScreen = null;
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _move(WorkTask t, TaskStatus to) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StatusSheet(to: to, back: to.index < t.status.index),
    );
    if (note == null) return;
    HapticFeedback.mediumImpact();
    await _run(() => ref.read(teamWorkActionsProvider).setStatus(t, to, note: note), 'Moved to ${to.label}.');
  }

  Future<void> _reassign(WorkTask t) async {
    final m = await pickTeamMember(context, currentId: t.assigneeId);
    if (m == null || m.id == t.assigneeId) return;
    await _run(() => ref.read(teamWorkActionsProvider).reassign(t, m), 'Assigned to ${m.name}.');
  }

  Future<void> _addNote(WorkTask t) async {
    final text = _note.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _run(() async {
      await ref.read(teamWorkActionsProvider).addNote(t, text);
      _note.clear();
    }, 'Note added.');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskProvider(widget.taskId));
    final user = ref.watch(teamWorkUserProvider).value;
    final projects = ref.watch(projectsProvider).value ?? const <Project>[];

    return TeamPage(
      title: 'Task',
      onRefresh: () => ref.invalidate(tasksProvider),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => TeamStateView.error(e, title: "Couldn't load task", onRetry: () => ref.invalidate(tasksProvider)),
        data: (t) {
          if (t == null) {
            return const TeamStateView(
              icon: Icons.search_off_rounded,
              title: 'Task not found',
              message: 'It may have been reassigned to someone else.',
            );
          }
          final project = projects.where((p) => p.id == t.projectId).firstOrNull;
          final isAdmin = user?.isAdmin ?? false;
          final isAssignee = user != null && user.id == t.assigneeId;
          final moves = nextStatuses(t, isAdmin: isAdmin, isAssignee: isAssignee);
          final wide = MediaQuery.sizeOf(context).width >= 900;

          final info = _InfoCard(task: t, project: project);
          final actions = _Actions(
            task: t,
            moves: moves,
            busy: _busy,
            canReassign: isAdmin,
            onMove: (s) => _move(t, s),
            onReassign: () => _reassign(t),
          );
          final timeline = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TIMELINE', style: teamSectionStyle),
              const SizedBox(height: 12),
              SoftCard(
                radius: 18,
                child: Column(
                  children: [
                    TaskTimeline(events: t.history),
                    if (isAdmin || isAssignee) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _note,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: teamInput('Add an update or note…', icon: Icons.chat_bubble_outline_rounded),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _busy ? null : () => _addNote(t),
                            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tasksProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 18, wide ? 28 : 16, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Column(children: [info, const SizedBox(height: 16), actions])),
                      const SizedBox(width: 20),
                      Expanded(flex: 6, child: timeline),
                    ],
                  )
                else ...[
                  info,
                  const SizedBox(height: 16),
                  actions,
                  const SizedBox(height: 22),
                  timeline,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final WorkTask task;
  final Project? project;
  const _InfoCard({required this.task, required this.project});

  @override
  Widget build(BuildContext context) {
    final t = task;
    final overdue = t.isOverdue();
    final module = project?.module(t.moduleId)?.name ?? '';
    final milestone = project?.milestone(t.milestoneId);
    Widget row(IconData icon, String label, Widget value) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: teamSubtle),
              const SizedBox(width: 10),
              SizedBox(width: 86, child: Text(label, style: const TextStyle(fontSize: 13, color: teamSubtle))),
              Expanded(child: value),
            ],
          ),
        );
    Text v(String s, {Color? color}) => Text(s,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color ?? teamInk),
        maxLines: 2,
        overflow: TextOverflow.ellipsis);

    return SoftCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
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
                    Text('${t.displayId} · ${project?.name ?? 'Project'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: teamSubtle)),
                    const SizedBox(height: 2),
                    Text(t.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: teamInk)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [TaskStatusChip(status: t.status), TaskPriorityTag(priority: t.priority)],
          ),
          if (t.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(t.description, style: const TextStyle(fontSize: 14, color: teamInk, height: 1.5)),
          ],
          const SizedBox(height: 18),
          TaskStepper(status: t.status),
          const SizedBox(height: 18),
          const Divider(height: 1, color: teamBorder),
          const SizedBox(height: 16),
          row(Icons.widgets_rounded, 'Module', v(module.isEmpty ? '—' : module)),
          if (milestone != null)
            row(
              Icons.outlined_flag_rounded,
              'Milestone',
              v(
                milestone.isCompleted ? '${milestone.title} ✓' : milestone.title,
                color: milestone.isCompleted ? HomeGlass.green : null,
              ),
            ),
          row(
            Icons.person_rounded,
            'Assigned to',
            Row(
              children: [
                TicketPersonAvatar(name: t.assigneeName, size: 22),
                const SizedBox(width: 6),
                Expanded(child: v(t.assigneeName.isEmpty ? 'Unassigned' : t.assigneeName)),
              ],
            ),
          ),
          row(Icons.admin_panel_settings_rounded, 'Assigned by', v(t.assignedByName.isEmpty ? '—' : t.assignedByName)),
          row(Icons.play_circle_outline_rounded, 'Start', v(teamDate(t.startDate))),
          row(
            overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
            'Due',
            v('${teamDate(t.dueDate)} · ${teamDueLabel(t)}', color: overdue ? AppColors.danger : null),
          ),
          if (t.completedAt != null)
            row(
              Icons.task_alt_rounded,
              'Completed',
              v('${teamDateTime(t.completedAt)}${t.finishedOnTime ? ' · on time' : ' · late'}',
                  color: t.finishedOnTime ? HomeGlass.green : AppColors.danger),
            ),
          if (t.status == TaskStatus.done)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: homePastel(const Color(0xFFD97706)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Text('+${taskPoints(t)} leaderboard points',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: teamInk)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final WorkTask task;
  final List<TaskStatus> moves;
  final bool busy;
  final bool canReassign;
  final ValueChanged<TaskStatus> onMove;
  final VoidCallback onReassign;

  const _Actions({
    required this.task,
    required this.moves,
    required this.busy,
    required this.canReassign,
    required this.onMove,
    required this.onReassign,
  });

  String _label(TaskStatus to) => switch (to) {
        TaskStatus.inProgress => task.status == TaskStatus.todo
            ? 'Start task'
            : task.status == TaskStatus.done
                ? 'Reopen'
                : 'Send back',
        TaskStatus.inReview => 'Send for review',
        TaskStatus.done => task.status == TaskStatus.inReview ? 'Approve & complete' : 'Mark done',
        TaskStatus.todo => 'Move to To do',
      };

  IconData _icon(TaskStatus to) => switch (to) {
        TaskStatus.inProgress =>
          task.status == TaskStatus.todo ? Icons.play_arrow_rounded : Icons.undo_rounded,
        TaskStatus.inReview => Icons.rate_review_rounded,
        TaskStatus.done => Icons.check_circle_rounded,
        TaskStatus.todo => Icons.radio_button_unchecked_rounded,
      };

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty && !canReassign) {
      return task.status == TaskStatus.inReview
          ? SoftCard(
              radius: 18,
              color: homePastel(TaskStatus.inReview.color),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFF9333EA)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Waiting for your lead to review.', style: TextStyle(color: teamInk))),
                ],
              ),
            )
          : const SizedBox.shrink();
    }
    final forward = moves.where((m) => m.index > task.status.index).toList();
    final back = moves.where((m) => m.index < task.status.index).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in forward)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: busy ? null : () => onMove(m),
                style: FilledButton.styleFrom(
                  backgroundColor: m.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(_icon(m)),
                label: Text(_label(m), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        Row(
          children: [
            for (final m in back) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => onMove(m),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_icon(m), size: 18),
                  label: Text(_label(m)),
                ),
              ),
              const SizedBox(width: 10),
            ],
            if (canReassign)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReassign,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Reassign'),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Confirms a status change with an optional note. Pops with the note
/// ('' = none) or null when cancelled.
class _StatusSheet extends StatefulWidget {
  final TaskStatus to;
  final bool back;
  const _StatusSheet({required this.to, required this.back});

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final to = widget.to;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                    width: 40, height: 4, decoration: BoxDecoration(color: teamBorder, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: homePastel(to.color), shape: BoxShape.circle),
                    child: Icon(to.icon, color: homeDeep(to.color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.back ? 'Move back to ${to.label}?' : 'Move to ${to.label}?',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: teamInk)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _c,
                autofocus: widget.back,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: teamInput(widget.back ? 'What needs to change? (optional)' : 'Add a note (optional)'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _c.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: to.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
