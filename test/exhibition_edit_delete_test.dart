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
final _detail = Exhibition.fromJson({
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
    {'id': 11, 'name': 'Ravi', 'mobile': '9876543210'},
    {'id': 12, 'name': 'Priya', 'mobile': '9876500000'},
  ],
});

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
          attendees: const [Attendee(name: 'Ravi', mobile: '9876543210')],
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
        'attendees': [
          {'name': 'Ravi', 'mobile': '9876543210'},
        ],
      });
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
      expect(body['attendees'], [
        {'name': 'Ravi', 'mobile': '9876543210'},
        {'name': 'Priya', 'mobile': '9876500000'},
      ]);
      expect(popped, isTrue);
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
