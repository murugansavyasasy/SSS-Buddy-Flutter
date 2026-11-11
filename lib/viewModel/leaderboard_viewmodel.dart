import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/LeaderboardModel.dart';
import '../repository/leaderboard_repository.dart';
import 'login_view_model.dart';
import 'reporting_members_dd_viewmodel.dart';

/// Swap for the API implementation once the targets API exists.
final leaderboardRepositoryProvider =
    Provider<LeaderboardRepository>((ref) => DemoLeaderboardRepository());

class LeaderboardPeriodNotifier extends Notifier<LbPeriod> {
  @override
  LbPeriod build() => LbPeriod.month;

  void set(LbPeriod p) => state = p;
}

final leaderboardPeriodProvider =
    NotifierProvider<LeaderboardPeriodNotifier, LbPeriod>(
  LeaderboardPeriodNotifier.new,
);

class LeaderboardMetricNotifier extends Notifier<LbMetric> {
  @override
  LbMetric build() => LbMetric.overall;

  void set(LbMetric m) => state = m;
}

final leaderboardMetricProvider =
    NotifierProvider<LeaderboardMetricNotifier, LbMetric>(
  LeaderboardMetricNotifier.new,
);

final leaderboardProvider = FutureProvider.autoDispose<List<LbEntry>>(
  (ref) => _fetchBoard(ref, ref.watch(leaderboardPeriodProvider)),
);

/// Home page card: always this month, ranked by overall score, independent
/// of the filters chosen on the full leaderboard screen.
final dashboardLeaderboardProvider =
    FutureProvider.autoDispose<List<RankedEntry>>((ref) async {
  final entries = await _fetchBoard(ref, LbPeriod.month);
  return rankEntries(entries, LbMetric.overall);
});

Future<List<LbEntry>> _fetchBoard(Ref ref, LbPeriod period) async {
  final login = await ref.watch(loginProvider.future);
  if (login == null) return [];

  List<LbMember> team = [];
  try {
    final members = await ref.watch(reportingmembersProvider.future);
    team = members
        .where((m) => m.idmember != login.userId)
        .map((m) => LbMember(id: m.idmember.toString(), name: m.membername))
        .toList();
  } catch (_) {
    // Team list is optional; the board still shows the user.
  }

  return ref.read(leaderboardRepositoryProvider).fetch(
        period: period,
        me: LbMember(
          id: login.userId.toString(),
          name: login.name,
          role: login.roleName,
        ),
        team: team,
      );
}

/// Entries ranked by the selected metric.
final rankedLeaderboardProvider =
    Provider.autoDispose<AsyncValue<List<RankedEntry>>>((ref) {
  final metric = ref.watch(leaderboardMetricProvider);
  return ref
      .watch(leaderboardProvider)
      .whenData((entries) => rankEntries(entries, metric));
});
