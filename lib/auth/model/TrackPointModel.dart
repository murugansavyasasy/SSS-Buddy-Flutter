import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

/// One GPS fix recorded while a trip is running.
///
/// [segment] separates trips started on the same day (START → END → START),
/// so the map does not draw a straight line between the end of one trip and
/// the start of the next, and the km do not include that gap.
class TrackPoint {
  final double lat;
  final double lng;
  final DateTime time;
  final int segment;

  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.time,
    this.segment = 0,
  });

  LatLng get latLng => LatLng(lat, lng);

  // ── Local storage (SharedPreferences) ──

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        't': time.toIso8601String(),
        's': segment,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        time: DateTime.tryParse(json['t']?.toString() ?? '') ?? DateTime.now(),
        segment: (json['s'] as num?)?.toInt() ?? 0,
      );

  // ── Server API ──

  static final DateFormat _apiFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  Map<String, dynamic> toApiJson() => {
        'latitude': lat,
        'longitude': lng,
        'recorded_at': _apiFormat.format(time),
        'segment': segment,
      };

  /// Tolerant parser: accepts latitude/lat, longitude/lng/lon,
  /// recorded_at/time and numbers sent as strings.
  static TrackPoint? fromApiJson(Map<String, dynamic> json) {
    double? num_(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

    final lat = num_(json['latitude'] ?? json['lat']);
    final lng = num_(json['longitude'] ?? json['lng'] ?? json['lon']);
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;

    final rawTime = (json['recorded_at'] ?? json['time'])?.toString() ?? '';
    DateTime? time = DateTime.tryParse(rawTime);
    if (time == null) {
      try {
        time = _apiFormat.parse(rawTime);
      } catch (_) {}
    }

    return TrackPoint(
      lat: lat,
      lng: lng,
      time: time ?? DateTime.now(),
      segment: (num_(json['segment']) ?? 0).toInt(),
    );
  }

  // ── Distance helpers ──

  static const Distance _distance = Distance();

  /// Metres between two points.
  static double metersBetween(TrackPoint a, TrackPoint b) =>
      _distance.as(LengthUnit.Meter, a.latLng, b.latLng);

  /// Total travelled km, summed inside each segment only.
  static double totalKm(List<TrackPoint> points) {
    double meters = 0;
    for (int i = 1; i < points.length; i++) {
      if (points[i].segment != points[i - 1].segment) continue;
      meters += metersBetween(points[i - 1], points[i]);
    }
    return meters / 1000;
  }

  /// Points grouped by segment, in order — one polyline per segment.
  static List<List<LatLng>> segments(List<TrackPoint> points) {
    final result = <List<LatLng>>[];
    int? current;
    for (final p in points) {
      if (current != p.segment || result.isEmpty) {
        result.add([]);
        current = p.segment;
      }
      result.last.add(p.latLng);
    }
    return result;
  }
}
