import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/FinancialYearModel.dart';
import 'package:sssbuddy/auth/model/PaymentSubmissionModel.dart';
import 'package:sssbuddy/core/network/DioClient.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import 'package:sssbuddy/repository/payment_submission_repository.dart';
import 'package:sssbuddy/view/payment_submission/payment_submission_detail_view.dart';
import 'package:sssbuddy/view/payment_submission/payment_submissions_view.dart';
import 'package:sssbuddy/view/payment_submission/payment_submit_view.dart';
import 'package:sssbuddy/viewModel/payment_submission_viewmodel.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _Adapter implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  Map<String, dynamic> Function(RequestOptions o) reply = (_) => {'status': 'success', 'data': []};
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? __) async {
    calls.add(o);
    return ResponseBody.fromString(jsonEncode(reply(o)), statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FakeDioClient implements DioClient {
  final Dio _dio;
  _FakeDioClient(_Adapter a) : _dio = Dio(BaseOptions(baseUrl: 'https://api.test/'))..httpClientAdapter = a;
  @override
  Dio get dio => _dio;
  @override
  Future<String?> getToken() async => 'tkn';
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

final _pendingJson = {
  'id': 501,
  'customerId': 499,
  'customerName': 'Akila Bharathi Matriculation School, Poyyur',
  'invoiceId': 17188,
  'invoiceNumber': 'PRO/25661/E/10/26-27',
  'invoiceStatus': 'pending',
  'amount': '20650.00',
  'paymentDate': '2026-11-20',
  'paymentMethod': 'upi',
  'referenceNumber': '632412345678',
  'payerBank': 'State Bank of India',
  'status': 'pending',
  'bankTxn': null,
  'submittedAt': '2026-11-24T05:11:00.000Z',
  'submittedBy': 42,
  'submittedByName': 'Venkataravi C R',
  'source': 'app',
  'supportingDocs': [
    {'url': 'https://s3.test/PROOF_1.jpg'},
  ],
};

class _FakeRepo implements PaymentSubmissionRepository {
  List<PaymentSubmission> rows = [PaymentSubmission.fromJson(_pendingJson)];
  final List<String> statuses = [];
  final List<String> searches = [];
  final List<int> withdrawn = [];

  @override
  Future<PsPage> fetchSubmissions({
    String status = '',
    bool mine = true,
    int page = 1,
    int limit = 25,
    String search = '',
  }) async {
    statuses.add(status);
    searches.add(search);
    return PsPage(
      items: rows
          .where((r) => status.isEmpty || r.status == status)
          .where((r) => search.isEmpty || r.customerName.toLowerCase().contains(search.toLowerCase()))
          .toList(),
      page: 1,
      totalPages: 1,
    );
  }

  final List<String> schoolSearches = [];

  @override
  Future<List<PsCustomer>> fetchCustomers({String search = ''}) async {
    schoolSearches.add(search);
    return _customers.where((c) => search.isEmpty || c.companyName.toLowerCase().contains(search.toLowerCase())).toList();
  }

  static const _customers = [
    PsCustomer(id: 499, companyName: 'Akila Bharathi Matriculation School', dashboardId: '2662', proformaCount: 1, pendingTotal: 20650),
  ];

  @override
  Future<List<PsProforma>> fetchProformas(int customerId) async => const [
        PsProforma(id: 17188, invoiceNumber: 'PRO/25661/E/10/26-27', total: 20650, claimable: 10650, submittedPending: 10000),
      ];

  @override
  Future<List<Paymentmodemodel>> fetchPaymentModes() async => [Paymentmodemodel(value: 'upi', label: 'UPI')];

  @override
  Future<PaymentSubmission> fetchSubmission(int id) async => rows.firstWhere((r) => r.id == id);

  @override
  Future<void> withdraw(int id) async {
    withdrawn.add(id);
    rows = [PaymentSubmission.fromJson({..._pendingJson, 'status': 'withdrawn'})];
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends UserSessionNotifier {
  final String userId;
  _Session(this.userId);
  @override
  Future<UserSession?> build() async => UserSession(
        employeeName: 'Venkataravi C R',
        employeeId: 'E1',
        employeerole: '',
        schoolUserId: '',
        userId: userId,
        token: 'tkn',
      );
}

Widget _app(_FakeRepo repo, Widget home, {String userId = '42'}) => ProviderScope(
      overrides: [
        paymentSubmissionRepositoryProvider.overrideWithValue(repo),
        userSessionProvider.overrideWith(() => _Session(userId)),
      ],
      child: MaterialApp(home: home),
    );

Future<void> _phone(WidgetTester t) async {
  t.view.physicalSize = const Size(1170, 2532);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

void main() {
  group('Model', () {
    test('status chip follows status + bankTxn', () {
      SubmissionStage stage(Map<String, dynamic> extra) =>
          PaymentSubmission.fromJson({..._pendingJson, ...extra}).stage;
      expect(stage({}), SubmissionStage.awaitingBank);
      expect(stage({'bankTxn': {'status': 'suggested', 'amount': '20650.00', 'valueDate': '2026-11-21'}}),
          SubmissionStage.foundInBank);
      expect(stage({'status': 'done'}), SubmissionStage.receipted);
      expect(stage({'status': 'rejected'}), SubmissionStage.rejected);
      expect(stage({'status': 'withdrawn'}), SubmissionStage.withdrawn);
    });

    test('amounts are parsed from strings; ₹ uses Indian grouping', () {
      final s = PaymentSubmission.fromJson(_pendingJson);
      expect(s.amount, 20650);
      expect(formatRupees(1917500), '₹19,17,500');
      expect(formatRupees(19175.5), '₹19,175.50');
      expect(parseAmount('19175.00'), 19175);
      expect(parseAmount(null), 0);
      expect(s.supportingDocs, ['https://s3.test/PROOF_1.jpg']);
    });

    test('withdraw only for the submitter while pending', () {
      final s = PaymentSubmission.fromJson(_pendingJson);
      expect(s.canWithdraw('42'), isTrue);
      expect(s.canWithdraw('7'), isFalse);
      expect(PaymentSubmission.fromJson({..._pendingJson, 'status': 'done'}).canWithdraw('42'), isFalse);
    });

    test('proforma, customer and AI read parse the documented shapes', () {
      final p = PsProforma.fromJson({
        'id': 17020,
        'invoiceNumber': 'PRO/25390/E/08/26-27',
        'invoiceDate': '2026-08-01',
        'periodStart': '2026-06-01',
        'periodEnd': '2026-08-31',
        'total': '20650',
        'pendingAmount': '20650.00',
        'submittedPending': '10000.00',
        'claimable': 10650,
      });
      expect(p.claimable, 10650);
      expect(p.submittedPending, 10000);
      expect(p.period, 'Jun–Aug 2026');

      final c = PsCustomer.fromJson({
        'id': 2484,
        'companyName': 'AKD Matriculation School',
        'dashboardId': '6494',
        'proformaCount': 1,
        'pendingTotal': '19175.00',
      });
      expect((c.id, c.pendingTotal, c.dashboardId), (2484, 19175.0, '6494'));

      final r = PsExtraction.fromJson({
        'id': 41,
        'status': 'ok',
        'paymentMode': 'cash_deposit',
        'txnRef': '632412345678',
        'txnDate': '2026-11-20',
        'amount': 20650,
        'confidence': 0.95,
        'warnings': ['Paid to account …7739, which is not one of our bank accounts.'],
        'proofUrl': 'https://s3.test/PROOF_1.jpg',
      });
      expect(r.isOk, isTrue);
      expect(r.formMode, 'cash');
      expect(r.txnDate, DateTime(2026, 11, 20));
      expect(r.warnings, hasLength(1));
    });

    test('submit body matches the API', () {
      final body = SubmitPaymentRequest(
        customerId: 499,
        invoiceId: 17188,
        amount: 20650,
        paymentDate: DateTime(2026, 11, 20),
        paymentMethod: 'upi',
        referenceNumber: '632412345678',
        payerBank: 'State Bank of India',
        proofUrls: const ['https://s3.test/PROOF_1.jpg'],
        extractionId: 41,
      ).toJson();
      expect(body, {
        'customerId': 499,
        'invoiceId': 17188,
        'amount': 20650,
        'paymentDate': '2026-11-20',
        'paymentMethod': 'upi',
        'referenceNumber': '632412345678',
        'payerBank': 'State Bank of India',
        'notes': '',
        'proofUrls': ['https://s3.test/PROOF_1.jpg'],
        'extractionId': 41,
      });
    });
  });

  group('Repository HTTP', () {
    late _Adapter adapter;
    late PaymentSubmissionRepository repo;
    setUp(() {
      adapter = _Adapter();
      repo = PaymentSubmissionRepository(_FakeDioClient(adapter));
    });

    test('list = GET /payment-submissions with filters, bearer and paging', () async {
      adapter.reply = (_) => {
            'status': 'success',
            'data': [_pendingJson],
            'pagination': {'page': 1, 'totalPages': 3},
          };
      final page = await repo.fetchSubmissions(status: 'pending', mine: false);
      final o = adapter.calls.single;
      expect(o.method, 'GET');
      expect(o.path, 'api/mobile/payment-submissions');
      expect(o.headers['Authorization'], 'Bearer tkn');
      expect(o.queryParameters, {'status': 'pending', 'mine': false, 'page': 1, 'limit': 25});

      await repo.fetchSubmissions(search: 'PRO/25661');
      expect(adapter.calls.last.queryParameters['search'], 'PRO/25661');
      expect(page.items.single.id, 501);
      expect(page.totalPages, 3);
    });

    test('403 on the probe hides the feature; other errors do not', () async {
      adapter
        ..statusCode = 403
        ..reply = (_) => {'status': 'error', 'message': 'Forbidden'};
      expect(await repo.hasAccess(), isFalse);
      adapter.statusCode = 500;
      expect(await repo.hasAccess(), isTrue);
      adapter.statusCode = 200;
      adapter.reply = (_) => {'status': 'success', 'data': []};
      expect(await repo.hasAccess(), isTrue);
      expect(adapter.calls.last.queryParameters['limit'], 1);
    });

    test('customers, proformas, detail and withdraw paths', () async {
      adapter.reply = (o) => o.path.endsWith('/501')
          ? {'status': 'success', 'data': _pendingJson}
          : {'status': 'success', 'data': []};
      await repo.fetchCustomers(search: 'matric');
      await repo.fetchProformas(499);
      final d = await repo.fetchSubmission(501);
      await repo.withdraw(501);
      expect(adapter.calls.map((c) => '${c.method} ${c.uri.path}${c.uri.query.isEmpty ? '' : '?${c.uri.query}'}'), [
        'GET /api/mobile/payment-submissions/customers?search=matric',
        'GET /api/mobile/payment-submissions/customers/499/proformas',
        'GET /api/mobile/payment-submissions/501',
        'POST /api/mobile/payment-submissions/501/withdraw',
      ]);
      expect(d.customerName, startsWith('Akila'));
      expect(adapter.calls.every((c) => c.headers['Authorization'] == 'Bearer tkn'), isTrue);
    });

    test('every call carries the login token (extract, modes, submit too)', () async {
      final dir = Directory.systemTemp.createTempSync('ps_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final proof = File('${dir.path}/proof.jpg')..writeAsBytesSync([1, 2, 3]);
      adapter.reply = (_) => {'status': 'success', 'data': {'id': 41, 'status': 'ok', 'proofUrl': 'https://s3.test/p.jpg'}};
      final read = await repo.extractProof(proof.path);
      final extract = adapter.calls.last;
      expect('${extract.method} ${extract.path}', 'POST api/mobile/payment-submissions/extract');
      expect(extract.data, isA<FormData>());
      expect((extract.data as FormData).files.single.key, 'proof');
      expect(read.proofUrl, 'https://s3.test/p.jpg');

      adapter.reply = (_) => {'status': 'success', 'data': [{'value': 'upi', 'label': 'UPI'}]};
      await repo.fetchPaymentModes();
      adapter.reply = (_) => {'status': 'success', 'data': _pendingJson};
      await repo.submit(SubmitPaymentRequest(customerId: 1, invoiceId: 2, amount: 1, paymentDate: DateTime(2026)));
      await repo.fetchSubmissions();
      await repo.fetchCustomers();
      await repo.fetchProformas(1);
      await repo.fetchSubmission(501);
      await repo.withdraw(501);

      expect(adapter.calls, hasLength(8));
      for (final c in adapter.calls) {
        expect(c.headers['Authorization'], 'Bearer tkn', reason: '${c.method} ${c.path}');
      }
    });

    test('submit = POST JSON; 409 surfaces the message', () async {
      adapter.reply = (_) => {'status': 'success', 'message': 'Payment submitted', 'data': _pendingJson};
      final (created, message) = await repo.submit(SubmitPaymentRequest(
        customerId: 499,
        invoiceId: 17188,
        amount: 100,
        paymentDate: DateTime(2026, 11, 20),
      ));
      expect(adapter.calls.single.method, 'POST');
      expect(adapter.calls.single.path, 'api/mobile/payment-submissions');
      expect((created.id, message), (501, 'Payment submitted'));

      adapter
        ..statusCode = 409
        ..reply = (_) => {'status': 'error', 'message': 'Reference already submitted'};
      await expectLater(
        repo.submit(SubmitPaymentRequest(customerId: 1, invoiceId: 2, amount: 1, paymentDate: DateTime(2026))),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });
  });

  group('Screens', () {
    testWidgets('list shows the card and filters by tab', (t) async {
      await _phone(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_app(repo, const PaymentSubmissionsView()));
      await t.pumpAndSettle();
      expect(find.text('Akila Bharathi Matriculation School, Poyyur'), findsOneWidget);
      expect(find.text('₹20,650'), findsOneWidget);
      expect(find.text('AWAITING BANK'), findsOneWidget);

      await t.tap(find.text('Receipted'));
      await t.pumpAndSettle();
      expect(repo.statuses.last, 'done');
      expect(find.text('No receipted submissions.'), findsOneWidget);
    });

    testWidgets('search box sends search to the API and can be cleared', (t) async {
      await _phone(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_app(repo, const PaymentSubmissionsView()));
      await t.pumpAndSettle();

      // Hidden until the header's search icon is tapped.
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.byTooltip('Search'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      final calls = repo.searches.length;
      await t.enterText(find.byType(TextField), 'kairali');
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(repo.searches.length, calls, reason: 'typing alone must not call the API');
      await t.tap(find.widgetWithText(FilledButton, 'Search'));
      await t.pumpAndSettle();
      expect(repo.searches.length, calls + 1);
      expect(repo.searches.last, 'kairali');
      expect(find.text('No match'), findsOneWidget);

      await t.tap(find.text('Clear search'));
      await t.pumpAndSettle();
      expect(repo.searches.last, '');
      expect(find.text('Akila Bharathi Matriculation School, Poyyur'), findsOneWidget);

      // Keyboard Search also runs it.
      await t.enterText(find.byType(TextField), 'akila');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(repo.searches.last, 'akila');
      expect(find.text('Akila Bharathi Matriculation School, Poyyur'), findsOneWidget);

      // Closing hides the box and drops the search.
      await t.tap(find.byTooltip('Close search'));
      await t.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(repo.searches.last, '');
    });

    testWidgets('submit flow: school → proforma (pre-selected) → proof', (t) async {
      await _phone(t);
      await t.pumpWidget(_app(_FakeRepo(), const PaymentSubmitView()));
      await t.pumpAndSettle();
      expect(find.text('Step 1 of 4 · School'), findsOneWidget);
      await t.tap(find.text('Akila Bharathi Matriculation School'));
      await t.pumpAndSettle();
      expect(find.text('Step 2 of 4 · Proforma'), findsOneWidget);
      expect(find.text('− ₹10,000'), findsOneWidget);
      expect(find.text('₹10,650'), findsOneWidget);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.text('Step 3 of 4 · Proof'), findsOneWidget);
      expect(find.text('Take photo'), findsOneWidget);
      expect(find.text('Choose file'), findsOneWidget);
    });

    testWidgets('school picker searches only when Search is tapped', (t) async {
      await _phone(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_app(repo, const PaymentSubmitView()));
      await t.pumpAndSettle();
      expect(repo.schoolSearches, ['']);

      await t.enterText(find.byType(TextField), 'kairali');
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(repo.schoolSearches, [''], reason: 'typing alone must not call the API');

      await t.tap(find.widgetWithText(FilledButton, 'Search'));
      await t.pumpAndSettle();
      expect(repo.schoolSearches.last, 'kairali');
      expect(find.text('No school found'), findsOneWidget);

      await t.tap(find.byTooltip('Clear search'));
      await t.pumpAndSettle();
      expect(find.text('Akila Bharathi Matriculation School'), findsOneWidget);
    });

    testWidgets('detail: submitter can withdraw a pending submission', (t) async {
      await _phone(t);
      final repo = _FakeRepo();
      await t.pumpWidget(_app(repo, const PaymentSubmissionDetailView(id: 501)));
      await t.pumpAndSettle();
      expect(find.text('Waiting for the credit to appear in an uploaded statement'), findsOneWidget);
      await t.tap(find.text('Withdraw submission'));
      await t.pumpAndSettle();
      await t.tap(find.text('Withdraw'));
      await t.pumpAndSettle();
      expect(repo.withdrawn, [501]);
      expect(find.text('WITHDRAWN'), findsOneWidget);
      expect(find.text('Withdraw submission'), findsNothing);
    });

    testWidgets('detail: someone else sees no Withdraw', (t) async {
      await _phone(t);
      await t.pumpWidget(_app(_FakeRepo(), const PaymentSubmissionDetailView(id: 501), userId: '7'));
      await t.pumpAndSettle();
      expect(find.text('Withdraw submission'), findsNothing);
    });
  });
}
