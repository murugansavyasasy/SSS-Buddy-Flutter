import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/TicketModel.dart';
import 'package:sssbuddy/repository/ticket_repository.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/view/ticket/ticket_detail_view.dart';
import 'package:sssbuddy/view/ticket/ticket_form_view.dart';
import 'package:sssbuddy/view/ticket/ticket_list_view.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/viewModel/ticket_viewmodel.dart';

/// Renders the Tickets screens at phone widths and fails on any overflow.
/// `flutter test test/ticket_layout_test.dart --dart-define=SHOTS=true
/// --update-goldens` also writes screenshots to test/shots/.
Future<void> _loadFonts() async {
  final loader = FontLoader('DMSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(
        File('assets/Fonts/DMSans/DMSans-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

Future<void> _seed() async {
  SharedPreferences.setMockInitialValues({});
  final repo = LocalTicketRepository();
  final a = await repo.createTicket(
    const CreateTicketRequest(
      app: 'School Chimes',
      description: 'Circular is not reaching parents of 8th standard. Tried twice from the admin login.',
      priority: TicketPriority.high,
      attachments: [
        TicketAttachment(url: '/missing/shot.jpg', type: TicketAttachmentType.image),
        TicketAttachment(url: '/missing/clip.mp4', type: TicketAttachmentType.video),
      ],
      platform: 'android 14',
    ),
    userId: '2',
    userName: 'Priya Raman',
  );
  await repo.assign(a.id, (id: '4', name: 'Kavin Kumar'), byName: 'Admin');
  await repo.updateStatus(a.id, TicketStatus.inProgress, note: 'Checking SMS gateway', byName: 'Support Team');
  await repo.updateStatus(a.id, TicketStatus.completed,
      note: 'Gateway fixed, circular re-sent.', byName: 'Support Team');
  await repo.createTicket(
    const CreateTicketRequest(app: 'Gradit', description: 'Attendance screen is slow to load.'),
    userId: '1',
    userName: 'Ravi Kumar',
  );
  final c = await repo.createTicket(
    const CreateTicketRequest(
        app: "Let's Reach", description: 'Login OTP not received', priority: TicketPriority.low),
    userId: '3',
    userName: 'Venkataravi C R',
  );
  await repo.updateStatus(c.id, TicketStatus.inProgress, byName: 'Admin');
}

Widget _app(Widget home) => ProviderScope(
      overrides: [
        ticketRepositoryProvider.overrideWithValue(LocalTicketRepository()),
        ticketUserProvider.overrideWith((ref) async => (id: '1', name: 'Admin', canManage: true)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: Routes.generateRoutes,
        home: home,
      ),
    );

Future<void> _shot(WidgetTester t, String name) async {
  if (const bool.fromEnvironment('SHOTS')) {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/$name.png'));
  }
}

void main() {
  setUpAll(_loadFonts);

  for (final width in [320.0, 390.0]) {
    final w = width.toInt();

    testWidgets('ticket list fits a $w pt phone', (t) async {
      t.view.physicalSize = Size(width * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await _seed();

      await t.pumpWidget(_app(const TicketListView()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('School Chimes'), findsOneWidget);
      await _shot(t, 'tickets_list_$w');

      await t.tap(find.text('In Progress').first);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text("Let's Reach"), findsOneWidget);
      expect(find.text('Gradit'), findsNothing);
    });

    testWidgets('ticket detail fits a $w pt phone', (t) async {
      t.view.physicalSize = Size(width * 3, 1400 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await _seed();
      final id = (await LocalTicketRepository().fetchTickets(userId: '', all: true))
          .firstWhere((x) => x.app == 'School Chimes')
          .id;

      await t.pumpWidget(_app(TicketDetailView(ticketId: id)));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Reopen'), findsOneWidget);
      expect(find.text('Kavin Kumar'), findsWidgets);
      expect(find.text('Assigned to Kavin Kumar'), findsOneWidget);
      await _shot(t, 'tickets_detail_$w');
    });

    testWidgets('raise ticket form fits a $w pt phone', (t) async {
      t.view.physicalSize = Size(width * 3, 1100 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});

      await t.pumpWidget(_app(const TicketFormView()));
      await t.pumpAndSettle();
      await t.tap(find.text('Submit Ticket'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Select the app with the issue'), findsOneWidget);

      await t.tap(find.text('Gradit'));
      await t.pumpAndSettle();
      expect(find.text('Select the app with the issue'), findsNothing);
      await _shot(t, 'tickets_form_$w');
    });
  }
}
