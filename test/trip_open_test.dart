import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';
import 'package:sssbuddy/viewModel/today_visit_viewmodal.dart';

Overalltripdetailsmodel trip(int id, String start, String? end) =>
    Overalltripdetailsmodel.fromJson({
      'trip_id': id,
      'start_time': start,
      'end_time': end,
    });

void main() {
  final now = DateTime(2026, 11, 26, 18);

  group('isTripOpen', () {
    test('no end_time is open', () {
      expect(TodayVisitViewmodel.isTripOpen(trip(1, '2026-11-26 09:00:00', null)), isTrue);
      expect(TodayVisitViewmodel.isTripOpen(trip(1, '2026-11-26 09:00:00', '')), isTrue);
      expect(TodayVisitViewmodel.isTripOpen(trip(1, '2026-11-26 09:00:00', 'null')), isTrue);
    });

    test('end after start is ended', () {
      expect(
          TodayVisitViewmodel.isTripOpen(
              trip(1, '2026-11-26 09:00:00', '2026-11-26 12:00:00')),
          isFalse);
    });

    test('restarted trip still carrying the old end_time is open', () {
      expect(
          TodayVisitViewmodel.isTripOpen(
              trip(1, '2026-11-26 14:00:00', '2026-11-26 12:00:00')),
          isTrue);
    });

    test('placeholder end_time is open', () {
      expect(
          TodayVisitViewmodel.isTripOpen(
              trip(1, '2026-11-26 09:00:00', '1900-01-01T00:00:00')),
          isTrue);
    });
  });

  group('latestTripToday', () {
    test('picks the latest trip started today, ignoring other days', () {
      final trips = [
        trip(1, '2026-11-26 08:00:00', null), // older trip left open
        trip(2, '2026-11-26 10:00:00', '2026-11-26 11:00:00'),
        trip(3, '2026-11-27 09:00:00', null),
        trip(4, '2026-11-25 20:00:00', null),
      ];
      final latest = TodayVisitViewmodel.latestTripToday(trips, now);
      expect(latest?.trip_id, 2);
      expect(TodayVisitViewmodel.isTripOpen(latest!), isFalse);
    });

    test('same start time: higher trip_id wins', () {
      final trips = [
        trip(5, '2026-11-26 10:00:00', null),
        trip(6, '2026-11-26 10:00:00', '2026-11-26 11:00:00'),
      ];
      expect(TodayVisitViewmodel.latestTripToday(trips, now)?.trip_id, 6);
    });

    test('no trip today', () {
      expect(
          TodayVisitViewmodel.latestTripToday(
              [trip(1, '2026-11-25 09:00:00', null)], now),
          isNull);
    });
  });
}
