import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/OverallTripDetailsModel.dart';
import '../auth/model/TrackPointModel.dart';
import '../core/location/trip_track_store.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';
import 'today_visit_viewmodal.dart';

/// What the Root Tracker map shows for one member on one day.
class RootTrackerData {
  final int memberId;
  final DateTime date;
  final bool isSelf;

  /// Recorded GPS breadcrumbs (oldest first).
  final List<TrackPoint> points;

  /// All Today Visit trips of that day from the server (start/end +
  /// visits), oldest first — the same data Status Report shows.
  final List<Overalltripdetailsmodel> trips;

  /// True when the route API failed (not live yet / offline), so only
  /// start, end and visit points from the trip details can be shown.
  final bool routeUnavailable;

  const RootTrackerData({
    required this.memberId,
    required this.date,
    required this.isSelf,
    required this.points,
    required this.trips,
    required this.routeUnavailable,
  });

  bool get hasTrip => trips.isNotEmpty;

  DateTime? get firstStart => trips.isEmpty ? null : trips.first.startDateTime;

  /// Server's start → visits → end estimate, same km as Status Report.
  double get reportKm =>
      trips.fold<double>(0, (sum, t) => sum + t.totalDistanceKm);

  int get visitCount =>
      trips.fold<int>(0, (sum, t) => sum + t.visit_details.length);

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool get tripRunning => trips.any((t) {
        final end = t.end_time?.trim();
        return end == null || end.isEmpty || end.toLowerCase() == 'null';
      });
}

class RootTrackerViewmodel extends AsyncNotifier<RootTrackerData?> {
  int _requestId = 0;

  @override
  Future<RootTrackerData?> build() async => null;

  /// Loads route + trip details. [silent] keeps the old map on screen
  /// while refreshing (auto-refresh), instead of showing a loader.
  Future<void> load({
    required int memberId,
    required DateTime date,
    bool silent = false,
  }) async {
    final requestId = ++_requestId;
    if (!silent || state.value == null) state = const AsyncLoading();

    try {
      final loginData = ref.read(loginProvider).value;
      if (loginData == null) throw Exception("User not logged in");
      final repo = ref.read(repositoryProvider);
      final day = TripTrackStore.dayKey(date);
      final isSelf = memberId == loginData.userId;

      // Trip details (start/end/visits) – already live on the server.
      List<Overalltripdetailsmodel> sameDay = [];
      try {
        final trips =
            await repo.getoveralldetails(loginData.token, memberId.toString());
        sameDay = trips.where((t) {
          final s = t.startDateTime;
          return s != null &&
              s.year == date.year &&
              s.month == date.month &&
              s.day == date.day;
        }).toList();
        sameDay.sort((a, b) => a.startDateTime!.compareTo(b.startDateTime!));
      } catch (e) {
        print("RootTracker trip details Error => $e");
      }

      // Route points: own route comes from the phone first.
      List<TrackPoint> points = [];
      if (isSelf) {
        final live = ref.read(todayVisitProvider.notifier).trackLog;
        final isToday = day == TripTrackStore.dayKey(DateTime.now());
        points = isToday && live.isNotEmpty
            ? List.of(live)
            : await TripTrackStore.load(memberId, day);
      }

      bool routeUnavailable = false;
      if (points.isEmpty) {
        try {
          points = await repo.getTripLocations(
              loginData.token, memberId.toString(), day);
        } catch (e) {
          print("GetTripLocations Error => $e");
          routeUnavailable = true;
        }
      }

      if (requestId != _requestId) return; // a newer selection won
      state = AsyncData(RootTrackerData(
        memberId: memberId,
        date: date,
        isSelf: isSelf,
        points: points,
        trips: sameDay,
        routeUnavailable: routeUnavailable,
      ));
    } catch (e, st) {
      if (requestId != _requestId) return;
      state = AsyncError(e, st);
    }
  }
}

final rootTrackerProvider =
    AsyncNotifierProvider<RootTrackerViewmodel, RootTrackerData?>(
  RootTrackerViewmodel.new,
);
