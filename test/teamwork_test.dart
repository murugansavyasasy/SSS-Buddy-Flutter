import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/TeamWorkModel.dart';
import 'package:sssbuddy/core/feature_flags.dart';
import 'package:sssbuddy/repository/teamwork_repository.dart';
import 'package:sssbuddy/repository/ticket_repository.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/view/teamwork/announcement_list_view.dart';
import 'package:sssbuddy/view/teamwork/dev_dashboard_view.dart';
import 'package:sssbuddy/view/teamwork/dev_leaderboard_view.dart';
import 'package:sssbuddy/view/teamwork/project_detail_view.dart';
import 'package:sssbuddy/view/teamwork/project_form_view.dart';
import 'package:sssbuddy/view/teamwork/project_list_view.dart';
import 'package:sssbuddy/view/teamwork/task_detail_view.dart';
import 'package:sssbuddy/view/teamwork/task_form_view.dart';
import 'package:sssbuddy/view/teamwork/task_list_view.dart';
import 'package:sssbuddy/viewModel/teamwork_viewmodel.dart';
import 'package:sssbuddy/viewModel/ticket_viewmodel.dart';

final _now = DateTime(2026, 11, 18, 10); // a Wednesday

WorkTask _task(
  String id, {
  String who = '1',
  String name = 'Kavin',
  TaskStatus status = TaskStatus.done,
  TaskPriority priority = TaskPriority.medium,
  DateTime? due,
  DateTime? completed,
  String project = 'p',
  String? milestone,
}) =>
    WorkTask(
      id: id,
      projectId: project,
      moduleId: 'm',
      milestoneId: milestone,
      title: 'Task $id',
      priority: priority,
      status: status,
      assigneeId: who,
      assigneeName: name,
      dueDate: due,
      completedAt: completed ?? (status == TaskStatus.done ? _now : null),
    );

void main() {
  group('roles and routing', () {
    test('developer role is detected case-insensitively', () {
      expect(isDeveloperRole('Developer'), isTrue);
      expect(isDeveloperRole(' developer '), isTrue);
      expect(isDeveloperRole('Admin'), isFalse);
      expect(isTeamWorkAdmin('admin'), isTrue);
      expect(isTeamWorkAdmin('Support'), isFalse);
    });

    test('developers land on the Developer Dashboard', () {
      expect(homeRouteFor('Developer'), kTeamWorkEnabled ? RoutesName.devDashboard : RoutesName.dashboard);
      expect(homeRouteFor('Admin'), RoutesName.dashboard);
      expect(homeRouteFor(null), RoutesName.dashboard);
    });
  });

  group('points', () {
    test('priority points, on-time bonus and late penalty', () {
      final due = DateTime(2026, 11, 18);
      expect(taskPoints(_task('a', priority: TaskPriority.high, due: due)), 15 + kOnTimeBonus);
      expect(taskPoints(_task('b', priority: TaskPriority.medium, due: due, completed: DateTime(2026, 11, 20))),
          10 - kLatePenalty);
      expect(taskPoints(_task('c', priority: TaskPriority.low, due: due, completed: DateTime(2026, 11, 20))),
          kMinTaskPoints);
      expect(taskPoints(_task('d', status: TaskStatus.inProgress)), 0);
    });

    test('ranking adds the milestone bonus and shares ranks on ties', () {
      final project = Project(
        id: 'p',
        name: 'App',
        milestones: [Milestone(id: 'ms', title: 'Beta', completedAt: _now)],
      );
      final tasks = [
        _task('1', who: '1', name: 'Kavin', milestone: 'ms'), // 10 + 5 + 20
        _task('2', who: '2', name: 'Saran', priority: TaskPriority.high), // 15 + 5
        _task('3', who: '2', name: 'Saran', priority: TaskPriority.high), // 15 + 5
        _task('4', who: '3', name: 'Chan', priority: TaskPriority.high, completed: DateTime(2026, 9, 1)), // old
        _task('5', who: '4', name: 'Anu', status: TaskStatus.todo),
      ];
      final board = rankDevelopers(tasks, [project], DevPeriod.month, _now);
      expect(board.first.score.member.name, 'Saran');
      expect(board.first.score.points, 40);
      expect(board[1].score.member.name, 'Kavin');
      expect(board[1].score.points, 35);
      expect(board[1].score.milestones, 1);
      // Chan (old task) and Anu (nothing done) both have 0: shared rank.
      expect(board[2].score.points, 0);
      expect(board[3].rank, board[2].rank);
    });

    test('period starts', () {
      expect(DevPeriod.week.start(_now), DateTime(2026, 11, 16));
      expect(DevPeriod.month.start(_now), DateTime(2026, 11));
      expect(DevPeriod.quarter.start(_now), DateTime(2026, 10));
    });
  });

  group('status rules', () {
    final t = _task('x', who: '7', status: TaskStatus.todo);
    test('assignee moves forward, admin approves', () {
      expect(nextStatuses(t, isAdmin: false, isAssignee: true), [TaskStatus.inProgress]);
      expect(nextStatuses(t, isAdmin: false, isAssignee: false), isEmpty);
      final review = _task('y', status: TaskStatus.inReview);
      expect(nextStatuses(review, isAdmin: false, isAssignee: true), isEmpty);
      expect(nextStatuses(review, isAdmin: true, isAssignee: false), [TaskStatus.done, TaskStatus.inProgress]);
    });
  });

  group('local repository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('task round trip, timeline and milestone completion', () async {
      final repo = LocalTeamWorkRepository();
      final p = await repo.saveProject(const Project(
        id: '',
        name: 'SSS Score',
        modules: [ProjectModule(id: '', name: 'Login')],
        milestones: [Milestone(id: '', title: 'Beta')],
      ));
      expect(p.id, isNotEmpty);
      expect(p.modules.single.id, isNotEmpty);
      final ms = p.milestones.single;

      final t = await repo.createTask(
        CreateTaskRequest(
          projectId: p.id,
          moduleId: p.modules.single.id,
          milestoneId: ms.id,
          title: 'OTP screen',
          assignee: (id: '7', name: 'Kavin'),
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
        by: (id: '1', name: 'Lead'),
      );
      expect(t.history.map((e) => e.event), ['created', 'assign']);
      expect(await repo.fetchTasks(userId: '7', all: false), hasLength(1));
      expect(await repo.fetchTasks(userId: '8', all: false), isEmpty);

      await repo.updateStatus(t.id, TaskStatus.inProgress, byName: 'Kavin');
      await repo.addNote(t.id, 'API ready', byName: 'Kavin');
      final done = await repo.updateStatus(t.id, TaskStatus.done, note: 'Looks good', byName: 'Lead');
      expect(done.completedAt, isNotNull);
      expect(done.history, hasLength(5));
      expect((await repo.fetchProjects()).single.milestones.single.isCompleted, isTrue);

      final reopened = await repo.updateStatus(t.id, TaskStatus.inProgress, byName: 'Lead');
      expect(reopened.completedAt, isNull);
      expect((await repo.fetchProjects()).single.milestones.single.isCompleted, isFalse);

      final moved = await repo.reassign(t.id, (id: '9', name: 'Saran'), byName: 'Lead');
      expect(moved.assigneeName, 'Saran');
      expect(moved.history.last.assignedToName, 'Saran');
    });

    test('announcements are stored', () async {
      final repo = LocalTeamWorkRepository();
      await repo.postAnnouncement(title: 'Release Friday', body: 'Freeze at 5 PM', important: true, byName: 'Lead');
      final items = await repo.fetchAnnouncements();
      expect(items.single.important, isTrue);
      expect(Announcement.fromJson(items.single.toJson()).title, 'Release Friday');
    });
  });

  group('screens render without overflow', () {
    late String taskId;
    late String projectId;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalTeamWorkRepository();
      final p = await repo.saveProject(Project(
        id: '',
        name: 'School Chimes ERP',
        description: 'Admissions, fees and exams',
        modules: const [ProjectModule(id: '', name: 'Fees'), ProjectModule(id: '', name: 'Exams')],
        milestones: [Milestone(id: '', title: 'Fee module beta', dueDate: DateTime.now().add(const Duration(days: 10)))],
      ));
      projectId = p.id;
      final t = await repo.createTask(
        CreateTaskRequest(
          projectId: p.id,
          moduleId: p.modules.first.id,
          milestoneId: p.milestones.first.id,
          title: 'Fee receipt PDF with school logo and a very long title to test wrapping',
          description: 'Generate the receipt after payment and share on WhatsApp.',
          priority: TaskPriority.high,
          assignee: (id: '7', name: 'Kavin Kumar'),
          startDate: DateTime.now(),
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        by: (id: '1', name: 'Team Lead'),
      );
      taskId = t.id;
      await repo.updateStatus(t.id, TaskStatus.inProgress, note: 'Started', byName: 'Kavin Kumar');
      final t2 = await repo.createTask(
        CreateTaskRequest(
          projectId: p.id,
          moduleId: p.modules.last.id,
          title: 'Marks entry grid',
          assignee: (id: '8', name: 'Saran'),
          dueDate: DateTime.now().add(const Duration(days: 3)),
        ),
        by: (id: '1', name: 'Team Lead'),
      );
      await repo.updateStatus(t2.id, TaskStatus.done, byName: 'Team Lead');
      await repo.postAnnouncement(title: 'Release on Friday', body: 'Code freeze at 5 PM.', important: true, byName: 'Team Lead');
    });

    Widget app(Widget home, {required bool admin}) => ProviderScope(
          overrides: [
            teamWorkRepositoryProvider.overrideWithValue(LocalTeamWorkRepository()),
            teamWorkUserProvider.overrideWith((ref) async => admin
                ? (id: '1', name: 'Team Lead', isAdmin: true, isDeveloper: false)
                : (id: '7', name: 'Kavin Kumar', isAdmin: false, isDeveloper: true)),
            teamMembersProvider.overrideWith((ref) async => [(id: '1', name: 'Team Lead'), (id: '7', name: 'Kavin Kumar')]),
            ticketRepositoryProvider.overrideWithValue(LocalTicketRepository()),
            ticketUserProvider.overrideWith((ref) async => (id: '1', name: 'Team Lead', canManage: true)),
          ],
          child: MaterialApp(theme: AppTheme.light, onGenerateRoute: Routes.generateRoutes, home: home),
        );

    for (final size in [const Size(375, 812), const Size(1024, 1366)]) {
      final label = size.width < 600 ? 'phone' : 'iPad';
      testWidgets('admin screens on $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final home in <Widget>[
          const DevDashboardView(),
          const TaskListView(),
          TaskDetailView(taskId: taskId),
          const TaskFormView(),
          ProjectDetailView(projectId: projectId),
          const ProjectListView(),
          ProjectFormView(projectId: projectId),
          const AnnouncementListView(),
          const DevLeaderboardView(),
        ]) {
          await tester.pumpWidget(app(home, admin: true));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '${home.runtimeType} on $label');
        }
        expect(find.byType(DevLeaderboardView), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('developer sees their task with actions', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const DevDashboardView(), admin: false));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('DEVELOPER'), findsOneWidget);
      await tester.pumpWidget(app(TaskDetailView(taskId: taskId), admin: false));
      await tester.pumpAndSettle();
      expect(find.text('Send for review'), findsOneWidget);
      expect(find.text('Reassign'), findsNothing);
      await tester.pumpWidget(app(const TaskListView(), admin: false));
      await tester.pumpAndSettle();
      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.textContaining('Fee receipt PDF'), findsOneWidget);
      expect(find.text('Marks entry grid'), findsNothing); // Saran's task
      await tester.pumpWidget(const SizedBox());
    });
  });
}
