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

  factory Overalltripdetailsmodel.fromJson(Map<String,dynamic> json) {
    return Overalltripdetailsmodel(
      status: json["status"],
      message: json["message"],
      trip_id: json["trip_id"],
      username: json["username"],
      start_time: json["start_time"],
      start_latitude: json["start_latitude"],
      start_longitude: json["start_longitude"],
      end_time: json["end_time"],
      end_latitude: json["end_latitude"],
      end_longitude: json["end_longitude"],
      is_closed: json["is_closed"],
      visit_details: json["visit_details"],
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
    required this.school_latitude,
    required this.school_longitude,
    required this.school_name,
    required this.person_name,
    required this.reason_of_visit,
    required this.remarks,
  });

  factory VisitDetail.fromJson(Map<String,dynamic> json) {
    return VisitDetail(
      school_latitude: json["school_latitude"],
      school_longitude: json["school_longitude"],
      school_name: json["school_name"],
      person_name: json["person_name"],
      reason_of_visit: json["reason_of_visit"],
      remarks: json["remarks"],
    );
  }

}