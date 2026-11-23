import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/model/TeamWorkModel.dart';
import '../core/teamwork/team_notifier.dart';
import '../provider/app_providers.dart';
import '../repository/teamwork_repository.dart';
import 'login_view_model.dart';
import 'reporting_members_dd_viewmodel.dart';

/// false = demo mode (data on this phone only). Set true once the backend
/// implements docs/TEAMWORK_API.md.
const bool kTeamWorkUseApi = false;

final teamWorkRepositoryProvider = Provider<TeamWorkRepository>(
  (ref) => kTeamWorkUseApi ? ApiTeamWorkRepository(ref.read(dioProvider)) : LocalTeamWorkRepository(),
);

/// The logged-in user as Team Work sees them.
typedef TeamWorkUser = ({String id, String name, bool isAdmin, bool isDeveloper});

final teamWorkUserProvider = FutureProvider<TeamWorkUser?>((ref) async {
  final login = await ref.watch(loginProvider.future);
  if (login == null) return null;
  return (
    id: login.userId.toString(),
    name: login.name,
    isAdmin: isTeamWorkAdmin(login.roleCode),
    isDeveloper: isDeveloperRole(login.roleCode),
  );
});

Duration? _noRetry(int retryCount, Object error) => null;

final projectsProvider = FutureProvider.autoDispose<List<Project>>(retry: _noRetry, (ref) async {
  final items = await ref.read(teamWorkRepositoryProvider).fetchProjects();
  return [...items]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Admin: every task. Developer: tasks assigned to them. Most recently
/// updated first.
final tasksProvider = FutureProvider.autoDispose<List<WorkTask>>(retry: _noRetry, (ref) async {
  final user = await ref.watch(teamWorkUserProvider.future);
  if (user == null) return [];
  final items = await ref.read(teamWorkRepositoryProvider).fetchTasks(userId: user.id, all: user.isAdmin);
  return [...items]..sort((a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(a.updatedAt ?? DateTime(1970)));
});

/// Every task, for the leaderboard (developers see the whole team's ranking).
final allTasksProvider = FutureProvider.autoDispose<List<WorkTask>>(retry: _noRetry, (ref) async {
  final user = await ref.watch(teamWorkUserProvider.future);
  return ref.read(teamWorkRepositoryProvider).fetchTasks(userId: user?.id ?? '', all: true);
});

final taskProvider = Provider.autoDispose.family<AsyncValue<WorkTask?>, String>(
  (ref, id) => ref.watch(tasksProvider).whenData((ts) => ts.where((t) => t.id == id).firstOrNull),
);

final announcementsProvider = FutureProvider.autoDispose<List<Announcement>>(retry: _noRetry, (ref) async {
  final items = await ref.read(teamWorkRepositoryProvider).fetchAnnouncements();
  return [...items]..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
});

class DevPeriodNotifier extends Notifier<DevPeriod> {
  @override
  DevPeriod build() => DevPeriod.month;
  void set(DevPeriod p) => state = p;
}

final devPeriodProvider = NotifierProvider<DevPeriodNotifier, DevPeriod>(DevPeriodNotifier.new);

final devLeaderboardProvider = FutureProvider.autoDispose<List<RankedDev>>(retry: _noRetry, (ref) async {
  final period = ref.watch(devPeriodProvider);
  final tasks = await ref.watch(allTasksProvider.future);
  final projects = await ref.watch(projectsProvider.future);
  return rankDevelopers(tasks, projects, period, DateTime.now());
});

// ─────────────────────────────────────────────────────────────────────────
// Announcement read state (per user, on this device)
// ─────────────────────────────────────────────────────────────────────────

class AnnouncementReadNotifier extends AsyncNotifier<Set<String>> {
  String _key = '';

  @override
  Future<Set<String>> build() async {
    final user = await ref.watch(teamWorkUserProvider.future);
    _key = 'teamwork_ann_read_v1_${user?.id ?? ''}';
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> markRead(Iterable<String> ids) async {
    final next = {...(state.value ?? const <String>{}), ...ids};
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final announcementReadProvider =
    AsyncNotifierProvider<AnnouncementReadNotifier, Set<String>>(AnnouncementReadNotifier.new);

final unreadAnnouncementCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(announcementsProvider).value ?? const [];
  final read = ref.watch(announcementReadProvider).value ?? const <String>{};
  return items.where((a) => !read.contains(a.id)).length;
});

/// Watched by the Team Work hub: on open and on every app resume, notifies
/// for tasks newly assigned to the user and new announcements.
final teamNotificationWatchProvider = FutureProvider.autoDispose<void>((ref) async {
  final listener = AppLifecycleListener(onResume: ref.invalidateSelf);
  ref.onDispose(listener.dispose);
  final user = await ref.watch(teamWorkUserProvider.future);
  if (user == null) return;
  try {
    final repo = ref.read(teamWorkRepositoryProvider);
    final mine = await repo.fetchTasks(userId: user.id, all: false);
    final ann = await repo.fetchAnnouncements();
    await TeamNotifier.instance.check(userId: user.id, myTasks: mine, announcements: ann);
  } catch (_) {
    // Offline or API down: try again on the next resume.
  }
});

/// People a task can be assigned to: the API's list when it has one,
/// otherwise the Admin's reporting members, with the Admin first ("Me").
final teamMembersProvider = FutureProvider.autoDispose<List<TeamMember>>((ref) async {
  final user = await ref.watch(teamWorkUserProvider.future);
  final list = <TeamMember>[
    ...await ref.read(teamWorkRepositoryProvider).fetchMembers().catchError((_) => <TeamMember>[]),
  ];
  if (list.isEmpty) {
    try {
      final members = await ref.read(reportingmembersProvider.future);
      list.addAll(members.map((m) => (id: '${m.idmember}', name: m.membername.trim())));
    } catch (_) {}
  }
  final seen = <String>{};
  final out = <TeamMember>[if (user != null) (id: user.id, name: user.name)];
  seen.addAll(out.map((m) => m.id));
  for (final m in list..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))) {
    if (m.name.isNotEmpty && seen.add(m.id)) out.add(m);
  }
  return out;
});

// ─────────────────────────────────────────────────────────────────────────
// Actions
// ─────────────────────────────────────────────────────────────────────────

class TeamWorkActions {
  final Ref _ref;
  TeamWorkActions(this._ref);

  TeamWorkRepository get _repo => _ref.read(teamWorkRepositoryProvider);

  Future<TeamWorkUser> _user() async {
    final u = await _ref.read(teamWorkUserProvider.future);
    if (u == null) throw StateError('Please log in again.');
    return u;
  }

  void _refreshTasks() {
    _ref.invalidate(tasksProvider);
    _ref.invalidate(allTasksProvider);
    _ref.invalidate(projectsProvider); // milestones follow their tasks
  }

  Future<Project> saveProject(Project p) async {
    final saved = await _repo.saveProject(p);
    _ref.invalidate(projectsProvider);
    return saved;
  }

  Future<WorkTask> createTask(CreateTaskRequest req) async {
    final u = await _user();
    final t = await _repo.createTask(req, by: (id: u.id, name: u.name));
    _refreshTasks();
    return t;
  }

  Future<WorkTask> setStatus(WorkTask t, TaskStatus status, {String note = ''}) async {
    final u = await _user();
    final out = await _repo.updateStatus(t.id, status, note: note, byName: u.name);
    _refreshTasks();
    return out;
  }

  Future<WorkTask> reassign(WorkTask t, TeamMember to) async {
    final u = await _user();
    final out = await _repo.reassign(t.id, to, byName: u.name);
    _refreshTasks();
    return out;
  }

  Future<WorkTask> addNote(WorkTask t, String note) async {
    final u = await _user();
    final out = await _repo.addNote(t.id, note, byName: u.name);
    _refreshTasks();
    return out;
  }

  Future<Announcement> postAnnouncement({required String title, required String body, required bool important}) async {
    final u = await _user();
    final a = await _repo.postAnnouncement(title: title, body: body, important: important, byName: u.name);
    _ref.invalidate(announcementsProvider);
    await _ref.read(announcementReadProvider.notifier).markRead([a.id]);
    return a;
  }
}

final teamWorkActionsProvider = Provider<TeamWorkActions>(TeamWorkActions.new);
