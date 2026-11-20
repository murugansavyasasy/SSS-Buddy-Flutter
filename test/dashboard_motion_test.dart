import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/Demolist.dart';
import 'package:sssbuddy/auth/model/SchoolStats.dart';
import 'package:sssbuddy/auth/model/Validatelogin.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import 'package:sssbuddy/repository/ticket_repository.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/view/dashboard.dart';
import 'package:sssbuddy/viewModel/demolist_view_model.dart';
import 'package:sssbuddy/viewModel/followup_viewmodel.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';
import 'package:sssbuddy/viewModel/schoollist_view_model.dart';
import 'package:sssbuddy/viewModel/ticket_viewmodel.dart';

/// Dashboard with sample data: the entrance animations finish without
/// errors or overflow. With `--dart-define=SHOTS=true --update-goldens` it
/// also saves frames of the opening animation to test/shots/.
class _Login extends LoginViewModel {
  @override
  Future<LoginData?> build() async => LoginData(
        token: 't',
        userId: 1,
        employeeId: 'E1',
        name: 'Murugan',
        email: '',
        roleId: 1,
        roleCode: 'Admin',
        roleSlug: 'admin',
        roleName: 'Admin',
      );
}

class _Session extends UserSessionNotifier {
  @override
  Future<UserSession?> build() async => UserSession(
        employeeName: 'Murugan',
        employeeId: 'E1',
        employeerole: 'Admin',
        schoolUserId: '1',
        userId: '1',
        token: 't',
      );
}

class _Stats extends SchoolStatsViewModel {
  @override
  Future<SchoolStats> build() async => SchoolStats(
        totalSchools: 60,
        liveActive: 42,
        liveInactive: 6,
        pocActive: 9,
        pocInactive: 2,
        stopped: 3,
        rawList: [
          {'Status': 'LIVE', 'isActive': '1', 'Students': '18240', 'Staff': '920'},
          {'Status': 'POC', 'isActive': '1', 'Students': '3100', 'Staff': '140'},
          {'Status': 'STOPPED', 'isActive': '0', 'Students': '700', 'Staff': '35'},
        ],
      );
}

class _Demos extends DemolistViewModel {
  @override
  Future<List<Demolist>> build() async => [
        for (final (i, s) in ['Sri Venkateswara Matric', 'ABC Public School', 'GV International'].indexed)
          Demolist(schoolName: s, principalNumber: 9876500000 + i, demoId: 120 + i, DemoID: 120 + i),
      ];
}

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
        loginProvider.overrideWith(() => _Login()),
        userSessionProvider.overrideWith(() => _Session()),
        schoolStatsProvider.overrideWith(() => _Stats()),
        demoviewProvider.overrideWith(() => _Demos()),
        followUpDueCountProvider.overrideWithValue(0),
        ticketRepositoryProvider.overrideWithValue(LocalTicketRepository()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const Dashboard()),
    );

void main() {
  setUpAll(_loadFonts);

  testWidgets('dashboard opening animation settles on a 390 pt phone', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});

    await t.pumpWidget(_app());
    const shots = bool.fromEnvironment('SHOTS');
    // Frames of the opening: header/sheet, stat cards, demos, tiles.
    var at = 0;
    for (final ms in [0, 120, 240, 400, 600, 900, 1150]) {
      await t.pump(Duration(milliseconds: ms - at));
      at = ms;
      if (shots) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/dash_$ms.png'));
      }
    }
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('42'), findsOneWidget); // count-up finished
    if (shots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/dash_final.png'));
    }

    // Carousel auto-advances after 4 s: catch it half-way.
    await t.pump(const Duration(seconds: 3));
    await t.pump(const Duration(milliseconds: 300));
    if (shots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/dash_auto.png'));
    }
    await t.pumpAndSettle();
    expect(find.text('POC Schools'), findsOneWidget);

    // Carousel: half-way swipe shows the neighbour growing in.
    final swipe = await t.startGesture(t.getCenter(find.text('POC Schools')));
    await swipe.moveBy(const Offset(-80, 0));
    await t.pump();
    await swipe.moveBy(const Offset(-80, 0));
    await t.pump();
    if (shots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/dash_swipe.png'));
    }
    await swipe.up();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    // Finger on a menu tile: tinted spotlight under it.
    final press = await t.startGesture(
        t.getTopLeft(find.text('Demo List')) + const Offset(10, -30));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    if (shots) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/dash_touch.png'));
    }
    await press.cancel();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
