import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/OverallTripDetailsModel.dart';
import 'package:sssbuddy/components/TripRouteMap.dart';

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
}
