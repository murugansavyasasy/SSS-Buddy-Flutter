import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../auth/model/TodayVisitModal.dart';
import '../auth/model/TrackPointModel.dart';
import '../core/location/trip_track_store.dart';
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

  // ── Root Tracker: persisted + uploaded breadcrumb log ──
  /// Every point recorded today (all segments), for the Root Tracker map.
  List<TrackPoint> trackLog = [];
  int? _trackUserId;
  String? _trackDay;
  int _segment = 0;
  int _uploadedCount = 0;
  bool _uploading = false;
  bool _dirty = false;
  DateTime _lastUpload = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _syncTimer;

  /// GPS fixes worse than this are ignored (metres).
  static const double _maxAccuracyM = 50;
  /// Jumps faster than this between two fixes are treated as GPS glitches.
  static const double _maxSpeedKmh = 180;
  static const int _uploadBatch = 20;
  static const Duration _uploadEvery = Duration(minutes: 2);

  bool get isTracking => _positionStream != null;

  @override
  Future<TripState?> build() async {
    repo = ref.read(repositoryProvider);

    // Cancel stream & timer when provider is disposed
    ref.onDispose(() {
      _positionStream?.cancel();
      _durationTimer?.cancel();
      _syncTimer?.cancel();
    });

    return null;
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        // Foreground service keeps GPS alive with the screen off.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Trip in progress",
          notificationText: "SSS Buddy is recording your route",
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  /// Adds a fix to [trackLog] unless it is GPS noise. Returns true if kept.
  bool _recordPoint(LatLng p, {double? accuracy, bool force = false}) {
    final point = TrackPoint(
      lat: p.latitude,
      lng: p.longitude,
      time: DateTime.now(),
      segment: _segment,
    );

    if (!force) {
      if (accuracy != null && accuracy > _maxAccuracyM) return false;
      final last = trackLog.isNotEmpty ? trackLog.last : null;
      if (last != null && last.segment == _segment) {
        final meters = TrackPoint.metersBetween(last, point);
        if (meters < 8) return false;
        final secs = point.time.difference(last.time).inMilliseconds / 1000;
        if (secs > 0 && (meters / 1000) / (secs / 3600) > _maxSpeedKmh) {
          return false;
        }
      }
    }

    trackLog.add(point);
    _dirty = true;
    return true;
  }

  /// Saves to the phone and uploads pending points when a batch is ready.
  Future<void> _sync({bool force = false}) async {
    final userId = _trackUserId;
    final day = _trackDay;
    if (userId == null || day == null) return;

    if (_dirty) {
      _dirty = false;
      try {
        await TripTrackStore.save(userId, day, trackLog);
      } catch (e) {
        _dirty = true;
        print("TripTrackStore save Error => $e");
      }
    }

    if (_uploading || _uploadedCount >= trackLog.length) return;
    final pending = trackLog.sublist(_uploadedCount);
    final due = force ||
        pending.length >= _uploadBatch ||
        DateTime.now().difference(_lastUpload) >= _uploadEvery;
    if (!due) return;

    _uploading = true;
    _lastUpload = DateTime.now();
    try {
      final ok = await repo.saveTripLocations(
        userId: userId.toString(),
        tripDate: day,
        points: pending,
      );
      if (ok) {
        _uploadedCount += pending.length;
        await TripTrackStore.setUploadedCount(userId, day, _uploadedCount);
      }
    } catch (e) {
      // Offline or API not live yet – points stay queued on the phone.
      print("SaveTripLocations Error => $e");
    } finally {
      _uploading = false;
    }
  }

  /// Loads today's stored log so a new segment can be appended to it.
  Future<void> _openTodayLog() async {
    final loginData = ref.read(loginProvider).value;
    if (loginData == null) return;
    final day = TripTrackStore.dayKey(DateTime.now());
    if (_trackUserId == loginData.userId && _trackDay == day) return;

    _trackUserId = loginData.userId;
    _trackDay = day;
    trackLog = await TripTrackStore.load(loginData.userId, day);
    _uploadedCount = await TripTrackStore.uploadedCount(loginData.userId, day);
    if (_uploadedCount > trackLog.length) _uploadedCount = trackLog.length;
    _segment = trackLog.isEmpty ? 0 : trackLog.last.segment;
    unawaited(TripTrackStore.pruneOld());
  }

  /// Called when Today Visit opens and the server says today's trip is
  /// still running: restarts GPS tracking after an app restart.
  Future<void> resumeTrackingIfNeeded() async {
    if (isTracking) return;
    await _openTodayLog();

    final current = trackLog.where((p) => p.segment == _segment).toList();
    LatLng? start = current.isNotEmpty ? current.first.latLng : null;
    if (start == null) {
      final pos = await getLocationSafely();
      if (pos == null) return;
      start = LatLng(pos.latitude, pos.longitude);
    }
    tripStartLocation = start;
    await startTracking(start, resume: true);
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

  /// Start trip tracking from a given point.
  /// [resume] continues the current segment instead of starting a new one.
  Future<void> startTracking(LatLng startPoint, {bool resume = false}) async {
    await _openTodayLog();

    if (resume) {
      final current = trackLog.where((p) => p.segment == _segment).toList();
      trackedPoints = current.map((p) => p.latLng).toList();
      if (trackedPoints.isEmpty) {
        trackedPoints = [startPoint];
        _recordPoint(startPoint, force: true);
      }
      _tripStartTime = current.isNotEmpty ? current.first.time : DateTime.now();
    } else {
      if (trackLog.isNotEmpty) _segment = trackLog.last.segment + 1;
      trackedPoints = [startPoint];
      _recordPoint(startPoint, force: true);
      _tripStartTime = DateTime.now();
    }
    await _sync(force: true);

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) => _sync());

    // Initialize state
    state = AsyncData(
      TripState(
        isTripStarted: true,
        distance: _calculateTotalDistance(trackedPoints),
        duration: DateTime.now().difference(_tripStartTime!).inSeconds,
        points: List.from(trackedPoints),
      ),
    );

    // Cancel any previous tracking
    await _positionStream?.cancel();
    _positionStream = null;
    _durationTimer?.cancel();

    // Start duration timer
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.value != null && _tripStartTime != null) {
        final duration = DateTime.now().difference(_tripStartTime!).inSeconds;
        state = AsyncData(state.value!.copyWith(duration: duration));
      }
    });

    // Listen to position updates (every ~10 metres, also in background)
    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen((Position pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      if (!_recordPoint(point, accuracy: pos.accuracy)) return;
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
    _syncTimer?.cancel();
    _syncTimer = null;
    _tripStartTime = null;
    unawaited(_sync(force: true));
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

  /// True if the logged-in user has a trip started today whose end_time is
  /// still null (trip not ended). Throws if the API call fails.
  Future<bool> hasOpenTripToday() async {
    final loginData = ref.read(loginProvider).value;
    if (loginData == null) throw Exception("User not logged in");

    final trips = await ref
        .read(repositoryProvider)
        .getoveralldetails(loginData.token, loginData.userId.toString());

    final now = DateTime.now();
    return trips.any((trip) {
      final start = trip.startDateTime;
      final isToday = start != null &&
          start.year == now.year &&
          start.month == now.month &&
          start.day == now.day;
      final endTime = trip.end_time?.trim();
      final isOpen =
          endTime == null || endTime.isEmpty || endTime.toLowerCase() == "null";
      return isToday && isOpen;
    });
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
        await _openTodayLog();
        if (_recordPoint(latLng, accuracy: position.accuracy)) {
          trackedPoints.add(latLng);
        }

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
      return response.first["result"].toString() == "1";

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