import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/model/TodayVisitModal.dart';
import '../provider/app_providers.dart';
import '../repository/clientrepository.dart';
import 'login_view_model.dart';

/// Model representing the current trip state
class TripState {
  final bool isTripStarted;
  final double distance; // km
  final int duration; // seconds
  final List<LatLng> points;

  TripState({
    required this.isTripStarted,
    required this.distance,
    required this.duration,
    required this.points,
  });

  TripState copyWith({
    bool? isTripStarted,
    double? distance,
    int? duration,
    List<LatLng>? points,
  }) {
    return TripState(
      isTripStarted: isTripStarted ?? this.isTripStarted,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      points: points ?? this.points,
    );
  }
}

/// ViewModel for Today Visit / Trip tracking
class TodayVisitViewmodel extends AsyncNotifier<TripState?> {
  late final ClientRepository repo;

  StreamSubscription<Position>? _positionStream;
  Timer? _durationTimer;
  List<LatLng> trackedPoints = [];
  DateTime? _tripStartTime;

  // Saved trip start/end locations
  LatLng? tripStartLocation;
  LatLng? tripEndLocation;

  @override
  Future<TripState?> build() async {
    repo = ref.read(repositoryProvider);

    // Cancel stream & timer when provider is disposed
    ref.onDispose(() {
      _positionStream?.cancel();
      _durationTimer?.cancel();
    });

    return null;
  }

  /// Get current location with permission checks
  Future<Position?> getLocationSafely() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // 🔹 First time ask
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return null; // ❌ user denied
      }
    }

    // 🔹 Permanently denied
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return null;
    }

    // ✅ Permission granted
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Start trip tracking from a given point
  Future<void> startTracking(LatLng startPoint) async {
    trackedPoints = [startPoint];
    _tripStartTime = DateTime.now();

    // Initialize state
    state = AsyncData(
      TripState(
        isTripStarted: true,
        distance: 0,
        duration: 0,
        points: List.from(trackedPoints),
      ),
    );

    // Cancel any previous tracking
    await _positionStream?.cancel();
    _durationTimer?.cancel();

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.value != null && _tripStartTime != null) {
        final duration = DateTime.now().difference(_tripStartTime!).inSeconds;
        state = AsyncData(state.value!.copyWith(duration: duration));
      }
    });

    // Listen to position updates (every 5 meters)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      trackedPoints.add(point);

      final totalDistance = _calculateTotalDistance(trackedPoints);
      final duration = _tripStartTime != null
          ? DateTime.now().difference(_tripStartTime!).inSeconds
          : 0;

      state = AsyncData(
        TripState(
          isTripStarted: true,
          distance: totalDistance,
          duration: duration,
          points: List.from(trackedPoints),
        ),
      );
    });
  }

  /// Stop trip tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _tripStartTime = null;
  }

  /// Calculate cumulative distance in km
  double _calculateTotalDistance(List<LatLng> points) {
    if (points.length < 2) return 0;
    const Distance distance = Distance();
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, points[i], points[i + 1]);
    }
    return total;
  }

  /// Manage trip: start or end
  Future<bool> manageTrip(String type) async {
    try {
      final loginData = ref.read(loginProvider).value;

      if (loginData == null) {
        throw Exception("User not logged in");
      }

      final position = await getLocationSafely();

      if (position == null) {
        return false;
      }

      final latLng = LatLng(
        position.latitude,
        position.longitude,
      );

      final response = await repo.manageTrip(
        position.latitude.toString(),
        position.longitude.toString(),
        type,
        loginData.userId.toString(),
      );

      print("ManageTrip Response => $response");

      final backendStatus = response["status"];
      final result = response["result"]?.toString();

      // Success condition for both start & stop
      final isSuccess = backendStatus == 1 || result == "1";

      if (!isSuccess) {
        return false;
      }

      if (type == "start") {
        tripStartLocation = latLng;
        await startTracking(latLng);

        state = AsyncData(
          state.value?.copyWith(
            isTripStarted: true,
          ),
        );

        return true;
      }

      if (type == "stop") {
        tripEndLocation = latLng;

        stopTracking();

        state = AsyncData(
          state.value?.copyWith(
            isTripStarted: false,
            distance: _calculateTotalDistance(trackedPoints),
          ),
        );

        return true;
      }

      return false;
    } catch (e, st) {
      print("ManageTrip Error => $e");
      print("StackTrace => $st");

      state = AsyncError(e, st);
      return false;
    }
  }

  /// Submit a visit record
  Future<bool> submitVisitRecord({
    required String schoolName,
    required String area,
    required String district,
    required String personName,
    required String contactNumber,
    required String remarks,
    required String reasonOfVisit,
    required String personMet,
    required String dateOfVisit,
  }) async {
    try {
      final loginData = ref.read(loginProvider).value;
      if (loginData == null) throw Exception("User not logged in");

      final position = await getLocationSafely();
      if (position == null) return false;

      final visitData = [
        {
          "login_id": loginData.userId.toString(),
          "school_name": schoolName,
          "area": area,
          "district": district,
          "person_name": personName,
          "contact_number": contactNumber,
          "remarks": remarks,
          "reason_of_visit": reasonOfVisit,
          "person_met": personMet,
          "date_of_visit": dateOfVisit,
          "latitude": position.latitude,
          "longitude": position.longitude,
        }
      ];

      final response = await repo.visitRecord(visitData);

      // Safe access — no implicit dynamic cast
      if (response.isEmpty) return false;
      return response.first["result"] == "1";

    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Fetch OSRM route between two points
  Future<void> getRoute({required LatLng start, required LatLng end}) async {
    state = const AsyncLoading();
    try {
      final url = "http://router.project-osrm.org/route/v1/driving/"
          "${start.longitude},${start.latitude};"
          "${end.longitude},${end.latitude}"
          "?overview=full&geometries=geojson";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Route fetch failed");

      final data = json.decode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) throw Exception("No route found");

      final route = routes[0];
      final coords = route['geometry']['coordinates'] as List;
      final osrmPoints = coords.map<LatLng>((c) {
        return LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble());
      }).toList();

      state = AsyncData(
        TripState(
          isTripStarted: false,
          distance: (route['distance'] as num).toDouble() / 1000,
          duration: ((route['duration'] as num).toDouble() / 60).round(),
          points: osrmPoints,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider
final todayVisitProvider =
AsyncNotifierProvider<TodayVisitViewmodel, TripState?>(
  TodayVisitViewmodel.new,
);