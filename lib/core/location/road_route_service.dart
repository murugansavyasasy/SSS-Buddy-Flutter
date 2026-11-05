import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Road-following path through a list of stops, using the public OSRM
/// router (OpenStreetMap data). Results are cached for the app session.
class RoadRouteService {
  static const _base = 'https://router.project-osrm.org/route/v1/driving/';
  static const _chunk = 25; // waypoints per request
  static final Map<String, List<LatLng>> _cache = {};

  static String _key(List<LatLng> stops) => stops
      .map((p) =>
          '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}')
      .join('|');

  /// Returns the road path, or null when routing fails (offline etc.) —
  /// callers then draw straight lines between the stops.
  static Future<List<LatLng>?> route(List<LatLng> stops) async {
    final clean = _dedupe(stops);
    if (clean.length < 2) return null;

    final key = _key(clean);
    final cached = _cache[key];
    if (cached != null) return cached;

    final path = <LatLng>[];
    // Split long days into overlapping chunks (last stop = next first stop).
    for (int i = 0; i < clean.length - 1; i += _chunk - 1) {
      final end = (i + _chunk).clamp(0, clean.length);
      final part = await _fetch(clean.sublist(i, end));
      if (part == null) return null;
      if (path.isNotEmpty && part.isNotEmpty) part.removeAt(0);
      path.addAll(part);
    }
    _cache[key] = path;
    return path;
  }

  static Future<List<LatLng>?> _fetch(List<LatLng> stops) async {
    try {
      final coords =
          stops.map((p) => '${p.longitude},${p.latitude}').join(';');
      final res = await http
          .get(Uri.parse('$_base$coords?overview=full&geometries=geojson'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final coordsList = routes[0]['geometry']['coordinates'] as List;
      return coordsList
          .map<LatLng>((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Drops consecutive stops closer than ~20 m (same school twice, etc.).
  static List<LatLng> _dedupe(List<LatLng> stops) {
    const d = Distance();
    final out = <LatLng>[];
    for (final p in stops) {
      if (out.isEmpty || d.as(LengthUnit.Meter, out.last, p) > 20) out.add(p);
    }
    return out;
  }
}
