import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/model/ExhibitionModel.dart' show extractList, extractObject;
import '../auth/model/TeamWorkModel.dart';
import '../core/network/DioClient.dart';
import 'app_endpoint.dart';

/// Storage for Team Work. [LocalTeamWorkRepository] is the demo mode used
/// until the backend is ready; [ApiTeamWorkRepository] follows
/// docs/TEAMWORK_API.md. Switch in `teamWorkRepositoryProvider`
/// (viewModel/teamwork_viewmodel.dart).
abstract class TeamWorkRepository {
  Future<List<Project>> fetchProjects();

  /// Creates [p] when its id is empty, otherwise updates it.
  Future<Project> saveProject(Project p);

  /// [all] = every task (Admin); else the tasks assigned to [userId].
  Future<List<WorkTask>> fetchTasks({required String userId, required bool all});

  Future<WorkTask> createTask(CreateTaskRequest req, {required TeamMember by});

  Future<WorkTask> updateStatus(String taskId, TaskStatus status, {String note = '', required String byName});

  Future<WorkTask> reassign(String taskId, TeamMember to, {required String byName});

  Future<WorkTask> addNote(String taskId, String note, {required String byName});

  /// People a task can be assigned to. Empty when the API has no list (the
  /// view model then offers the reporting members).
  Future<List<TeamMember>> fetchMembers();

  Future<List<Announcement>> fetchAnnouncements();

  Future<Announcement> postAnnouncement({
    required String title,
    required String body,
    required bool important,
    required String byName,
  });
}

/// Demo mode: everything kept in shared_preferences on this phone, shared
/// by every user who logs in on it (so Admin assigning and a developer
/// finishing a task can be tried on one device).
class LocalTeamWorkRepository implements TeamWorkRepository {
  static const _projectsKey = 'teamwork_projects_v1';
  static const _tasksKey = 'teamwork_tasks_v1';
  static const _announcementsKey = 'teamwork_announcements_v1';

  final _random = Random();
  final DateTime Function() _now;

  LocalTeamWorkRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  String _newId() => '${_now().millisecondsSinceEpoch}${_random.nextInt(900) + 100}';

  Future<List<T>> _read<T>(String key, T Function(Map<String, dynamic>) parse) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) => parse(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  Future<List<Project>> _projects() => _read(_projectsKey, Project.fromJson);
  Future<List<WorkTask>> _tasks() => _read(_tasksKey, WorkTask.fromJson);

  Future<void> _saveTasks(List<WorkTask> tasks) => _write(_tasksKey, tasks.map((t) => t.toJson()).toList());
  Future<void> _saveProjects(List<Project> ps) => _write(_projectsKey, ps.map((p) => p.toJson()).toList());

  /// Keeps milestone completion in step with its tasks.
  Future<void> _syncMilestones(String projectId, List<WorkTask> tasks) async {
    final ps = await _projects();
    final i = ps.indexWhere((p) => p.id == projectId);
    if (i < 0) return;
    ps[i] = ps[i].copyWith(milestones: syncMilestones(ps[i], tasks, _now()));
    await _saveProjects(ps);
  }

  @override
  Future<List<Project>> fetchProjects() => _projects();

  @override
  Future<Project> saveProject(Project p) async {
    final ps = await _projects();
    String fill(String id) => id.isEmpty ? _newId() : id;
    final saved = Project(
      id: fill(p.id),
      name: p.name,
      description: p.description,
      color: p.color,
      modules: [for (final m in p.modules) ProjectModule(id: fill(m.id), name: m.name)],
      milestones: [
        for (final m in p.milestones)
          Milestone(id: fill(m.id), title: m.title, dueDate: m.dueDate, completedAt: m.completedAt),
      ],
      createdAt: p.createdAt ?? _now(),
    );
    final i = ps.indexWhere((x) => x.id == saved.id);
    if (i < 0) {
      ps.add(saved);
    } else {
      ps[i] = saved;
    }
    await _saveProjects(ps);
    await _syncMilestones(saved.id, await _tasks());
    return (await _projects()).firstWhere((x) => x.id == saved.id);
  }

  @override
  Future<List<WorkTask>> fetchTasks({required String userId, required bool all}) async {
    final items = await _tasks();
    return all ? items : items.where((t) => t.assigneeId == userId).toList();
  }

  @override
  Future<WorkTask> createTask(CreateTaskRequest req, {required TeamMember by}) async {
    final now = _now();
    final t = WorkTask(
      id: _newId(),
      projectId: req.projectId,
      moduleId: req.moduleId,
      milestoneId: req.milestoneId,
      title: req.title,
      description: req.description,
      priority: req.priority,
      assigneeId: req.assignee.id,
      assigneeName: req.assignee.name,
      assignedById: by.id,
      assignedByName: by.name,
      startDate: req.startDate,
      dueDate: req.dueDate,
      createdAt: now,
      updatedAt: now,
      history: [
        TaskEvent(event: 'created', status: TaskStatus.todo, byName: by.name, at: now),
        TaskEvent(
          event: 'assign',
          status: TaskStatus.todo,
          byName: by.name,
          at: now,
          assignedToName: req.assignee.name,
        ),
      ],
    );
    final items = await _tasks()
      ..add(t);
    await _saveTasks(items);
    await _syncMilestones(t.projectId, items);
    return t;
  }

  Future<WorkTask> _update(String taskId, WorkTask Function(WorkTask t, DateTime now) change) async {
    final items = await _tasks();
    final i = items.indexWhere((t) => t.id == taskId);
    if (i < 0) throw ApiException('Task not found');
    final t = change(items[i], _now());
    items[i] = t;
    await _saveTasks(items);
    return t;
  }

  @override
  Future<WorkTask> updateStatus(String taskId, TaskStatus status, {String note = '', required String byName}) async {
    final t = await _update(
      taskId,
      (t, now) => t.copyWith(
        status: status,
        completedAt: status == TaskStatus.done ? now : null,
        clearCompleted: status != TaskStatus.done,
        updatedAt: now,
        history: [...t.history, TaskEvent(event: 'status', status: status, note: note, byName: byName, at: now)],
      ),
    );
    await _syncMilestones(t.projectId, await _tasks());
    return t;
  }

  @override
  Future<WorkTask> reassign(String taskId, TeamMember to, {required String byName}) => _update(
        taskId,
        (t, now) => t.copyWith(
          assignee: to,
          updatedAt: now,
          history: [
            ...t.history,
            TaskEvent(event: 'assign', status: t.status, byName: byName, at: now, assignedToName: to.name),
          ],
        ),
      );

  @override
  Future<WorkTask> addNote(String taskId, String note, {required String byName}) => _update(
        taskId,
        (t, now) => t.copyWith(
          updatedAt: now,
          history: [...t.history, TaskEvent(event: 'note', status: t.status, note: note, byName: byName, at: now)],
        ),
      );

  @override
  Future<List<TeamMember>> fetchMembers() async => const [];

  @override
  Future<List<Announcement>> fetchAnnouncements() => _read(_announcementsKey, Announcement.fromJson);

  @override
  Future<Announcement> postAnnouncement({
    required String title,
    required String body,
    required bool important,
    required String byName,
  }) async {
    final a = Announcement(
      id: _newId(),
      title: title,
      body: body,
      important: important,
      byName: byName,
      createdAt: _now(),
    );
    final items = await fetchAnnouncements()
      ..add(a);
    await _write(_announcementsKey, items.map((x) => x.toJson()).toList());
    return a;
  }
}

/// Backend implementation of docs/TEAMWORK_API.md.
class ApiTeamWorkRepository implements TeamWorkRepository {
  final DioClient _client;
  ApiTeamWorkRepository(this._client);

  Dio get _dio => _client.dio;

  Future<Options> _options() async {
    final token = await _client.getToken() ?? '';
    return Options(
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      contentType: Headers.jsonContentType,
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final err = e.error;
      if (err is ApiException) throw err;
      throw ApiException(e.message ?? 'Something went wrong. Please try again.', statusCode: e.response?.statusCode);
    }
  }

  void _ensureOk(Response res) {
    final body = res.data;
    if (body is Map) {
      final status = (body['status'] ?? body['Status'])?.toString().toLowerCase();
      if (status == 'error' || status == 'failed' || body['success'] == false) {
        throw ApiException(
          (body['message'] ?? body['Message'] ?? 'Request failed').toString(),
          statusCode: res.statusCode,
        );
      }
    }
  }

  Future<Map<String, dynamic>> _send(String method, String path, {Object? data, Map<String, dynamic>? query}) =>
      _guard(() async {
        final res = await _dio.request(
          path,
          data: data,
          queryParameters: query,
          options: (await _options()).copyWith(method: method),
        );
        _ensureOk(res);
        return res.data is Map ? (res.data as Map).cast<String, dynamic>() : <String, dynamic>{};
      });

  WorkTask _task(Map<String, dynamic> body) => WorkTask.fromJson(extractObject(body, ['task']));

  @override
  Future<List<Project>> fetchProjects() async =>
      extractList(await _send('GET', AppEndpoint.teamProjects), ['projects']).map(Project.fromJson).toList();

  @override
  Future<Project> saveProject(Project p) async {
    final body = p.toJson()..remove('id');
    final res = p.id.isEmpty
        ? await _send('POST', AppEndpoint.teamProjects, data: body)
        : await _send('PUT', AppEndpoint.teamProjectById(p.id), data: body);
    return Project.fromJson(extractObject(res, ['project']));
  }

  @override
  Future<List<WorkTask>> fetchTasks({required String userId, required bool all}) async => extractList(
        await _send('GET', AppEndpoint.teamTasks, query: {'scope': all ? 'all' : 'mine'}),
        ['tasks'],
      ).map(WorkTask.fromJson).toList();

  @override
  Future<WorkTask> createTask(CreateTaskRequest req, {required TeamMember by}) async =>
      _task(await _send('POST', AppEndpoint.teamTasks, data: req.toJson()));

  @override
  Future<WorkTask> updateStatus(String taskId, TaskStatus status, {String note = '', required String byName}) async =>
      _task(await _send('PUT', AppEndpoint.teamTaskStatus(taskId), data: {'status': status.apiValue, 'note': note}));

  @override
  Future<WorkTask> reassign(String taskId, TeamMember to, {required String byName}) async => _task(
      await _send('PUT', AppEndpoint.teamTaskAssign(taskId), data: {'assigneeId': to.id, 'assigneeName': to.name}));

  @override
  Future<WorkTask> addNote(String taskId, String note, {required String byName}) async =>
      _task(await _send('POST', AppEndpoint.teamTaskNotes(taskId), data: {'note': note}));

  @override
  Future<List<TeamMember>> fetchMembers() async =>
      extractList(await _send('GET', AppEndpoint.teamMembers), ['members'])
          .map((m) => (id: '${m['id'] ?? ''}', name: '${m['name'] ?? ''}'.trim()))
          .where((m) => m.id.isNotEmpty)
          .toList();

  @override
  Future<List<Announcement>> fetchAnnouncements() async =>
      extractList(await _send('GET', AppEndpoint.teamAnnouncements), ['announcements'])
          .map(Announcement.fromJson)
          .toList();

  @override
  Future<Announcement> postAnnouncement({
    required String title,
    required String body,
    required bool important,
    required String byName,
  }) async =>
      Announcement.fromJson(extractObject(
        await _send('POST', AppEndpoint.teamAnnouncements, data: {'title': title, 'body': body, 'important': important}),
        ['announcement'],
      ));
}
