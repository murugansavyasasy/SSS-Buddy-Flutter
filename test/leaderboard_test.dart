import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/LeaderboardModel.dart';
import 'package:sssbuddy/repository/leaderboard_repository.dart';
import 'package:sssbuddy/view/leaderboard/leaderboard_view.dart';
import 'package:sssbuddy/viewModel/leaderboard_viewmodel.dart';

LbEntry entry(String id, double demos, {bool me = false, int? prev}) => LbEntry(
      member: LbMember(id: id, name: 'Person $id'),
      isMe: me,
      previousRank: prev,
      scores: {
        LbMetric.demos: LbScore(demos, 20),
        LbMetric.pos: const LbScore(3, 6),
        LbMetric.poValue: const LbScore(300000, 600000),
        LbMetric.collection: const LbScore(200000, 450000),
      },
    );

void main() {
  test('ties share a rank and rank change is computed', () {
    final ranked = rankEntries(
      [entry('a', 10, prev: 1), entry('b', 15, prev: 3), entry('c', 15), entry('d', 5)],
      LbMetric.demos,
    );
    expect(ranked.map((r) => r.rank), [1, 1, 3, 4]);
    expect(ranked.firstWhere((r) => r.entry.member.id == 'b').rankChange, 2);
    expect(ranked.firstWhere((r) => r.entry.member.id == 'a').rankChange, -2);
  });

  test('overall score caps each metric at 150%', () {
    final e = LbEntry(
      member: const LbMember(id: 'x', name: 'X'),
      isMe: false,
      scores: {
        LbMetric.demos: const LbScore(100, 10), // 1000% -> capped 150%
        LbMetric.pos: const LbScore(0, 5),
        LbMetric.poValue: const LbScore(0, 1),
        LbMetric.collection: const LbScore(0, 1),
      },
    );
    expect(e.overallScore, closeTo(37.5, 0.001));
  });

  testWidgets('renders every metric on a phone screen without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Real timers: the demo repository uses Future.delayed.
    final entries = (await tester.runAsync(() => DemoLeaderboardRepository().fetch(
          period: LbPeriod.month,
          me: const LbMember(id: 'me', name: 'Murugan N', role: 'Admin'),
          team: const [],
        )))!;

    await tester.pumpWidget(ProviderScope(
      overrides: [
        leaderboardProvider.overrideWith((ref) async => entries),
      ],
      child: const MaterialApp(home: LeaderboardView()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.textContaining('Your rank'), findsOneWidget);

    for (final m in LbMetric.values) {
      await tester.ensureVisible(find.text(m.label).first);
      await tester.tap(find.text(m.label).first);
      await tester.pumpAndSettle();
    }
    for (final p in LbPeriod.values) {
      await tester.tap(find.text(p.label));
      await tester.pumpAndSettle();
    }
  });
}
