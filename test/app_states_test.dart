import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/components/app_states.dart';
import 'package:sssbuddy/core/network/DioClient.dart';
import 'package:sssbuddy/values/app_theme.dart';

/// Shared loading / error / empty states render and settle without errors.
Future<void> _loadFonts() async {
  final loader = FontLoader('DMSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(
        File('assets/Fonts/DMSans/DMSans-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFonts);

  for (final (name, child) in [
    ('skeleton', const AppListSkeleton()),
    ('error', AppErrorView(error: ApiException('No internet connection. Please check your network.'), onRetry: () {})),
    ('empty', const AppEmptyView(title: 'No demos yet', message: 'Create a demo and it will appear here.', icon: Icons.record_voice_over_outlined)),
  ]) {
    testWidgets('state: $name', (t) async {
      t.view.physicalSize = const Size(390 * 3, 700 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(backgroundColor: const Color(0xFFF2F5F9), body: child),
      ));
      await t.pump(const Duration(milliseconds: 700));
      expect(t.takeException(), isNull);
      if (const bool.fromEnvironment('SHOTS')) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('shots/state_$name.png'));
      }
    });
  }
}
