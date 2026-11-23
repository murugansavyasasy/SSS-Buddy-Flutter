import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import 'package:sssbuddy/repository/exhibition_repository.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/view/exhibition/exhibition_create_view.dart';
import 'package:sssbuddy/view/exhibition/exhibition_detail_view.dart';
import 'package:sssbuddy/view/exhibition/exhibition_list_view.dart';
import 'package:sssbuddy/view/exhibition/showcase/school_chimes_showcase.dart';
import 'package:sssbuddy/view/exhibition/give_demo_view.dart';
import 'package:sssbuddy/view/exhibition/widget/exhibition_common.dart';
import 'package:sssbuddy/view/exhibition/widget/exhibition_sheets.dart';
import 'package:sssbuddy/viewModel/exhibition_viewmodel.dart';

/// Every Exhibitions screen renders without overflow / errors at phone and
/// iPad sizes. `--dart-define=SHOTS=true --update-goldens` saves
/// screenshots to test/shots/ for a visual check.
class _Repo implements ExhibitionRepository {
  @override
  Future<Exhibition> fetchExhibition(String id) async => _exs.firstWhere((e) => e.id == id);
  @override
  Future<List<Exhibition>> fetchExhibitions({String status = '', String search = ''}) async => _exs;
  @override
  Future<List<ExhibitionDemo>> fetchDemos(String exhibitionId) async => _demos;
  @override
  Future<List<ExhibitionLead>> fetchLeads(String exhibitionId) async => _leads;
  @override
  Future<List<DemoTemplate>> fetchTemplates(String exhibitionId) async => const [];
  @override
  Future<ExhibitionDemo> fetchDemo(String demoId) async =>
      _demos.firstWhere((d) => d.id == demoId, orElse: () => _demos.first);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends UserSessionNotifier {
  @override
  Future<UserSession?> build() async => UserSession(
        employeeName: 'Venkataravi C R',
        employeeId: 'E1',
        employeerole: 'Admin',
        schoolUserId: '1',
        userId: '1',
        token: 't',
      );
}

final _exs = [
  Exhibition.fromJson({
    'id': 7,
    'name': 'DIDAC India 2027 — International Education Expo',
    'venue': 'Bombay Exhibition Centre, Goregaon East',
    'city': 'Mumbai',
    'startDate': '2027-09-10',
    'endDate': '2027-09-12',
    'status': 'active',
    'attendeeCount': 4,
    'demoCount': 12,
    'leadCount': 5,
    'createdBy': 1,
    'createdByName': 'Venkataravi C R',
    'notes': 'Hall 3, Stall 42',
    'attendees': [
      {'name': 'Ravi', 'mobile': '9876543210'},
      {'name': 'Priya Raman', 'mobile': '9876500000'},
    ],
  }),
  Exhibition.fromJson({
    'id': 8,
    'name': 'School Leaders Summit',
    'venue': 'Chennai Trade Centre',
    'city': 'Chennai',
    'startDate': '2026-10-01',
    'endDate': '2026-10-02',
    'status': 'completed',
    'attendeeCount': 2,
    'demoCount': 30,
    'leadCount': 11,
  }),
];

final _demos = [
  ExhibitionDemo.fromJson({
    'id': 1,
    'visitorName': 'Mrs. Lakshmi Narayanan from Sri Venkateswara Matriculation',
    'recipientCount': 3,
    'status': 'completed',
    'createdByName': 'Venkataravi C R',
    'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    'hasLead': true,
    'recipients': [
      {'id': 1, 'mobile': '9811112222', 'recipientType': 'visitor', 'recipientName': 'Mrs. Lakshmi', 'callStatus': 'answered'},
      {'id': 2, 'mobile': '9876543210', 'recipientType': 'team', 'recipientName': 'Ravi', 'callStatus': 'failed'},
    ],
  }),
  ExhibitionDemo.fromJson({'id': 2, 'visitorName': '', 'recipientCount': 1, 'status': 'queued'}),
  // A few days of activity for the Insights charts.
  for (var k = 0; k < 14; k++)
    ExhibitionDemo.fromJson({
      'id': 10 + k,
      'visitorName': 'Visitor $k',
      'recipientCount': 2,
      'status': ['completed', 'answered', 'failed', 'completed', 'queued'][k % 5],
      'createdAt': DateTime.now()
          .subtract(Duration(days: k % 4, hours: k % 3))
          .toIso8601String(),
    }),
];

final _leads = [
  ExhibitionLead.fromJson({
    'id': 1,
    'schoolName': 'Sri Venkateswara Matriculation Higher Secondary School',
    'city': 'Kanchipuram',
    'contactName': 'Mrs. Lakshmi Narayanan',
    'contactNumber': '9876543210',
    'contactEmail': 'principal.svmhss.kanchipuram@example.com',
    'notes': 'Wants a follow-up demo for the management next week.',
    'interestLevel': 'Excellent',
    'createdByName': 'Venkataravi C R',
    'createdBy': 1,
    'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
  }),
  ExhibitionLead.fromJson({'id': 2, 'schoolName': 'ABC School', 'interestLevel': 'Good'}),
  for (var k = 0; k < 5; k++)
    ExhibitionLead.fromJson({
      'id': 20 + k,
      'schoolName': 'School $k',
      'interestLevel': ['Excellent', 'Good', 'Average', 'Good', ''][k],
      'createdAt': DateTime.now().subtract(Duration(days: k % 4)).toIso8601String(),
    }),
];

Future<void> _loadFonts() async {
  final loader = FontLoader('DMSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(
        File('assets/Fonts/DMSans/DMSans-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Widget _app(Widget home) => ProviderScope(
      overrides: [
        exhibitionRepositoryProvider.overrideWithValue(_Repo()),
        userSessionProvider.overrideWith(() => _Session()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

const _shots = bool.fromEnvironment('SHOTS');
Future<void> _shot(WidgetTester t, String name) async {
  if (_shots) await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
}

void _size(WidgetTester t, Size s) {
  t.view.physicalSize = s * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
}

/// Pumps through entrance animations and fails on any layout error.
Future<void> _settle(WidgetTester t) async {
  // Several frames: animations that start once data arrives need frames
  // to run (one 2 s jump would leave them at their first frame).
  await t.pump();
  for (var k = 0; k < 8; k++) {
    await t.pump(const Duration(milliseconds: 250));
  }
  expect(t.takeException(), isNull);
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('list cards stagger in once, not again after a rebuild', (t) async {
    _size(t, const Size(390, 844));
    ExAppear.resetPlayed();
    await t.pumpWidget(_app(const ExhibitionListView()));
    await t.pump();
    var at = 0;
    for (final ms in [60, 180, 300, 600]) {
      await t.pump(Duration(milliseconds: ms - at));
      at = ms;
      await _shot(t, 'ex_list_anim_$ms');
    }
    await _settle(t);
    // Second card is fully shown; a rebuild must not hide it again.
    final second = find.text('School Leaders Summit');
    double opacityOf(Finder f) => t
        .widgetList<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)))
        .fold(1.0, (v, o) => v * o.opacity);
    expect(opacityOf(second), 1.0);
    await t.pumpWidget(_app(const ExhibitionListView()));
    await t.pump(const Duration(milliseconds: 50));
    expect(opacityOf(second), 1.0);
  });

  testWidgets('"Give demo" pill opens the School Chimes showcase, not Give Demo', (t) async {
    _size(t, const Size(390, 1600));
    await t.pumpWidget(_app(ExhibitionDetailView(exhibitionId: '7', initial: _exs.first)));
    await _settle(t);
    await t.scrollUntilVisible(find.text('Give demo'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Give demo'));
    await _settle(t);
    expect(find.byType(SchoolChimesShowcase), findsOneWidget);
    expect(find.byType(GiveDemoView), findsNothing);
    await t.pumpWidget(const SizedBox()); // stop the slideshow timer
  });

  testWidgets('"Give first demo" opens the School Chimes showcase', (t) async {
    _size(t, const Size(390, 1600));
    await t.pumpWidget(ProviderScope(
      overrides: [
        exhibitionRepositoryProvider.overrideWithValue(_Repo()),
        userSessionProvider.overrideWith(() => _Session()),
        exhibitionDemosProvider.overrideWith((ref, id) async => const <ExhibitionDemo>[]),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: ExhibitionDetailView(exhibitionId: '7', initial: _exs.first),
      ),
    ));
    await _settle(t);
    await t.scrollUntilVisible(find.text('Give first demo'), 300, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Give first demo'));
    await _settle(t);
    expect(find.byType(SchoolChimesShowcase), findsOneWidget);
    await t.pumpWidget(const SizedBox()); // stop the slideshow timer
  });

  for (final (name, size) in [('320', const Size(320, 640)), ('390', const Size(390, 844)), ('ipad', const Size(1024, 1366))]) {
    testWidgets('School Chimes showcase · every slide fits · $name', (t) async {
      _size(t, size);
      var demo = 0, lead = 0;
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: SchoolChimesShowcase(onGiveDemo: () => demo++, onCaptureLead: () => lead++),
      ));
      await _settle(t);
      expect(find.byTooltip('Pause slideshow'), findsOneWidget); // auto-play on
      for (var k = 0; k < 5; k++) {
        await _shot(t, 'showcase_${name}_$k');
        await t.drag(find.byType(PageView), Offset(-size.width * 0.8, 0));
        await _settle(t);
      }
      // Swiping by hand turned auto-play off.
      expect(find.byTooltip('Play slideshow'), findsOneWidget);
      await t.tap(find.text("I'm interested").last);
      await t.tap(find.text('Hear a voice demo').last);
      expect((demo, lead), (1, 1));
      await t.pumpWidget(const SizedBox()); // stop the slideshow timer
    });
  }

  testWidgets('list overview · phone shows a strip, tap opens the charts', (t) async {
    _size(t, const Size(390, 844));
    await t.pumpWidget(_app(const ExhibitionListView()));
    await _settle(t);
    expect(find.text('Charts'), findsOneWidget);
    expect(find.text('Trend'), findsNothing);
    await _shot(t, 'ex_list_phone_strip');
    await t.tap(find.text('Charts'));
    await _settle(t);
    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    await _shot(t, 'ex_list_phone_sheet');
  });

  testWidgets('list overview · iPad full view', (t) async {
    _size(t, const Size(1024, 900));
    SharedPreferences.setMockInitialValues({'exhibition_ipad_split_view': false});
    await t.pumpWidget(_app(const ExhibitionListView()));
    await _settle(t);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Trend'), findsOneWidget);
    await _shot(t, 'ex_list_ipad_full');
    // Every overview chart renders without layout errors.
    for (final tab in ['Top shows', 'Lead interest']) {
      await t.tap(find.text(tab));
      await _settle(t);
    }
  });

  for (final (name, size) in [
    ('390', const Size(390, 1100)),
    ('320', const Size(320, 1100)),
    ('ipad', const Size(1024, 1100)),
  ]) {
    testWidgets('insights tab · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(ExhibitionDetailView(exhibitionId: '7', initial: _exs.first)));
      await _settle(t);
      await t.tap(find.text('Insights'));
      await _settle(t);
      await t.scrollUntilVisible(find.text('Demos & leads by day'), 300,
          scrollable: find.byType(Scrollable).first);
      await _settle(t);
      expect(find.text('Lead rate'), findsOneWidget);
      // Switch the trend to running totals.
      await t.tap(find.text('Running total'));
      await _settle(t);
      await t.scrollUntilVisible(find.text('Lead quality'), 300,
          scrollable: find.byType(Scrollable).first);
      await _settle(t);
      await _shot(t, 'ex_insights_$name');
      // Tap a day: the legend shows that day's numbers.
      await t.tapAt(t.getCenter(find.byType(CustomPaint).last));
      await _settle(t);
    });
  }

  for (final (name, size) in [
    ('320', const Size(320, 700)),
    ('390', const Size(390, 844)),
    ('ipad', const Size(1024, 768)),
  ]) {
    testWidgets('exhibition list · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(const ExhibitionListView()));
      await _settle(t);
      await _shot(t, 'ex_list_$name');
    });

    testWidgets('exhibition detail demos + leads · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(ExhibitionDetailView(exhibitionId: '7', initial: _exs.first)));
      await _settle(t);
      await _shot(t, 'ex_detail_demos_$name');
      await t.tap(find.textContaining('Leads').first);
      await _settle(t);
      await _shot(t, 'ex_detail_leads_$name');
    });

    testWidgets('create exhibition · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(ExhibitionCreateView(initial: _exs.first)));
      await _settle(t);
      await _shot(t, 'ex_create_$name');
    });

    testWidgets('give demo · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(GiveDemoView(exhibition: _exs.first)));
      await _settle(t);
      await _shot(t, 'ex_give_$name');
    });

    testWidgets('capture lead + demo sent sheets · $name', (t) async {
      _size(t, size);
      await t.pumpWidget(_app(Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              TextButton(
                onPressed: () => showCaptureLeadSheet(context,
                    exhibitionId: '7', demo: _demos.first, prefillNumber: '9811112222'),
                child: const Text('lead'),
              ),
              TextButton(
                onPressed: () => showDemoSentSheet(context,
                    callCount: 3,
                    exhibitionName: _exs.first.name,
                    visitorName: 'Mrs. Lakshmi',
                    visitorNumbers: const ['9811112222', '9833334444']),
                child: const Text('sent'),
              ),
            ],
          ),
        ),
      )));
      await t.tap(find.text('lead'));
      await _settle(t);
      // No field is focused (keyboard stays down) until the user taps one.
      expect(find.byWidgetPredicate((w) => w is EditableText && w.focusNode.hasFocus), findsNothing);
      await _shot(t, 'ex_lead_sheet_$name');
      Navigator.of(t.element(find.text('lead'))).popUntil((r) => r.isFirst);
      await _settle(t);
      await t.tap(find.text('sent'));
      await _settle(t);
      await _shot(t, 'ex_sent_sheet_$name');
    });
  }
}
