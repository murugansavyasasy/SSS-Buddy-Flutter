import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ReportingMembersModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';
import 'reporting_members_dd_viewmodel.dart';

/// Today's entry status split into the members who HAVE recorded a trip for the
/// current day and those who have NOT.
class TodayEntryStatus {
  final List<Reportingmembersmodel> present;
  final List<Reportingmembersmodel> absent;

  const TodayEntryStatus({required this.present, required this.absent});

  bool get isEmpty => present.isEmpty && absent.isEmpty;
}

/// Computes [TodayEntryStatus] for every reporting member.
///
/// There is no bulk / attendance endpoint, so this fetches each member's trip
/// details individually (in parallel) and classifies them by whether any of
/// their trips are dated today.
final todayEntryStatusProvider =
    FutureProvider.autoDispose<TodayEntryStatus>((ref) async {
  final loginData = ref.watch(loginProvider).value;
  if (loginData == null) {
    return const TodayEntryStatus(present: [], absent: []);
  }

  final members = await ref.watch(reportingmembersProvider.future);
  if (members.isEmpty) {
    return const TodayEntryStatus(present: [], absent: []);
  }

  final token = loginData.token;
  final repo = ref.read(repositoryProvider);

  final now = DateTime.now();
  bool isToday(DateTime? d) =>
      d != null &&
      d.year == now.year &&
      d.month == now.month &&
      d.day == now.day;

  // Fetch every member's trips in parallel and record whether they have an
  // entry dated today.
  final results = await Future.wait(
    members.map((member) async {
      try {
        final trips = await repo.getoveralldetails(
          token,
          member.idmember.toString(),
        );
        final hasEntryToday = trips.any((t) => isToday(t.startDateTime));
        return (member: member, present: hasEntryToday);
      } catch (_) {
        // On failure we can't prove an entry exists, so treat as absent.
        return (member: member, present: false);
      }
    }),
  );

  return TodayEntryStatus(
    present: [for (final r in results) if (r.present) r.member],
    absent: [for (final r in results) if (!r.present) r.member],
  );
});
