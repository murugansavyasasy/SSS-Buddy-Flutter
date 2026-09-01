import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Overalltripdetailsmodel {
  int status;
  String message;
  int trip_id;
  String username;
  String start_time;
  String start_latitude;
  String start_longitude;
  String? end_time;
  String? end_latitude;
  String? end_longitude;
  int is_closed;

  List<VisitDetail> visit_details;

  double totalDistanceKm;

  Overalltripdetailsmodel({
    required this.status,
    required this.message,
    required this.trip_id,
    required this.username,
    required this.start_time,
    required this.start_latitude,
    required this.start_longitude,
    required this.end_time,
    required this.end_latitude,
    required this.end_longitude,
    required this.is_closed,
    required this.visit_details,
    required this.totalDistanceKm,
  });

  factory Overalltripdetailsmodel.fromJson(
      Map<String, dynamic> json,
      ) {
    final visits =
    (json["visit_details"] as List<dynamic>? ?? [])
        .map(
          (item) => VisitDetail.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();

    return Overalltripdetailsmodel(
      status: json["status"] ?? 0,
      message: json["message"]?.toString() ?? '',
      trip_id: json["trip_id"] ?? 0,
      username: json["username"]?.toString() ?? '',
      start_time: json["start_time"]?.toString() ?? '',

      start_latitude:
      json["start_latitude"]?.toString() ?? '',

      start_longitude:
      json["start_longitude"]?.toString() ?? '',

      end_time:
      json["end_time"]?.toString(),

      end_latitude:
      json["end_latitude"]?.toString(),

      end_longitude:
      json["end_longitude"]?.toString(),

      is_closed: json["is_closed"] ?? 0,

      visit_details: visits,

      totalDistanceKm:
      DistanceCalculator.totalApproximateRoadDistance(
        _buildPoints(
          json["start_latitude"]?.toString() ?? '',
          json["start_longitude"]?.toString() ?? '',
          json["end_latitude"]?.toString(),
          json["end_longitude"]?.toString(),
          visits,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD DISTANCE POINTS
  // ============================================================

  static List<List<double>> _buildPoints(
      String startLatStr,
      String startLonStr,
      String? endLatStr,
      String? endLonStr,
      List<VisitDetail> visits,
      ) {
    final List<List<double>> points = [];

    // START
    try {
      final startLat =
      DistanceCalculator.parseCoordinate(startLatStr);

      final startLon =
      DistanceCalculator.parseCoordinate(startLonStr);

      points.add([
        startLat,
        startLon,
      ]);
    } catch (_) {
      return [];
    }

    // VISITS
    for (final visit in visits) {
      if (visit.school_latitude != null &&
          visit.school_longitude != null &&
          visit.school_latitude!.isNotEmpty &&
          visit.school_longitude!.isNotEmpty) {
        try {
          final lat =
          DistanceCalculator.parseCoordinate(
            visit.school_latitude!,
          );

          final lon =
          DistanceCalculator.parseCoordinate(
            visit.school_longitude!,
          );

          points.add([
            lat,
            lon,
          ]);
        } catch (_) {
          // Invalid coordinate
        }
      }
    }

    // END
    if (endLatStr != null &&
        endLonStr != null &&
        endLatStr.isNotEmpty &&
        endLonStr.isNotEmpty) {
      try {
        final endLat =
        DistanceCalculator.parseCoordinate(
          endLatStr,
        );

        final endLon =
        DistanceCalculator.parseCoordinate(
          endLonStr,
        );

        points.add([
          endLat,
          endLon,
        ]);
      } catch (_) {
      }
    }

    return points;
  }
}
// ============================================================
// VISIT DETAIL
// ============================================================

class VisitDetail {
  String? school_latitude;
  String? school_longitude;

  String? school_name;
  String? person_name;
  String? reason_of_visit;
  String? remarks;
  String? address;

  VisitDetail({
    this.school_latitude,
    this.school_longitude,
    this.school_name,
    this.person_name,
    this.reason_of_visit,
    this.remarks,
    this.address,
  });

  factory VisitDetail.fromJson(
      Map<String, dynamic> json,
      ) {
    return VisitDetail(
      school_latitude:
      json["school_latitude"]?.toString(),

      school_longitude:
      json["school_longitude"]?.toString(),

      school_name:
      json["school_name"]?.toString(),

      person_name:
      json["person_name"]?.toString(),

      reason_of_visit:
      json["reason_of_visit"]?.toString(),

      remarks:
      json["remarks"]?.toString(),

      address: null,
    );
  }

  double? get latitude {
    if (school_latitude == null ||
        school_latitude!.trim().isEmpty) {
      return null;
    }

    try {
      return DistanceCalculator.parseCoordinate(
        school_latitude!,
      );
    } catch (_) {
      return null;
    }
  }

  double? get longitude {
    if (school_longitude == null ||
        school_longitude!.trim().isEmpty) {
      return null;
    }

    try {
      return DistanceCalculator.parseCoordinate(
        school_longitude!,
      );
    } catch (_) {
      return null;
    }
  }
}


// ============================================================
// DISTANCE CALCULATOR
// ============================================================

class DistanceCalculator {

  static double distanceBetween(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double R = 6371e3;

    final phi1 =
    _toRadians(lat1);

    final phi2 =
    _toRadians(lat2);

    final deltaPhi =
    _toRadians(lat2 - lat1);

    final deltaLambda =
    _toRadians(lon2 - lon1);

    final a =
        math.sin(deltaPhi / 2) *
            math.sin(deltaPhi / 2) +
            math.cos(phi1) *
                math.cos(phi2) *
                math.sin(deltaLambda / 2) *
                math.sin(deltaLambda / 2);

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return R * c;
  }

  static double totalApproximateRoadDistance(
      List<List<double>> points,
      ) {
    if (points.length < 2) {
      return 0.0;
    }

    double totalDistance = 0;

    for (int i = 0;
    i < points.length - 1;
    i++) {

      final p1 = points[i];
      final p2 = points[i + 1];

      totalDistance += distanceBetween(
        p1[0],
        p1[1],
        p2[0],
        p2[1],
      );
    }

    final distanceKm =
        totalDistance / 1000.0;

    // Approximate road distance
    const double roadMultiplier = 1.3;

    return distanceKm * roadMultiplier;
  }

  static double parseCoordinate(
      String coord,
      ) {
    if (coord.trim().isEmpty) {
      throw ArgumentError(
        "Coordinate is null or empty",
      );
    }

    coord = coord.trim();

    final upper =
    coord.toUpperCase();

    if (coord.contains("°") ||
        upper.contains("N") ||
        upper.contains("S") ||
        upper.contains("E") ||
        upper.contains("W")) {

      coord =
          coord.replaceAll("°", "").trim();

      final parts =
      coord.split(RegExp(r'\s+'));

      double value =
      double.parse(parts[0]);

      if (parts.length > 1) {
        final direction =
        parts[1].toUpperCase();

        if (direction == "S" ||
            direction == "W") {
          value = -value;
        }
      }

      return value;
    }

    return double.parse(coord);
  }

  static double _toRadians(
      double degrees,
      ) {
    return degrees *
        (math.pi / 180);
  }
}


// ============================================================
// ADDRESS SERVICE
// ============================================================

class AddressService {

  static Future<String> getAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'json',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'SSSBuddyFlutterApp/1.0 (contact@yourapp.com)',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () => http.Response('TIMEOUT', 408),
      );

      if (response.statusCode == 429) {
        print('🚫 Nominatim rate-limited us [$latitude,$longitude]');
        return "Address unavailable";
      }

      if (response.statusCode != 200) {
        print('⚠️ Address lookup non-200 [$latitude,$longitude] → ${response.statusCode}');
        return "Address unavailable";
      }

      final data = jsonDecode(response.body);
      final displayName = data["display_name"];

      if (displayName != null && displayName.toString().trim().isNotEmpty) {
        return displayName.toString();
      }

      return "Address unavailable";
    } catch (e) {
      print('❌ Address lookup error [$latitude,$longitude]: $e');
      return "Address unavailable";
    }
  }
}


// ============================================================
// TRIP ADDRESS LOADER (single-coordinate, cached)
// ============================================================

class TripAddressLoader {

  static String cacheKey(double lat, double lon) {
    final latKey = lat.toStringAsFixed(5);
    final lonKey = lon.toStringAsFixed(5);
    return 'address_cache_${latKey}_$lonKey';
  }
  static Future<String> getCachedAddress({
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = cacheKey(latitude, longitude);

    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final address = await AddressService.getAddress(
      latitude: latitude,
      longitude: longitude,
    );

    if (address != "Address unavailable") {
      await prefs.setString(key, address);
    }

    return address;
  }
}