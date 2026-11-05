import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';
import 'package:sssbuddy/auth/model/TrackPointModel.dart';
import 'package:sssbuddy/components/TripRouteMap.dart';
import 'package:sssbuddy/components/TripTimelineView.dart';
import 'package:sssbuddy/viewModel/root_tracker_viewmodel.dart';

Overalltripdetailsmodel trip(int id, String start, List<Map<String, dynamic>> visits,
        {String? endLat, String? endLng}) =>
    Overalltripdetailsmodel.fromJson({
      'trip_id': id,
      'start_time': start,
      'start_latitude': '13.0827',
      'start_longitude': '80.2707',
      'end_latitude': endLat,
      'end_longitude': endLng,
      'visit_details': visits,
    });

void main() {
  test('stops: S, visits numbered across trips, E; bad coords skipped', () {
    final later = trip(2, 'Nov  5 2026  2:00PM', [
      {'school_name': 'C', 'school_latitude': '13.03', 'school_longitude': '80.21'},
    ]);
    final earlier = trip(1, 'Nov  5 2026  9:00AM', [
      {'school_name': 'A', 'school_latitude': '13.05', 'school_longitude': '80.22'},
      {'school_name': 'no gps', 'school_latitude': '', 'school_longitude': ''},
      {'school_name': 'B', 'school_latitude': '0', 'school_longitude': '0'},
    ], endLat: '13.00', endLng: '80.25');

    final stops = buildRouteStops([later, earlier]);
    expect(stops.map((s) => s.label).toList(), ['S', '1', 'E', 'S', '2']);
    expect(stops[1].title, 'A');
    expect(stops[4].title, 'C');
  });

  test('pin km + km after last stop equals the GPS total shown outside', () {
    final t = trip(1, '2026-11-05 09:00:00', [
      {'school_name': 'A', 'school_latitude': '13.0900', 'school_longitude': '80.2200'},
      {'school_name': 'B', 'school_latitude': '13.0950', 'school_longitude': '80.2300'},
    ]);
    final stops = buildRouteStops([t]);
    final t0 = DateTime(2026, 11, 5, 9);
    TrackPoint p(double lat, double lng, int i, int seg) => TrackPoint(
        lat: lat, lng: lng, time: t0.add(Duration(minutes: i)), segment: seg);
    // A fix before the start pin, a GPS gap (segment 0 → 1) and driving
    // on after the last school.
    final track = [
      p(13.0820, 80.2690, 0, 0),
      p(13.0827, 80.2707, 1, 0),
      p(13.0870, 80.2450, 2, 0),
      p(13.0900, 80.2200, 3, 0),
      p(13.0930, 80.2260, 4, 1),
      p(13.0950, 80.2300, 5, 1),
      p(13.0990, 80.2350, 6, 1),
    ];
    final line = track.map((e) => e.latLng).toList();
    final segs = track.map((e) => e.segment).toList();

    final km = stopDistancesKm(stops, line, segments: segs);
    final after = kmAfterLastStop(stops, line, segs);

    expect(km.first, 0);
    expect(km, orderedEquals([...km]..sort()));
    expect(after, greaterThan(0));
    expect(km.last + after, closeTo(TrackPoint.totalKm(track), 1e-9));
  });

  test('no GPS: legs, total and duration all agree with Status Report', () {
    final t = Overalltripdetailsmodel.fromJson({
      'trip_id': 7,
      'start_time': '2026-11-05 09:31:00',
      'end_time': '2026-11-05 14:44:00',
      'start_latitude': '17.3297',
      'start_longitude': '76.8343',
      'end_latitude': '17.29809',
      'end_longitude': '76.80961',
      'visit_details': [
        {'school_name': 'A', 'school_latitude': '17.3400', 'school_longitude': '76.8100'},
        {'school_name': 'B', 'school_latitude': '17.3450', 'school_longitude': '76.8180'},
        {'school_name': 'C', 'school_latitude': '17.3380', 'school_longitude': '76.8260'},
      ],
    });
    final data = RootTrackerData(
      memberId: 1,
      date: DateTime(2026, 11, 5),
      isSelf: false,
      points: const [],
      trips: [t],
      routeUnavailable: false,
    );

    final legs = stopDistancesKm(buildRouteStops([t]), const []);
    final stats = TripStats.of(data, const [], false);

    expect(stats.usingGps, isFalse);
    expect(legs.last, closeTo(stats.km, 1e-9)); // pins == outer total
    expect(stats.km, closeTo(t.totalDistanceKm, 1e-9)); // == Status Report
    expect(stats.duration, '5h 13m'); // from trip start/end, not "--"
  });
}
