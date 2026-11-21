import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/View/login.dart';
import 'package:sssbuddy/auth/model/Demolist.dart';
import 'package:sssbuddy/auth/model/Validatelogin.dart';
import 'package:sssbuddy/auth/model/Versioncheck.dart';
import 'package:sssbuddy/core/storage/secure_storage.dart';
import 'package:sssbuddy/main.dart';
import 'package:sssbuddy/provider/app_providers.dart';
import 'package:sssbuddy/repository/clientrepository.dart';
import 'package:sssbuddy/view/dashboard.dart';

/// Regression: after logout and a new login, the dashboard showed "No demo
/// list found". The restart kept the old Navigator (global key), so the
/// login screen saved the user into the old ProviderScope and the new
/// dashboard read an empty login.
class _Repo implements ClientRepository {
  int demoCalls = 0;

  @override
  Future<Versioncheck> getVersionCheckDetails() async => Versioncheck.fromJson({
        'IsVersionUpdateAvailable': 0,
        'IsForceUpdateRequired': 0,
        'result': 1,
        'resultMessage': '',
        'SchoolURL': 'https://school.test/',
        'VimsURL': 'https://vims.test/',
      });

  @override
  Future<LoginResponse> apilogin(String employeeId, String password) async => LoginResponse.fromJson({
        'status': 'success',
        'message': '',
        'data': {
          'token': 't',
          'userId': 7,
          'employeeId': employeeId,
          'schoolUserId': '55',
          'name': 'Ravi',
          'roleName': 'Sales',
          'roleCode': 'SE',
        },
      });

  @override
  Future<List<Demolist>> getdemolist(String schoolLoginId) async {
    demoCalls++;
    return [Demolist.fromJson({'SchoolName': 'Demo School $schoolLoginId', 'DemoId': 1})];
  }

  @override
  Future<List<dynamic>> postschoollist(String schoolLoginId) async => [];

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 20; i++) {
    await t.pump(const Duration(milliseconds: 200));
    t.takeException(); // plugins (notifications, connectivity) aren't available in tests
  }
}

// Finders use skipOffstage: false: the connectivity overlay keeps pages
// "offstage" in tests.
Future<void> _login(WidgetTester t) async {
  expect(find.byType(LoginScreen, skipOffstage: false), findsOneWidget);
  await t.enterText(find.byType(TextFormField, skipOffstage: false).at(0), 'E1');
  await t.enterText(find.byType(TextFormField, skipOffstage: false).at(1), 'pw');
  await t.tap(find.text('Login', skipOffstage: false).last, warnIfMissed: false);
  await _settle(t);
}

void main() {
  testWidgets('logout then login again: dashboard loads the demo list', (t) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844) * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final repo = _Repo();

    await t.pumpWidget(AppRoot(overrides: [repositoryProvider.overrideWithValue(repo)]));
    await _settle(t);
    await _login(t);
    expect(find.byType(Dashboard, skipOffstage: false), findsOneWidget);
    expect(find.text('Demo School 55', skipOffstage: false), findsOneWidget);
    expect(repo.demoCalls, 1);

    // Logout, as the header menu does.
    final ctx = t.element(find.byType(Dashboard, skipOffstage: false));
    await SecureStorage.clearLoginData();
    AppRoot.restartApp(ctx);
    await _settle(t);

    // Fresh start: splash → login (not a leftover screen of the old app).
    await _login(t);
    expect(find.byType(Dashboard, skipOffstage: false), findsOneWidget);
    expect(repo.demoCalls, 2);
    expect(find.text('Demo School 55', skipOffstage: false), findsOneWidget);
    expect(find.text('No demo list found', skipOffstage: false), findsNothing);
  });
}
