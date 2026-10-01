import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';

import '../provider/app_providers.dart';
import '../utils/trip_date_utils.dart';
import 'login_view_model.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

class OverallTripViewmodel
    extends AsyncNotifier<List<Overalltripdetailsmodel>> {
  List<Overalltripdetailsmodel> _all = [];

  @override
  Future<List<Overalltripdetailsmodel>> build() async {
    print('📌 OverallTripViewmodel build() called');
    return [];
  }

  Future<void> loadForMember(int idMember) async {
    print('📡 loadForMember CALLED → ID: $idMember');

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _fetch(idMember);

      final now = DateTime.now();
      var month = DateTime(now.year, now.month);

      if (filterByMonth(month).isEmpty) {
        final dates = _all
            .map((t) => parseTripDate(t.start_time))
            .whereType<DateTime>()
            .toList();

        if (dates.isNotEmpty) {
          dates.sort();
          month = DateTime(dates.last.year, dates.last.month);
        }
      }

      ref.read(selectedMonthProvider.notifier).state = month;

      return filterByMonth(month);
    });
  }

  Future<void> _fetch(int idMember) async {
    final loginData = ref.read(loginProvider).value;

    if (loginData == null) {
      throw Exception("User not logged in");
    }

    final token = loginData.token;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getoveralldetails(
      token,
      idMember.toString(),
    );

    await TripAddressLoader.loadAddresses(response);

    _all = await repo.getoveralldetails(
      token,
      idMember.toString(),
    );
  }

  void setMonth(DateTime month) {
    final m = DateTime(month.year, month.month);

    ref.read(selectedMonthProvider.notifier).state = m;

    state = AsyncData(filterByMonth(m));
  }

  List<Overalltripdetailsmodel> filterByMonth(DateTime month) {
    return _all.where((t) {
      final d = parseTripDate(t.start_time);

      return d != null &&
          d.year == month.year &&
          d.month == month.month;
    }).toList();
  }

  void filter(String query) {
    final monthList = filterByMonth(
      ref.read(selectedMonthProvider),
    );

    if (query.trim().isEmpty) {
      state = AsyncData(monthList);
      return;
    }

    final lower = query.toLowerCase();

    final filteredList = monthList.where((item) {
      return item.username.toLowerCase().contains(lower);
    }).toList();

    state = AsyncData(filteredList);
  }
}

final overallTripProvider =
AsyncNotifierProvider<OverallTripViewmodel,
    List<Overalltripdetailsmodel>>(
  OverallTripViewmodel.new,
);