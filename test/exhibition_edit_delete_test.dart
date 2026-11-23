import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/core/network/DioClient.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import 'package:sssbuddy/repository/exhibition_repository.dart';
import 'package:sssbuddy/view/exhibition/exhibition_create_view.dart';
import 'package:sssbuddy/view/exhibition/widget/exhibition_common.dart';
import 'package:sssbuddy/view/exhibition/exhibition_detail_view.dart';
import 'package:sssbuddy/viewModel/exhibition_viewmodel.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

/// Records every request and answers with [reply].
class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  final List<dynamic> bodies = [];
  Map<String, dynamic> Function(RequestOptions o) reply = (_) => {
    'status': 'success',
    'data': {'id': 7},
  };
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    calls.add(o);
    bodies.add(o.data);
    return ResponseBody.fromString(
      jsonEncode(reply(o)),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeDioClient implements DioClient {
  final Dio _dio;
  _FakeDioClient(_Adapter a)
    : _dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))..httpClientAdapter = a;
  @override
  Dio get dio => _dio;
  @override
  Future<String?> getToken() async => 'tkn';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// In-memory repository for the screens.
class _FakeRepo implements ExhibitionRepository {
  Exhibition detail;
  Object? detailError;
  int detailCalls = 0;
  final List<(String, CreateExhibitionRequest)> updates = [];
  final List<String> deletes = [];

  _FakeRepo(this.detail);

  @override
  Future<Exhibition> fetchExhibition(String id) async {
    detailCalls++;
    final e = detailError;
    if (e != null) throw e;
    return detail;
  }

  @override
  Future<void> updateExhibition(String id, CreateExhibitionRequest req) async =>
      updates.add((id, req));

  @override
  Future<void> deleteExhibition(String id) async => deletes.add(id);

  @override
  Future<List<Exhibition>> fetchExhibitions({String status = '', String search = ''}) async => [
    detail,
  ];
  @override
  Future<List<ExhibitionDemo>> fetchDemos(String exhibitionId) async => const [];
  @override
  Future<List<ExhibitionLead>> fetchLeads(String exhibitionId) async => const [];
  @override
  Future<List<DemoTemplate>> fetchTemplates(String exhibitionId) async => const [];
  @override
  Future<List<AttendeeOption>> fetchAttendeeOptions() async => const [
    AttendeeOption(id: '18', name: 'Ravi', employeeId: '1502', roleName: 'Sales Manager', phone: '9876543210', hasPhone: true),
    AttendeeOption(id: '24', name: 'Priya', employeeId: '1517', roleName: 'Sales Executive', phone: '9876500000', hasPhone: true),
    AttendeeOption(id: '31', name: 'Karthik S', employeeId: '1600', roleName: 'Sales Executive'),
  ];

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends UserSessionNotifier {
  final UserSession? user;
  _Session(this.user);
  @override
  Future<UserSession?> build() async => user;
}

UserSession _user({String id = '42', String name = 'Venkataravi C R'}) => UserSession(
  employeeName: name,
  employeeId: 'E1',
  employeerole: '',
  schoolUserId: '',
  userId: id,
  token: 'tkn',
);

// The list row (#37 shape): no team, no notes.
final _listRow = Exhibition.fromJson({
  'id': 7,
  'name': 'DIDAC India 2027',
  'venue': 'Bombay Exhibition Centre',
  'city': 'Mumbai',
  'startDate': '2027-09-10',
  'endDate': '2027-09-12',
  'status': 'completed',
  'attendeeCount': 2,
  'demoCount': 12,
  'leadCount': 5,
  'createdByName': 'Venkataravi C R',
  'createdById': 42,
  'createdAt': '2026-11-11T10:00:00.000Z',
});

// The detail (#39 shape): team + notes, no creator / lead count.
final _detail = Exhibition.fromJson(_detailJson);
const _detailJson = <String, dynamic>{
  'id': 7,
  'name': 'DIDAC India 2027',
  'venue': 'Bombay Exhibition Centre',
  'city': 'Mumbai',
  'startDate': '2027-09-10',
  'endDate': '2027-09-12',
  'status': 'completed',
  'demoCount': 12,
  'notes': 'Hall 3, Stall 42',
  'attendees': [
    {'id': 11, 'userId': 18, 'name': 'Ravi', 'mobile': '9876543210', 'linked': true},
    {'id': 12, 'userId': 24, 'name': 'Priya', 'mobile': '9876500000', 'linked': true},
  ],
};

Widget _app(_FakeRepo repo, Widget home, {UserSession? user}) => ProviderScope(
  overrides: [
    exhibitionRepositoryProvider.overrideWithValue(repo),
    userSessionProvider.overrideWith(() => _Session(user)),
  ],
  child: MaterialApp(home: home),
);

Future<void> _phone(WidgetTester t) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  // ── Repository: what goes over the wire ──────────────────────────────

  group('ExhibitionRepository HTTP', () {
    late _Adapter adapter;
    late ExhibitionRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = ExhibitionRepository(_FakeDioClient(adapter));
    });

    test('edit = PUT /exhibitions/:id with bearer and the full body', () async {
      await repo.updateExhibition(
        '7',
        CreateExhibitionRequest(
          name: 'DIDAC India 2027',
          venue: 'BEC',
          city: 'Mumbai',
          startDate: DateTime(2027, 9, 10),
          endDate: DateTime(2027, 9, 12),
          status: ExhibitionStatus.completed,
          notes: 'Hall 3',
          attendees: const [
            Attendee(name: 'Ravi', mobile: '9876543210', userId: '18'),
            // A typed entry (no SCORE user id) is never sent.
            Attendee(name: 'Old', mobile: '9000000000'),
          ],
        ),
      );
      final o = adapter.calls.single;
      expect(o.method, 'PUT');
      expect(o.path, 'api/mobile/exhibitions/7');
      expect(o.headers['Authorization'], 'Bearer tkn');
      expect(adapter.bodies.single, {
        'name': 'DIDAC India 2027',
        'venue': 'BEC',
        'city': 'Mumbai',
        'startDate': '2027-09-10',
        'endDate': '2027-09-12',
        'status': 'completed',
        'notes': 'Hall 3',
        'attendeeUserIds': [18],
      });
    });

    test('attendee options = GET /exhibitions/attendee-options, parsed', () async {
      adapter.reply = (_) => {
        'status': 'success',
        'data': [
          {'id': 18, 'name': 'Murugan N', 'employeeId': '1502', 'roleName': 'Sales Manager', 'phone': '9003769500', 'hasPhone': true},
          {'id': 24, 'name': 'Priya K', 'employeeId': '1517', 'roleName': 'Sales Executive', 'phone': null, 'hasPhone': false},
        ],
      };
      final opts = await repo.fetchAttendeeOptions();
      final o = adapter.calls.single;
      expect(o.method, 'GET');
      expect(o.path, 'api/mobile/exhibitions/attendee-options');
      expect(o.headers['Authorization'], 'Bearer tkn');
      expect(opts.map((e) => e.id), ['18', '24']);
      expect(opts.first.hasPhone, isTrue);
      expect(opts.first.phone, '9003769500');
      expect(opts.last.hasPhone, isFalse);
      expect(opts.last.phone, '');
      final a = opts.first.toAttendee();
      expect((a.userId, a.name, a.isLinked), ('18', 'Murugan N', true));
    });

    test('delete = DELETE /exhibitions/:id with bearer', () async {
      await repo.deleteExhibition('7');
      final o = adapter.calls.single;
      expect(o.method, 'DELETE');
      expect(o.path, 'api/mobile/exhibitions/7');
      expect(o.headers['Authorization'], 'Bearer tkn');
    });

    test('status:error body on edit / delete surfaces the backend message', () async {
      adapter.reply = (_) => {'status': 'error', 'message': 'Exhibition not found'};
      await expectLater(
        repo.deleteExhibition('99'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Exhibition not found')),
      );
      await expectLater(
        repo.updateExhibition('99', const CreateExhibitionRequest(name: 'X')),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Exhibition not found')),
      );
    });

    test('detail GET parses team + notes', () async {
      adapter.reply = (_) => {
        'status': 'success',
        'data': {
          'id': 7,
          'name': 'DIDAC',
          'notes': 'Hall 3',
          'attendees': [
            {'id': 11, 'name': 'Ravi', 'mobile': '9876543210'},
          ],
        },
      };
      final ex = await repo.fetchExhibition('7');
      expect(adapter.calls.single.path, 'api/mobile/exhibitions/7');
      expect(ex.notes, 'Hall 3');
      expect(ex.attendees.single.mobile, '9876543210');
    });
  });

  // ── Edit form: prefill and save ──────────────────────────────────────

  group('Create exhibition dates', () {
    Future<DatePickerDialog> openStartPicker(WidgetTester t, Widget form) async {
      await _phone(t);
      await t.pumpWidget(_app(_FakeRepo(_detail), form));
      await t.pumpAndSettle();
      final row = find.ancestor(of: find.text('DATES'), matching: find.byType(ExSummaryRow));
      if (row.evaluate().isNotEmpty) {
        await t.ensureVisible(row);
        await t.tap(row);
      } else {
        await t.enterText(find.byType(TextField).first, 'Expo');
        await t.tap(find.text('Next'));
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).first, 'Hall');
        await t.tap(find.text('Next'));
      }
      await t.pumpAndSettle();
      await t.tap(find.text('STARTS'));
      await t.pumpAndSettle();
      return t.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    }

    testWidgets('new exhibition: the start picker starts at today', (t) async {
      final d = await openStartPicker(t, const ExhibitionCreateView());
      final n = DateTime.now();
      expect(d.firstDate, DateTime(n.year, n.month, n.day));
    });

    testWidgets('edit: the start picker also starts at today', (t) async {
      final d = await openStartPicker(t, ExhibitionCreateView(initial: _listRow));
      final n = DateTime.now();
      expect(d.firstDate, DateTime(n.year, n.month, n.day));
    });

    testWidgets('edit: an exhibition that already started saves with its date unchanged', (t) async {
      await _phone(t);
      final past = Exhibition.fromJson({
        ..._detailJson,
        'startDate': '2024-01-10',
        'endDate': '2024-01-12',
      });
      final repo = _FakeRepo(past);
      await t.pumpWidget(_app(repo, ExhibitionCreateView(initial: past)));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Update Exhibition'));
      await t.tap(find.text('Update Exhibition'));
      await t.pumpAndSettle();
      expect(repo.updates.single.$2.toJson()['startDate'], '2024-01-10');
    });
  });

  group('Edit exhibition form', () {
    testWidgets('opens with every field from detail + list row', (t) async {
      await _phone(t);
      final repo = _FakeRepo(_detail);
      await t.pumpWidget(_app(repo, ExhibitionCreateView(initial: _listRow)));
      await t.pumpAndSettle();

      expect(repo.detailCalls, 1, reason: 'edit must fetch the full exhibition');
      expect(find.text('Edit exhibition'), findsOneWidget);
      for (final v in [
        'DIDAC India 2027',
        'Bombay Exhibition Centre',
        'Mumbai',
        'Hall 3, Stall 42',
      ]) {
        // Edit opens on the summary step, which shows every value.
        expect(find.textContaining(v), findsWidgets, reason: '"$v" not prefilled');
      }
      // Attendee chips (names and numbers).
      expect(find.textContaining('Ravi'), findsWidgets);
      expect(find.textContaining('Priya'), findsWidgets);
      // Dates show (10 Sep / 12 Sep 2027 in whatever format the field uses).
      expect(find.textContaining('2027'), findsWidgets);
    });

    testWidgets('Update Exhibition sends the same data back and keeps the status', (t) async {
      await _phone(t);
      final repo = _FakeRepo(_detail);
      bool? popped;
      await t.pumpWidget(
        _app(
          repo,
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    popped = await Navigator.push<bool>(
                      ctx,
                      MaterialPageRoute(builder: (_) => ExhibitionCreateView(initial: _listRow)),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Update Exhibition'));
      await t.tap(find.text('Update Exhibition'));
      await t.pumpAndSettle();

      expect(repo.updates, hasLength(1));
      final (id, req) = repo.updates.single;
      expect(id, '7');
      final body = req.toJson();
      expect(body['name'], 'DIDAC India 2027');
      expect(body['venue'], 'Bombay Exhibition Centre');
      expect(body['city'], 'Mumbai');
      expect(body['startDate'], '2027-09-10');
      expect(body['endDate'], '2027-09-12');
      expect(body['notes'], 'Hall 3, Stall 42');
      expect(body['status'], 'completed', reason: 'edit must not reset status to active');
      expect(body['attendeeUserIds'], [18, 24]);
      expect(body.containsKey('attendees'), isFalse, reason: 'typed attendees are rejected by the API');
      expect(popped, isTrue);
    });

    testWidgets('team step picks SCORE users (no typed fields) and sends their ids', (t) async {
      await _phone(t);
      final repo = _FakeRepo(_detail);
      await t.pumpWidget(_app(repo, ExhibitionCreateView(initial: _listRow)));
      await t.pumpAndSettle();
      final row = find.ancestor(of: find.text('ATTENDEES'), matching: find.byType(ExSummaryRow));
      await t.ensureVisible(row);
      await t.tap(row);
      await t.pumpAndSettle();

      expect(find.text('10-digit mobile'), findsNothing, reason: 'attendees are never typed');
      expect(find.text('Karthik S'), findsOneWidget);
      expect(find.textContaining("won't be called"), findsOneWidget);
      await t.enterText(find.byType(TextField).first, 'karth');
      await t.pumpAndSettle();
      expect(find.text('Priya'), findsOneWidget, reason: 'picked chip stays; option is filtered out');
      await t.tap(find.text('Karthik S'));
      await t.pumpAndSettle();
      expect(find.textContaining('On the team · 3'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('detail fails → error + Retry, no Save button; Retry loads', (t) async {
      await _phone(t);
      final repo = _FakeRepo(_detail)..detailError = ApiException('Server down');
      await t.pumpWidget(_app(repo, ExhibitionCreateView(initial: _listRow)));
      await t.pumpAndSettle();
      expect(find.text("Couldn't load exhibition"), findsOneWidget);
      expect(find.text('Update Exhibition'), findsNothing);

      repo.detailError = null;
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.text('Update Exhibition'), findsOneWidget);
      expect(find.textContaining('Hall 3, Stall 42'), findsWidgets);
    });
  });

  // ── Detail screen: Edit / Delete buttons ─────────────────────────────

  group('Exhibition detail Edit / Delete', () {
    // Hidden in the app for now; switched on here to keep the flow covered.
    setUp(() => exhibitionDeleteEnabled = true);
    tearDown(() => exhibitionDeleteEnabled = false);

    Future<_FakeRepo> open(WidgetTester t, {UserSession? user}) async {
      await _phone(t);
      final repo = _FakeRepo(_detail);
      await t.pumpWidget(
        _app(
          repo,
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => ExhibitionDetailView(exhibitionId: '7', initial: _listRow),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          user: user,
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      return repo;
    }

    testWidgets('creator sees Edit and Delete even when detail omits the creator', (t) async {
      await open(t, user: _user());
      expect(find.byTooltip('Edit exhibition'), findsOneWidget);
      expect(find.byTooltip('Delete exhibition'), findsOneWidget);
    });

    testWidgets('Delete hidden for now: the creator sees Edit only', (t) async {
      exhibitionDeleteEnabled = false;
      await open(t, user: _user());
      expect(find.byTooltip('Edit exhibition'), findsOneWidget);
      expect(find.byTooltip('Delete exhibition'), findsNothing);
    });

    testWidgets('someone else sees neither', (t) async {
      await open(
        t,
        user: _user(id: '99', name: 'Other Person'),
      );
      expect(find.byTooltip('Edit exhibition'), findsNothing);
      expect(find.byTooltip('Delete exhibition'), findsNothing);
    });

    testWidgets('Delete → Cancel does nothing', (t) async {
      final repo = await open(t, user: _user());
      await t.tap(find.byTooltip('Delete exhibition'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(repo.deletes, isEmpty);
      expect(find.byType(ExhibitionDetailView), findsOneWidget);
    });

    testWidgets('Delete → confirm calls the API and closes the page', (t) async {
      final repo = await open(t, user: _user());
      await t.tap(find.byTooltip('Delete exhibition'));
      await t.pumpAndSettle();
      await t.tap(find.text('Delete').last);
      await t.pumpAndSettle();
      expect(repo.deletes, ['7']);
      expect(find.byType(ExhibitionDetailView), findsNothing);
    });

    testWidgets('Edit button opens the form with the full data', (t) async {
      final repo = await open(t, user: _user());
      await t.tap(find.byTooltip('Edit exhibition'));
      await t.pumpAndSettle();
      expect(find.text('Edit exhibition'), findsOneWidget);
      expect(find.textContaining('Hall 3, Stall 42'), findsWidgets);
      expect(find.textContaining('Priya'), findsWidgets);
      expect(repo.detailCalls, greaterThanOrEqualTo(2));
    });
  });
}
