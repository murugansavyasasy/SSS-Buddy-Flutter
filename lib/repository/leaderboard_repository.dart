import 'dart:math';

import '../auth/model/LeaderboardModel.dart';

/// Source of leaderboard numbers.
///
/// Today: [DemoLeaderboardRepository] — generated numbers for the design
/// review. Later: an API that returns achieved/target per metric per member
/// for the period; swap it in `leaderboardRepositoryProvider`.
abstract class LeaderboardRepository {
  Future<List<LbEntry>> fetch({
    required LbPeriod period,
    required LbMember me,
    required List<LbMember> team,
  });
}

class DemoLeaderboardRepository implements LeaderboardRepository {
  /// Used to fill the board when the real team is small, so the design can
  /// be reviewed with a realistic number of rows.
  static const _sampleTeam = [
    LbMember(id: 'demo_ravi', name: 'Ravi Kumar', role: 'Sales Executive'),
    LbMember(id: 'demo_priya', name: 'Priya Lakshmi', role: 'Sales Executive'),
    LbMember(id: 'demo_arun', name: 'Arun Prakash', role: 'Senior Executive'),
    LbMember(id: 'demo_karthik', name: 'Karthik Raja', role: 'Sales Executive'),
    LbMember(id: 'demo_divya', name: 'Divya S', role: 'Sales Executive'),
    LbMember(id: 'demo_suresh', name: 'Suresh Babu', role: 'Sales Executive'),
    LbMember(id: 'demo_meena', name: 'Meena R', role: 'Sales Trainee'),
    LbMember(id: 'demo_vignesh', name: 'Vignesh M', role: 'Sales Executive'),
  ];

  static const _minRows = 8;

  @override
  Future<List<LbEntry>> fetch({
    required LbPeriod period,
    required LbMember me,
    required List<LbMember> team,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final members = <LbMember>[me, ...team.where((m) => m.id != me.id)];
    for (final s in _sampleTeam) {
      if (members.length >= _minRows) break;
      if (!members.any((m) => m.id == s.id)) members.add(s);
    }

    final entries = [
      for (final m in members)
        LbEntry(member: m, isMe: m.id == me.id, scores: _scores(m.id, period, 0)),
    ];

    // Previous-period ranks from the same generator, one period earlier.
    final previous = [
      for (final m in members)
        LbEntry(member: m, isMe: false, scores: _scores(m.id, period, 1)),
    ];
    final prevRank = {
      for (final r in rankEntries(previous, LbMetric.overall))
        r.entry.member.id: r.rank,
    };

    return [
      for (final e in entries)
        LbEntry(
          member: e.member,
          isMe: e.isMe,
          scores: e.scores,
          previousRank: prevRank[e.member.id],
        ),
    ];
  }

  /// Deterministic per member + period, so numbers don't jump on refresh.
  Map<LbMetric, LbScore> _scores(String memberId, LbPeriod period, int periodsAgo) {
    final now = DateTime.now();
    final periodKey = switch (period) {
      LbPeriod.week => now.difference(DateTime(now.year)).inDays ~/ 7,
      LbPeriod.month => now.month,
      LbPeriod.quarter => (now.month - 1) ~/ 3,
    };
    final seed = Object.hash(memberId, period.name, periodKey - periodsAgo);
    final rnd = Random(seed);

    // How far into the period we are (current period only).
    final elapsed = periodsAgo > 0
        ? 1.0
        : switch (period) {
            LbPeriod.week => (now.weekday / 7),
            LbPeriod.month =>
              now.day / DateTime(now.year, now.month + 1, 0).day,
            LbPeriod.quarter =>
              (((now.month - 1) % 3) * 30 + now.day) / 91,
          };

    final scale = switch (period) {
      LbPeriod.week => 0.25,
      LbPeriod.month => 1.0,
      LbPeriod.quarter => 3.0,
    };

    // Skill factor per person (stable), plus per-period noise.
    final skill = 0.55 + Random(memberId.hashCode).nextDouble() * 0.7;

    LbScore score(double monthlyTarget, {bool round = true}) {
      final target = monthlyTarget * scale;
      var achieved = target * elapsed * skill * (0.7 + rnd.nextDouble() * 0.6);
      if (round) achieved = achieved.roundToDouble();
      return LbScore(achieved, round ? target.roundToDouble() : target);
    }

    return {
      LbMetric.demos: score(20),
      LbMetric.pos: score(6),
      LbMetric.poValue: score(600000, round: false),
      LbMetric.collection: score(450000, round: false),
    };
  }
}
