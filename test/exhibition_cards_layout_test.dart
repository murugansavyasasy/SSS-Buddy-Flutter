import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/ExhibitionModel.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import 'package:sssbuddy/repository/exhibition_repository.dart';
import 'package:sssbuddy/view/exhibition/exhibition_detail_view.dart';
import 'package:sssbuddy/viewModel/exhibition_viewmodel.dart';

class _Repo implements ExhibitionRepository {
  @override
  Future<Exhibition> fetchExhibition(String id) async => _ex;
  @override
  Future<List<Exhibition>> fetchExhibitions({String status = '', String search = ''}) async => [_ex];
  @override
  Future<List<ExhibitionDemo>> fetchDemos(String exhibitionId) async => _demos;
  @override
  Future<List<ExhibitionLead>> fetchLeads(String exhibitionId) async => _leads;
  @override
  Future<List<DemoTemplate>> fetchTemplates(String exhibitionId) async => const [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends UserSessionNotifier {
  @override
  Future<UserSession?> build() async => null;
}

final _ex = Exhibition.fromJson({
  'id': 7,
  'name': 'DIDAC India 2027',
  'venue': 'Bombay Exhibition Centre',
  'city': 'Mumbai',
  'startDate': '2027-09-10',
  'endDate': '2027-09-12',
  'status': 'active',
});

final _demos = [
  ExhibitionDemo.fromJson({
    'id': 1,
    'visitorName': 'Mrs. Lakshmi Narayanan from Sri Venkateswara Matriculation',
    'recipientCount': 3,
    'status': 'completed',
    'createdByName': 'Venkataravi C R',
    'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    'hasLead': true,
  }),
  ExhibitionDemo.fromJson({'id': 2, 'visitorName': '', 'recipientCount': 1, 'status': 'queued'}),
];

final _leads = [
  ExhibitionLead.fromJson({
    'id': 1,
    'schoolName': 'Sri Venkateswara Matriculation Higher Secondary School',
    'city': 'Kanchipuram',
    'contactName': 'Mrs. Lakshmi Narayanan',
    'contactNumber': '9876543210',
    'contactEmail': 'principal.svmhss.kanchipuram@example.com',
    'designation': 'Principal',
    'notes': 'Wants a follow-up demo for the management next week.',
    'interestLevel': 'Excellent',
    'createdByName': 'Venkataravi C R',
    'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    'visitorName': 'Mrs. Lakshmi',
  }),
  ExhibitionLead.fromJson({'id': 2, 'schoolName': 'ABC School'}),
];

Future<void> _loadFonts() async {
  final loader = FontLoader('DMSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(
        File('assets/Fonts/DMSans/DMSans-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Widget _app() => ProviderScope(
      overrides: [
        exhibitionRepositoryProvider.overrideWithValue(_Repo()),
        userSessionProvider.overrideWith(() => _Session()),
      ],
      child: MaterialApp(home: ExhibitionDetailView(exhibitionId: '7', initial: _ex)),
    );

void main() {
  setUpAll(_loadFonts);

  for (final width in [320.0, 390.0]) {
    testWidgets('demo and lead cards fit a ${width.toInt()} pt phone', (t) async {
      t.view.physicalSize = Size(width * 3, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      await t.pumpWidget(_app());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      // The header (with the School Chimes showcase button) is tall: scroll
      // down to the demo cards.
      for (var k = 0; k < 8 && find.text('Lead captured').evaluate().isEmpty; k++) {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await t.pumpAndSettle();
      }
      expect(find.text('Lead captured'), findsWidgets);
      if (const bool.fromEnvironment('SHOTS')) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('shots/demos_${width.toInt()}.png'));
      }

      await t.drag(find.byType(Scrollable).first, const Offset(0, 3000)); // back to the top
      await t.pumpAndSettle();
      await t.tap(find.textContaining('Leads').first);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      for (var k = 0; k < 8 && find.byTooltip('Send demo video on WhatsApp').evaluate().isEmpty; k++) {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await t.pumpAndSettle();
      }
      expect(find.byTooltip('Send demo video on WhatsApp'), findsOneWidget);
      expect(find.text('Principal'), findsOneWidget);
      if (const bool.fromEnvironment('SHOTS')) {
        await expectLater(find.byType(MaterialApp),
            matchesGoldenFile('shots/leads_${width.toInt()}.png'));
      }
    });
  }
}
