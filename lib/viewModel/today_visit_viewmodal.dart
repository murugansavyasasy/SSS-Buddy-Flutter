import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../auth/model/TodayVisitModal.dart';

class TodayVisitViewmodel extends AsyncNotifier<RouteModel?> {
  @override
  Future<RouteModel?> build() async => null;
  Future<bool> endTripApi() async {
    try {
      // 👇 உங்கள் API call (example)
      final response = await Future.delayed(
        const Duration(seconds: 2),
            () => true, // success response
      );

      return response;
    } catch (e) {
      return false;
    }
  }
  Future<bool> startTripApi() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e) {
      return false;
    }
  }
  Future<void> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    state = const AsyncLoading();
    try {
      final url = "http://router.project-osrm.org/route/v1/driving/"
          "${start.longitude},${start.latitude};"
          "${end.longitude},${end.latitude}"
          "?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final route = data['routes'][0];

        final double distance = route['distance'] / 1000;
        final double duration = route['duration'] / 60;

        final coords = route['geometry']['coordinates'] as List;
        final List<LatLng> points = coords
            .map<LatLng>(
                (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        state = AsyncData(RouteModel(
          distance: distance,
          duration: duration,
          points: points,
        ));
      } else {
        state = AsyncError(
            "API Error ${response.statusCode}", StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final todayVisitProvider =
AsyncNotifierProvider<TodayVisitViewmodel, RouteModel?>(
  TodayVisitViewmodel.new,
);