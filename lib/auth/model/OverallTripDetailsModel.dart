import 'dart:math' as math;

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

  factory Overalltripdetailsmodel.fromJson(Map<String, dynamic> json) {
    final visits = (json["visit_details"] as List<dynamic>? ?? [])
        .map((item) => VisitDetail.fromJson(item as Map<String, dynamic>))
        .toList();

    return Overalltripdetailsmodel(
      status: json["status"] ?? 0,
      message: json["message"] ?? '',
      trip_id: json["trip_id"] ?? 0,
      username: json["username"] ?? '',
      start_time: json["start_time"] ?? '',
      start_latitude: json["start_latitude"] ?? '',
      start_longitude: json["start_longitude"] ?? '',
      end_time: json["end_time"],
      end_latitude: json["end_latitude"],
      end_longitude: json["end_longitude"],
      is_closed: json["is_closed"] ?? 0,
      visit_details: visits,
      totalDistanceKm: DistanceCalculator.totalApproximateRoadDistance(
        _buildPoints(
          json["start_latitude"] ?? '',
          json["start_longitude"] ?? '',
          json["end_latitude"],
          json["end_longitude"],
          visits,
        ),
      ),
    );
  }

  /// Mirrors the Android adapter's point-building logic exactly:
  /// start -> each visit (if lat & lng both present) -> end (if present).
  /// No sanitization — matches TripDetailsAdapter.onBindViewHolder as-is.
  static List<List<double>> _buildPoints(
      String startLatStr,
      String startLonStr,
      String? endLatStr,
      String? endLonStr,
      List<VisitDetail> visits,
      ) {
    final List<List<double>> points = [];

    try {
      final startLat = DistanceCalculator.parseCoordinate(startLatStr);
      final startLon = DistanceCalculator.parseCoordinate(startLonStr);
      points.add([startLat, startLon]);
    } catch (e) {
      return []; // matches Android: if start missing, no distance shown
    }

    for (var visit in visits) {
      if (visit.school_latitude != null &&
          visit.school_longitude != null &&
          visit.school_latitude!.isNotEmpty &&
          visit.school_longitude!.isNotEmpty) {
        try {
          final lat = DistanceCalculator.parseCoordinate(visit.school_latitude!);
          final lon = DistanceCalculator.parseCoordinate(visit.school_longitude!);
          points.add([lat, lon]);
        } catch (e) {
          // skip invalid visit point, same as Android silently skipping
        }
      }
    }

    if (endLatStr != null &&
        endLonStr != null &&
        endLatStr.isNotEmpty &&
        endLonStr.isNotEmpty) {
      try {
        final endLat = DistanceCalculator.parseCoordinate(endLatStr);
        final endLon = DistanceCalculator.parseCoordinate(endLonStr);
        points.add([endLat, endLon]);
      } catch (e) {
        // skip invalid end point
      }
    }

    return points;
  }
}

class VisitDetail {
  String? school_latitude;
  String? school_longitude;
  String? school_name;
  String? person_name;
  String? reason_of_visit;
  String? remarks;

  VisitDetail({
    this.school_latitude,
    this.school_longitude,
    this.school_name,
    this.person_name,
    this.reason_of_visit,
    this.remarks,
  });

  factory VisitDetail.fromJson(Map<String, dynamic> json) {
    return VisitDetail(
      school_latitude: json["school_latitude"] as String?,
      school_longitude: json["school_longitude"] as String?,
      school_name: json["school_name"] as String?,
      person_name: json["person_name"] as String?,
      reason_of_visit: json["reason_of_visit"] as String?,
      remarks: json["remarks"] as String?,
    );
  }
}

class DistanceCalculator {
  static double distanceBetween(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371e3;
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaPhi = _toRadians(lat2 - lat1);
    final deltaLambda = _toRadians(lon2 - lon1);

    final a = math.sin(deltaPhi / 2) * math.sin(deltaPhi / 2) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(deltaLambda / 2) *
            math.sin(deltaLambda / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double totalApproximateRoadDistance(List<List<double>> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      totalDistance += distanceBetween(p1[0], p1[1], p2[0], p2[1]);
    }

    final distanceKm = totalDistance / 1000.0;
    const double roadMultiplier = 1.3;
    return distanceKm * roadMultiplier;
  }

  static double parseCoordinate(String coord) {
    if (coord.isEmpty) {
      throw ArgumentError("Coordinate is null or empty");
    }
    coord = coord.trim();

    final upper = coord.toUpperCase();
    if (coord.contains("°") ||
        upper.contains("N") ||
        upper.contains("S") ||
        upper.contains("E") ||
        upper.contains("W")) {
      coord = coord.replaceAll("°", "").trim();
      final parts = coord.split(RegExp(r'\s+'));
      double value = double.parse(parts[0]);
      if (parts.length > 1) {
        final dir = parts[1].toUpperCase();
        if (dir == "S" || dir == "W") {
          value = -value;
        }
      }
      return value;
    } else {
      return double.parse(coord);
    }
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180);
}