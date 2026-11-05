import 'package:flutter_test/flutter_test.dart';
import 'package:sssbuddy/auth/model/TrackPointModel.dart';

void main() {
  final t = DateTime(2026, 11, 5, 9);
  TrackPoint p(double lat, double lng, int seg, int min) =>
      TrackPoint(lat: lat, lng: lng, segment: seg, time: t.add(Duration(minutes: min)));

  test('km sums only inside a segment', () {
    // ~1.11 km per 0.01° latitude
    final pts = [
      p(13.00, 80.27, 0, 0),
      p(13.01, 80.27, 0, 5),
      // second trip far away — gap must not count
      p(13.50, 80.27, 1, 60),
      p(13.51, 80.27, 1, 65),
    ];
    expect(TrackPoint.totalKm(pts), closeTo(2.22, 0.02));
    expect(TrackPoint.segments(pts).length, 2);
  });

  test('api json round-trip and tolerant parsing', () {
    final a = p(13.0827, 80.2707, 2, 0);
    final b = TrackPoint.fromApiJson(a.toApiJson())!;
    expect(b.lat, a.lat);
    expect(b.segment, 2);
    expect(b.time, a.time);
    final c = TrackPoint.fromApiJson({'lat': '13.1', 'lon': '80.2', 'time': '2026-11-05T10:00:00'})!;
    expect(c.lng, 80.2);
    expect(TrackPoint.fromApiJson({'latitude': 0, 'longitude': 0}), isNull);
  });
}
