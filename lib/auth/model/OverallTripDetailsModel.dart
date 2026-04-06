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
  List<VisitDetail> visit_details;   // ← this stays the same

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
  });

  factory Overalltripdetailsmodel.fromJson(Map<String, dynamic> json) {
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
      // ✅ THIS WAS THE MISSING PART
      visit_details: (json["visit_details"] as List<dynamic>? ?? [])
          .map((item) => VisitDetail.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
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