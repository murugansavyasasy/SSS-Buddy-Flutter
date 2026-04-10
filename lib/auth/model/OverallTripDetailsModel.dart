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
      totalDistanceKm: _calculateTotalDistance(
        json["start_latitude"] ?? '',
        json["start_longitude"] ?? '',
        json["end_latitude"],
        json["end_longitude"],
        visits,
      ),
    );
  }



  static const bool AUTO_FIX_SUSPICIOUS_COORDS = true;
  static const double SAME_LAT_LNG_EPS = 1e-6;
  static const double LONGITUDE_JUMP_DEGREES = 5.0;

  static double _calculateTotalDistance(
      String startLatStr,
      String startLonStr,
      String? endLatStr,
      String? endLonStr,
      List<VisitDetail> visits,
      ) {
    final startLat = _parseCoordinate(startLatStr);
    final startLon = _parseCoordinate(startLonStr);

    if (!_isValidCoordinate(startLat, startLon)) {
      return 0.0;
    }

    final endLat = endLatStr != null ? _parseCoordinate(endLatStr) : double.nan;
    final endLon = endLonStr != null ? _parseCoordinate(endLonStr) : double.nan;

    final List<(double, double)> points = [];
    points.add((startLat, startLon));

    double prevLat = startLat;
    double prevLon = startLon;

    for (var visit in visits) {
      final rawLat = _parseCoordinate(visit.school_latitude ?? '');
      final rawLon = _parseCoordinate(visit.school_longitude ?? '');

      final fixed = _sanitizeSchoolPoint(
        prevLat,
        prevLon,
        endLon,
        rawLat,
        rawLon,
      );

      if (_isValidCoordinate(fixed[0], fixed[1])) {
        points.add((fixed[0], fixed[1]));
        prevLat = fixed[0];
        prevLon = fixed[1];
      }
    }

    if (_isValidCoordinate(endLat, endLon)) {
      points.add((endLat, endLon));
    }

    if (points.length < 2) return 0.0;

    double totalKm = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalKm += _haversineKm(
        points[i].$1,
        points[i].$2,
        points[i + 1].$1,
        points[i + 1].$2,
      );
    }

    return totalKm;
  }

  static double _parseCoordinate(String? coord) {
    if (coord == null) return double.nan;
    String s = coord.trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return double.nan;

    try {
      final isSouth = s.toUpperCase().contains('S');
      final isWest = s.toUpperCase().contains('W');

      s = s.replaceAll('°', ' ').replaceAll('º', ' ').replaceAll(',', ' ').trim();
      s = s.replaceAll(RegExp(r'[^0-9+\-\.]'), '');

      if (s.isEmpty) return double.nan;

      double value = double.parse(s);
      if (isSouth || isWest) value = -value;
      return value;
    } catch (e) {
      return double.nan;
    }
  }

  static bool _isValidLat(double lat) =>
      !lat.isNaN && lat >= -90 && lat <= 90;

  static bool _isValidLng(double lng) =>
      !lng.isNaN && lng >= -180 && lng <= 180;

  static bool _isValidCoordinate(double lat, double lng) =>
      _isValidLat(lat) && _isValidLng(lng);

  static List<double> _sanitizeSchoolPoint(
      double prevLat,
      double prevLng,
      double endLng,
      double schoolLat,
      double schoolLng,
      ) {
    if (!_isValidLat(schoolLat)) {
      return [double.nan, double.nan];
    }

    if (!_isValidLng(schoolLng)) {
      if (_isValidLng(prevLng)) return [schoolLat, prevLng];
      if (_isValidLng(endLng)) return [schoolLat, endLng];
      return [double.nan, double.nan];
    }

    if (!AUTO_FIX_SUSPICIOUS_COORDS) {
      return _isValidCoordinate(schoolLat, schoolLng)
          ? [schoolLat, schoolLng]
          : [double.nan, double.nan];
    }

    final latEqualsLng = (schoolLat - schoolLng).abs() <= SAME_LAT_LNG_EPS;
    final lonJumpPrev = _isValidLng(prevLng) &&
        (schoolLng - prevLng).abs() > LONGITUDE_JUMP_DEGREES;
    final lonJumpEnd = _isValidLng(endLng) &&
        (schoolLng - endLng).abs() > LONGITUDE_JUMP_DEGREES;

    if (latEqualsLng || (lonJumpPrev && lonJumpEnd)) {
      if (_isValidLng(prevLng)) return [schoolLat, prevLng];
      if (_isValidLng(endLng)) return [schoolLat, endLng];
      return [double.nan, double.nan];
    }

    return [schoolLat, schoolLng];
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371.0;
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
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