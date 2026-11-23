import 'package:flutter/material.dart';

/// Models for the Team Work module (developer tasks, projects, milestones,
/// announcements). JSON keys follow docs/TEAMWORK_API.md.

/// True for a developer login (roleCode "Developer"); they get the
/// Developer Dashboard instead of the sales dashboard.
bool isDeveloperRole(String roleCode) => roleCode.trim().toLowerCase() == 'developer';

/// Only Admin assigns tasks, manages projects and posts announcements.
bool isTeamWorkAdmin(String roleCode) => roleCode.trim().toLowerCase() == 'admin';

String _s(Map<String, dynamic> j, String key) => (j[key] ?? '').toString().trim();

DateTime? _date(dynamic v) {
  final s = (v ?? '').toString().trim();
  return s.isEmpty ? null : DateTime.tryParse(s)?.toLocal();
}

String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList() : const [];

// ─────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────

enum TaskStatus {
  todo('Todo', 'To do', Icons.radio_button_unchecked_rounded, Color(0xFF64748B)),
  inProgress('InProgress', 'In progress', Icons.timelapse_rounded, Color(0xFF2563EB)),
  inReview('InReview', 'In review', Icons.rate_review_rounded, Color(0xFF9333EA)),
  done('Done', 'Done', Icons.check_circle_rounded, Color(0xFF16A34A));

  final String apiValue;
  final String label;
  final IconData icon;
  final Color color;
  const TaskStatus(this.apiValue, this.label, this.icon, this.color);

  static TaskStatus parse(String v) {
    final s = v.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
    return TaskStatus.values.firstWhere((e) => e.apiValue.toLowerCase() == s, orElse: () => TaskStatus.todo);
  }

  bool get isOpen => this != TaskStatus.done;
}

enum TaskPriority {
  low('Low', Color(0xFF0E9F6E), 5),
  medium('Medium', Color(0xFFEA580C), 10),
  high('High', Color(0xFFDC2626), 15);

  final String apiValue;
  final Color color;

  /// Leaderboard points for finishing a task of this priority.
  final int points;
  const TaskPriority(this.apiValue, this.color, this.points);

  static TaskPriority parse(String v) => TaskPriority.values
      .firstWhere((e) => e.apiValue.toLowerCase() == v.trim().toLowerCase(), orElse: () => TaskPriority.medium);
}

// ─────────────────────────────────────────────────────────────────────────
// Projects
// ─────────────────────────────────────────────────────────────────────────

class ProjectModule {
  final String id;
  final String name;
  const ProjectModule({required this.id, required this.name});

  factory ProjectModule.fromJson(Map<String, dynamic> j) => ProjectModule(id: _s(j, 'id'), name: _s(j, 'name'));
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Milestone {
  final String id;
  final String title;
  final DateTime? dueDate;

  /// Set when every task in the milestone is Done.
  final DateTime? completedAt;

  const Milestone({required this.id, required this.title, this.dueDate, this.completedAt});

  bool get isCompleted => completedAt != null;

  factory Milestone.fromJson(Map<String, dynamic> j) => Milestone(
        id: _s(j, 'id'),
        title: _s(j, 'title'),
        dueDate: _date(j['dueDate']),
        completedAt: _date(j['completedAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueDate': _iso(dueDate),
        'completedAt': _iso(completedAt),
      };

  Milestone copyWith({String? title, DateTime? dueDate, DateTime? completedAt, bool clearCompleted = false}) =>
      Milestone(
        id: id,
        title: title ?? this.title,
        dueDate: dueDate ?? this.dueDate,
        completedAt: clearCompleted ? null : completedAt ?? this.completedAt,
      );
}

/// Project colours offered in the project form.
const projectColors = <Color>[
  Color(0xFF2563EB),
  Color(0xFF7C3AED),
  Color(0xFF0E9F6E),
  Color(0xFFEA580C),
  Color(0xFFDB2777),
  Color(0xFF0891B2),
];

class Project {
  final String id;
  final String name;
  final String description;
  final Color color;
  final List<ProjectModule> modules;
  final List<Milestone> milestones;
  final DateTime? createdAt;

  const Project({
    required this.id,
    required this.name,
    this.description = '',
    this.color = const Color(0xFF2563EB),
    this.modules = const [],
    this.milestones = const [],
    this.createdAt,
  });

  ProjectModule? module(String id) => modules.where((m) => m.id == id).firstOrNull;
  Milestone? milestone(String? id) => id == null ? null : milestones.where((m) => m.id == id).firstOrNull;

  factory Project.fromJson(Map<String, dynamic> j) {
    final hex = _s(j, 'color').replaceAll('#', '');
    final c = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return Project(
      id: _s(j, 'id'),
      name: _s(j, 'name'),
      description: _s(j, 'description'),
      color: c == null ? const Color(0xFF2563EB) : Color(c),
      modules: _maps(j['modules']).map(ProjectModule.fromJson).toList(),
      milestones: _maps(j['milestones']).map(Milestone.fromJson).toList(),
      createdAt: _date(j['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color': '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        'modules': modules.map((m) => m.toJson()).toList(),
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'createdAt': _iso(createdAt),
      };

  Project copyWith({
    String? name,
    String? description,
    Color? color,
    List<ProjectModule>? modules,
    List<Milestone>? milestones,
  }) =>
      Project(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        modules: modules ?? this.modules,
        milestones: milestones ?? this.milestones,
        createdAt: createdAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Tasks
// ─────────────────────────────────────────────────────────────────────────

typedef TeamMember = ({String id, String name});

/// One entry on a task's timeline.
class TaskEvent {
  /// `created`, `status`, `assign` or `note`.
  final String event;
  final TaskStatus status;
  final String note;
  final String byName;
  final DateTime? at;

  /// For `assign`: the new assignee's name.
  final String assignedToName;

  const TaskEvent({
    required this.event,
    required this.status,
    this.note = '',
    this.byName = '',
    this.at,
    this.assignedToName = '',
  });

  factory TaskEvent.fromJson(Map<String, dynamic> j) => TaskEvent(
        event: _s(j, 'event').isEmpty ? 'status' : _s(j, 'event'),
        status: TaskStatus.parse(_s(j, 'status')),
        note: _s(j, 'note'),
        byName: _s(j, 'byName'),
        at: _date(j['at']),
        assignedToName: _s(j, 'assignedToName'),
      );

  Map<String, dynamic> toJson() => {
        'event': event,
        'status': status.apiValue,
        'note': note,
        'byName': byName,
        'at': _iso(at),
        'assignedToName': assignedToName,
      };
}

class WorkTask {
  final String id;
  final String projectId;
  final String moduleId;
  final String? milestoneId;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final String assigneeId;
  final String assigneeName;
  final String assignedById;
  final String assignedByName;
  final DateTime? startDate;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TaskEvent> history;

  const WorkTask({
    required this.id,
    required this.projectId,
    required this.moduleId,
    this.milestoneId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.assigneeId = '',
    this.assigneeName = '',
    this.assignedById = '',
    this.assignedByName = '',
    this.startDate,
    this.dueDate,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.history = const [],
  });

  String get displayId => '#T${id.length > 4 ? id.substring(id.length - 4) : id}';

  /// Open and past its due date (by day).
  bool isOverdue([DateTime? now]) {
    if (!status.isOpen || dueDate == null) return false;
    final n = now ?? DateTime.now();
    return DateUtils.dateOnly(dueDate!).isBefore(DateUtils.dateOnly(n));
  }

  /// Done on or before the due date (no due date counts as on time).
  bool get finishedOnTime =>
      completedAt != null &&
      (dueDate == null || !DateUtils.dateOnly(completedAt!).isAfter(DateUtils.dateOnly(dueDate!)));

  factory WorkTask.fromJson(Map<String, dynamic> j) => WorkTask(
        id: _s(j, 'id'),
        projectId: _s(j, 'projectId'),
        moduleId: _s(j, 'moduleId'),
        milestoneId: _s(j, 'milestoneId').isEmpty ? null : _s(j, 'milestoneId'),
        title: _s(j, 'title'),
        description: _s(j, 'description'),
        priority: TaskPriority.parse(_s(j, 'priority')),
        status: TaskStatus.parse(_s(j, 'status')),
        assigneeId: _s(j, 'assigneeId'),
        assigneeName: _s(j, 'assigneeName'),
        assignedById: _s(j, 'assignedById'),
        assignedByName: _s(j, 'assignedByName'),
        startDate: _date(j['startDate']),
        dueDate: _date(j['dueDate']),
        completedAt: _date(j['completedAt']),
        createdAt: _date(j['createdAt']),
        updatedAt: _date(j['updatedAt']),
        history: _maps(j['history']).map(TaskEvent.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'moduleId': moduleId,
        'milestoneId': milestoneId,
        'title': title,
        'description': description,
        'priority': priority.apiValue,
        'status': status.apiValue,
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'assignedById': assignedById,
        'assignedByName': assignedByName,
        'startDate': _iso(startDate),
        'dueDate': _iso(dueDate),
        'completedAt': _iso(completedAt),
        'createdAt': _iso(createdAt),
        'updatedAt': _iso(updatedAt),
        'history': history.map((h) => h.toJson()).toList(),
      };

  WorkTask copyWith({
    TaskStatus? status,
    TeamMember? assignee,
    DateTime? completedAt,
    bool clearCompleted = false,
    DateTime? updatedAt,
    List<TaskEvent>? history,
  }) =>
      WorkTask(
        id: id,
        projectId: projectId,
        moduleId: moduleId,
        milestoneId: milestoneId,
        title: title,
        description: description,
        priority: priority,
        status: status ?? this.status,
        assigneeId: assignee?.id ?? assigneeId,
        assigneeName: assignee?.name ?? assigneeName,
        assignedById: assignedById,
        assignedByName: assignedByName,
        startDate: startDate,
        dueDate: dueDate,
        completedAt: clearCompleted ? null : completedAt ?? this.completedAt,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        history: history ?? this.history,
      );
}

class CreateTaskRequest {
  final String projectId;
  final String moduleId;
  final String? milestoneId;
  final String title;
  final String description;
  final TaskPriority priority;
  final TeamMember assignee;
  final DateTime? startDate;
  final DateTime? dueDate;

  const CreateTaskRequest({
    required this.projectId,
    required this.moduleId,
    this.milestoneId,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    required this.assignee,
    this.startDate,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
        'projectId': projectId,
        'moduleId': moduleId,
        'milestoneId': milestoneId,
        'title': title,
        'description': description,
        'priority': priority.apiValue,
        'assigneeId': assignee.id,
        'assigneeName': assignee.name,
        'startDate': _iso(startDate),
        'dueDate': _iso(dueDate),
      };
}

/// Statuses the user can move [t] to. The assignee moves it forward
/// (Todo → In progress → In review); Admin approves (Done), sends it back
/// or reopens it.
List<TaskStatus> nextStatuses(WorkTask t, {required bool isAdmin, required bool isAssignee}) {
  final out = <TaskStatus>[];
  switch (t.status) {
    case TaskStatus.todo:
      if (isAssignee || isAdmin) out.add(TaskStatus.inProgress);
    case TaskStatus.inProgress:
      if (isAssignee || isAdmin) out.add(TaskStatus.inReview);
      if (isAdmin) out.add(TaskStatus.done);
    case TaskStatus.inReview:
      if (isAdmin) out.addAll([TaskStatus.done, TaskStatus.inProgress]);
    case TaskStatus.done:
      if (isAdmin) out.add(TaskStatus.inProgress);
  }
  return out;
}

/// Milestones whose completion follows from [tasks]: completed when every
/// task in it is Done (and it has at least one), otherwise not.
List<Milestone> syncMilestones(Project p, List<WorkTask> tasks, DateTime now) => [
      for (final m in p.milestones)
        () {
          final mine = tasks.where((t) => t.projectId == p.id && t.milestoneId == m.id).toList();
          final done = mine.isNotEmpty && mine.every((t) => t.status == TaskStatus.done);
          if (done && !m.isCompleted) return m.copyWith(completedAt: now);
          if (!done && m.isCompleted) return m.copyWith(clearCompleted: true);
          return m;
        }(),
    ];

// ─────────────────────────────────────────────────────────────────────────
// Announcements
// ─────────────────────────────────────────────────────────────────────────

class Announcement {
  final String id;
  final String title;
  final String body;
  final bool important;
  final String byName;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.title,
    this.body = '',
    this.important = false,
    this.byName = '',
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: _s(j, 'id'),
        title: _s(j, 'title'),
        body: _s(j, 'body'),
        important: j['important'] == true || _s(j, 'important').toLowerCase() == 'true',
        byName: _s(j, 'byName'),
        createdAt: _date(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'important': important,
        'byName': byName,
        'createdAt': _iso(createdAt),
      };
}

// ─────────────────────────────────────────────────────────────────────────
// Developer leaderboard (tasks + milestones)
// ─────────────────────────────────────────────────────────────────────────

enum DevPeriod {
  week('This Week'),
  month('This Month'),
  quarter('This Quarter');

  final String label;
  const DevPeriod(this.label);

  DateTime start(DateTime now) {
    final d = DateUtils.dateOnly(now);
    return switch (this) {
      DevPeriod.week => d.subtract(Duration(days: d.weekday - 1)),
      DevPeriod.month => DateTime(d.year, d.month),
      DevPeriod.quarter => DateTime(d.year, ((d.month - 1) ~/ 3) * 3 + 1),
    };
  }
}

const kOnTimeBonus = 5;
const kLatePenalty = 3;
const kMinTaskPoints = 2;
const kMilestoneBonus = 20;

/// Points for one Done task: priority points, +5 on time, −3 late (at
/// least 2).
int taskPoints(WorkTask t) {
  if (t.status != TaskStatus.done) return 0;
  final base = t.priority.points;
  return t.finishedOnTime ? base + kOnTimeBonus : (base - kLatePenalty).clamp(kMinTaskPoints, base);
}

class DevScore {
  final TeamMember member;
  final int points;
  final int tasksDone;
  final int onTime;
  final int milestones;
  final int openTasks;

  const DevScore({
    required this.member,
    required this.points,
    required this.tasksDone,
    required this.onTime,
    required this.milestones,
    required this.openTasks,
  });

  double get onTimeRate => tasksDone == 0 ? 0 : onTime / tasksDone;
}

class RankedDev {
  final int rank;
  final DevScore score;
  const RankedDev(this.rank, this.score);
}

/// Scores every assignee in [tasks] for tasks completed since
/// [period]'s start, plus +20 for each milestone completed in the period
/// in which they had a task. Ranked by points (ties share a rank), then
/// tasks done, then name.
List<RankedDev> rankDevelopers(List<WorkTask> tasks, List<Project> projects, DevPeriod period, DateTime now) {
  final from = period.start(now);
  bool inPeriod(DateTime? d) => d != null && !d.isBefore(from) && !d.isAfter(now.add(const Duration(days: 1)));

  final names = <String, String>{};
  final points = <String, int>{};
  final done = <String, int>{};
  final onTime = <String, int>{};
  final open = <String, int>{};
  final milestones = <String, int>{};

  for (final t in tasks) {
    if (t.assigneeId.isEmpty) continue;
    names[t.assigneeId] = t.assigneeName;
    points.putIfAbsent(t.assigneeId, () => 0);
    if (t.status.isOpen) open[t.assigneeId] = (open[t.assigneeId] ?? 0) + 1;
    if (t.status == TaskStatus.done && inPeriod(t.completedAt)) {
      points[t.assigneeId] = points[t.assigneeId]! + taskPoints(t);
      done[t.assigneeId] = (done[t.assigneeId] ?? 0) + 1;
      if (t.finishedOnTime) onTime[t.assigneeId] = (onTime[t.assigneeId] ?? 0) + 1;
    }
  }
  for (final p in projects) {
    for (final m in p.milestones) {
      if (!inPeriod(m.completedAt)) continue;
      final people = tasks
          .where((t) => t.projectId == p.id && t.milestoneId == m.id && t.assigneeId.isNotEmpty)
          .map((t) => t.assigneeId)
          .toSet();
      for (final id in people) {
        points[id] = (points[id] ?? 0) + kMilestoneBonus;
        milestones[id] = (milestones[id] ?? 0) + 1;
      }
    }
  }

  final scores = [
    for (final id in points.keys)
      DevScore(
        member: (id: id, name: names[id] ?? ''),
        points: points[id] ?? 0,
        tasksDone: done[id] ?? 0,
        onTime: onTime[id] ?? 0,
        milestones: milestones[id] ?? 0,
        openTasks: open[id] ?? 0,
      ),
  ]..sort((a, b) {
      final c = b.points.compareTo(a.points);
      if (c != 0) return c;
      final d = b.tasksDone.compareTo(a.tasksDone);
      if (d != 0) return d;
      return a.member.name.toLowerCase().compareTo(b.member.name.toLowerCase());
    });

  final out = <RankedDev>[];
  for (var i = 0; i < scores.length; i++) {
    final rank = i > 0 && scores[i].points == scores[i - 1].points ? out[i - 1].rank : i + 1;
    out.add(RankedDev(rank, scores[i]));
  }
  return out;
}
