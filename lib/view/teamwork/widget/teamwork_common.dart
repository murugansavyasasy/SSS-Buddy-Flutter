import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../Values/Colors/app_colors.dart';
import '../../../auth/model/TeamWorkModel.dart';
import '../../../components/app_motion.dart';
import '../../../components/glass_card.dart';
import '../../../components/toolbar_layout.dart';
import '../../../viewModel/teamwork_viewmodel.dart';
import '../../ticket/widget/ticket_common.dart' show TicketPersonAvatar;

/// Shared styling and widgets for the Team Work module (tasks, projects,
/// announcements, developer leaderboard). Uses the home screen palette.

const teamInk = HomeGlass.ink;
const teamSubtle = HomeGlass.muted;
const teamBorder = HomeGlass.line;
const teamPageBg = HomeGlass.bg;

const teamTitleStyle = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: teamInk, height: 1.3);
const teamBodyStyle = TextStyle(fontSize: 13, color: teamSubtle, height: 1.45);
const teamSectionStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: teamInk);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "23 Nov" (adds the year when it isn't this year).
String teamDate(DateTime? d) {
  if (d == null) return '—';
  final y = d.year == DateTime.now().year ? '' : ' ${d.year}';
  return '${d.day} ${_months[d.month - 1]}$y';
}

/// "23 Nov, 4:05 PM".
String teamDateTime(DateTime? d) {
  if (d == null) return '';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${teamDate(d)}, $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Due today", "Due in 3 days", "2 days overdue".
String teamDueLabel(WorkTask t, [DateTime? now]) {
  if (t.dueDate == null) return 'No due date';
  if (t.status == TaskStatus.done) return 'Due ${teamDate(t.dueDate)}';
  final n = DateUtils.dateOnly(now ?? DateTime.now());
  final days = DateUtils.dateOnly(t.dueDate!).difference(n).inDays;
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  if (days > 1) return 'Due in $days days';
  return days == -1 ? '1 day overdue' : '${-days} days overdue';
}

/// Blue header with the module title, then the rounded light body (same
/// look as Tickets).
class TeamPage extends StatelessWidget {
  final String title;
  final Widget body;
  final ValueChanged<String>? onSearch;
  final String searchHint;
  final VoidCallback? onRefresh;
  final Widget? fab;
  final VoidCallback? onBack;

  const TeamPage({
    super.key,
    required this.title,
    required this.body,
    this.onSearch,
    this.searchHint = 'Search...',
    this.onRefresh,
    this.fab,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          floatingActionButton: fab,
          body: Column(
            children: [
              ToolbarLayout(
                title: title,
                onSearch: onSearch,
                searchHint: searchHint,
                onRefresh: onRefresh,
                onBackPressed: onBack,
              ),
              Expanded(
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
            ],
          ),
        ),
      );
}

/// Primary extended FAB used by Team Work screens.
class TeamFab extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  const TeamFab({super.key, required this.label, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}

/// Empty / error state with an icon bubble and optional action.
class TeamStateView extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;

  const TeamStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message = '',
    this.color = HomeGlass.blue,
    this.action,
  });

  factory TeamStateView.error(Object e, {required String title, required VoidCallback onRetry}) => TeamStateView(
        icon: Icons.cloud_off_rounded,
        color: AppColors.danger,
        title: title,
        message: e.toString(),
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      );

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(gradient: homePastelGradient(color), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: homeDeep(color)),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: teamInk)),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: teamBodyStyle),
          ],
          if (action != null) ...[
            const SizedBox(height: 18),
            Center(child: action),
          ],
        ],
      );
}

class TaskStatusChip extends StatelessWidget {
  final TaskStatus status;
  const TaskStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: homePastel(status.color), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 13, color: homeDeep(status.color)),
            const SizedBox(width: 4),
            Text(status.label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: homeDeep(status.color))),
          ],
        ),
      );
}

class TaskPriorityTag extends StatelessWidget {
  final TaskPriority priority;
  const TaskPriorityTag({super.key, required this.priority});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: priority.color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 12, color: priority.color),
            const SizedBox(width: 3),
            Text(priority.apiValue,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: priority.color)),
          ],
        ),
      );
}

/// Coloured rounded square with the project's first letter.
class ProjectBadge extends StatelessWidget {
  final Project? project;
  final double size;
  const ProjectBadge({super.key, required this.project, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final c = project?.color ?? HomeGlass.blue;
    final name = project?.name.trim() ?? '';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.15)!, c],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

/// Task row: project badge, title, project · module, assignee, due, status.
class TaskCard extends StatelessWidget {
  final WorkTask task;
  final Project? project;
  final bool showAssignee;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.project, required this.onTap, this.showAssignee = true});

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue();
    final module = project?.module(task.moduleId)?.name ?? '';
    final milestone = project?.milestone(task.milestoneId)?.title;
    return SoftCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      borderColor: overdue ? AppColors.danger.withValues(alpha: 0.35) : null,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProjectBadge(project: project, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: teamTitleStyle),
                    const SizedBox(height: 2),
                    Text(
                      [project?.name ?? 'Project', if (module.isNotEmpty) module].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: teamSubtle, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TaskStatusChip(status: task.status),
            ],
          ),
          if (milestone != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.outlined_flag_rounded, size: 14, color: teamSubtle),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(milestone,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: teamSubtle)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: teamBorder),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showAssignee) ...[
                TicketPersonAvatar(name: task.assigneeName, size: 24),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(task.assigneeName.isEmpty ? 'Unassigned' : task.assigneeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: teamInk)),
                ),
                const SizedBox(width: 10),
              ],
              Icon(overdue ? Icons.warning_amber_rounded : Icons.event_rounded,
                  size: 14, color: overdue ? AppColors.danger : teamSubtle),
              const SizedBox(width: 4),
              Text(teamDueLabel(task),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: overdue ? AppColors.danger : teamSubtle)),
              const Spacer(),
              TaskPriorityTag(priority: task.priority),
            ],
          ),
        ],
      ),
    );
  }
}

/// To do → In progress → In review → Done, current step highlighted.
class TaskStepper extends StatelessWidget {
  final TaskStatus status;
  const TaskStepper({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final cur = status.index;
    final c = status.color;
    final last = TaskStatus.values.length - 1;
    Widget half(bool on) => Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 3,
            color: on ? c : teamBorder,
          ),
        );
    // Equal slot per step: connector halves either side of the dot, so the
    // dots line up with their labels at any width.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in TaskStatus.values)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 26,
                  child: Row(
                    children: [
                      s.index == 0 ? const Spacer() : half(s.index <= cur),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: s.index <= cur ? c : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: s.index <= cur ? c : teamBorder, width: 2),
                        ),
                        child: s.index < cur || status == TaskStatus.done
                            ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                            : s.index == cur
                                ? const Icon(Icons.circle, size: 8, color: Colors.white)
                                : null,
                      ),
                      s.index == last ? const Spacer() : half(s.index < cur),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(s.label,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: s.index <= cur ? homeDeep(c) : teamSubtle)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Vertical timeline of a task's history (oldest first).
class TaskTimeline extends StatelessWidget {
  final List<TaskEvent> events;
  const TaskTimeline({super.key, required this.events});

  (IconData, Color, String) _describe(TaskEvent e) => switch (e.event) {
        'created' => (Icons.add_task_rounded, HomeGlass.navy, 'Task created'),
        'assign' => (
            Icons.person_add_alt_1_rounded,
            const Color(0xFF0891B2),
            e.assignedToName.isEmpty ? 'Unassigned' : 'Assigned to ${e.assignedToName}'
          ),
        'note' => (Icons.chat_bubble_outline_rounded, const Color(0xFF64748B), 'Note'),
        _ => (e.status.icon, e.status.color, 'Moved to ${e.status.label}'),
      };

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (i, e) in events.indexed)
            AppEntrance(
              index: i,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 34,
                      child: Column(
                        children: [
                          Builder(builder: (_) {
                            final (icon, color, _) = _describe(e);
                            return Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(color: homePastel(color), shape: BoxShape.circle),
                              child: Icon(icon, size: 16, color: homeDeep(color)),
                            );
                          }),
                          if (i < events.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                color: teamBorder,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4, bottom: i < events.length - 1 ? 16 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_describe(e).$3,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: teamInk)),
                            const SizedBox(height: 2),
                            Text(
                              [if (e.byName.isNotEmpty) e.byName, teamDateTime(e.at)].where((s) => s.isNotEmpty).join(' · '),
                              style: const TextStyle(fontSize: 11.5, color: teamSubtle),
                            ),
                            if (e.note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: teamBorder),
                                ),
                                child: Text(e.note, style: const TextStyle(fontSize: 13, color: teamInk, height: 1.4)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}

/// Horizontal scroll of filter chips.
class TeamFilterChips<T> extends StatelessWidget {
  final List<(T?, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;
  const TeamFilterChips({super.key, required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (value, label) = options[i];
            final on = value == selected;
            return ChoiceChip(
              label: Text(label),
              selected: on,
              showCheckmark: false,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                onChanged(value);
              },
              labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? Colors.white : teamInk),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: on ? AppColors.primary : teamBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          },
        ),
      );
}

/// Searchable list of people ("Me" first). Returns null when dismissed.
Future<TeamMember?> pickTeamMember(BuildContext context, {String currentId = ''}) =>
    showModalBottomSheet<TeamMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MemberSheet(currentId: currentId),
    );

class _MemberSheet extends ConsumerStatefulWidget {
  final String currentId;
  const _MemberSheet({required this.currentId});

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamMembersProvider);
    final me = ref.watch(teamWorkUserProvider).value?.id;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: teamBorder, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Assign to', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: teamInk)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search people',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: teamPageBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString(), style: teamBodyStyle)),
                data: (people) {
                  final list = people.where((p) => _q.isEmpty || p.name.toLowerCase().contains(_q)).toList();
                  if (list.isEmpty) return const Center(child: Text('No one found', style: teamBodyStyle));
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ListTile(
                        leading: TicketPersonAvatar(name: p.name, size: 36),
                        title: Text(p.id == me ? '${p.name} (Me)' : p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, color: teamInk)),
                        trailing: p.id == widget.currentId
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled form section used by the Team Work forms.
class TeamFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final String? error;
  const TeamFormField({super.key, required this.label, required this.child, this.error});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: teamInk)),
            const SizedBox(height: 8),
            child,
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
}

InputDecoration teamInput(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teamBorder)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teamBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.6)),
    );

/// Tappable white box showing a value (dropdown / date / person picker).
class TeamPickerBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool placeholder;
  final VoidCallback? onTap;
  final Widget? leading;
  const TeamPickerBox({
    super.key,
    required this.icon,
    required this.text,
    this.placeholder = false,
    this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: onTap == null ? teamPageBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: teamBorder)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                leading ?? Icon(icon, size: 20, color: teamSubtle),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: placeholder ? FontWeight.w500 : FontWeight.w600,
                          color: placeholder ? teamSubtle : teamInk)),
                ),
                if (onTap != null) const Icon(Icons.expand_more_rounded, color: teamSubtle),
              ],
            ),
          ),
        ),
      );
}

/// Picks one of [options] from a bottom sheet.
Future<T?> pickTeamOption<T>(BuildContext context,
        {required String title, required List<(T, String)> options, T? current}) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: teamBorder, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: teamInk)),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final (value, label) in options)
                      ListTile(
                        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: teamInk)),
                        trailing: value == current ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        onTap: () => Navigator.pop(ctx, value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
