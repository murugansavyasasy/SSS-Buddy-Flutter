import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sssbuddy/auth/model/Demolist.dart';
import 'package:sssbuddy/auth/model/Validatelogin.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/view/create_demo.dart';
import 'package:sssbuddy/view/demo_list.dart';
import 'package:sssbuddy/view/login.dart';
import 'package:sssbuddy/viewModel/demolist_view_model.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

/// Main module screens render at phone width without layout errors.
/// `--dart-define=SHOTS=true --update-goldens` saves screenshots.
class _Login extends LoginViewModel {
  @override
  Future<LoginData?> build() async => LoginData(
        token: 't', userId: 1, employeeId: 'E1', name: 'Ravi', email: '',
        roleId: 1, roleCode: 'Admin', roleSlug: 'admin', roleName: 'Admin', schoolUserId: '5');
}

class _Demos extends DemolistViewModel {
  @override
  Future<List<Demolist>> build() async => [
        for (final (i, s) in [
          'Sri Venkateswara Matriculation Higher Secondary School',
          'ABC Public School',
          'GV International',
          'St. Joseph\'s Convent',
        ].indexed)
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

Widget _app(Widget home) => ProviderScope(
      overrides: [
        loginProvider.overrideWith(() => _Login()),
        demoviewProvider.overrideWith(() => _Demos()),
      ],
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (name, screen) in [
    ('login', const LoginScreen()),
    ('create_demo', const CreateDemo()),
    ('demo_list', const DemoListView()),
  ]) {
    testWidgets('$name renders at 390 pt', (t) async {
      t.view.physicalSize = const Size(390 * 3, 844 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(screen));
      await t.pump();
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      if (const bool.fromEnvironment('SHOTS')) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/mod_$name.png'));
      }
    });
  }
}
