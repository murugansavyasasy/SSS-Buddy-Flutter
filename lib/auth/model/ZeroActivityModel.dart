class Zeroactivitymodel {
  final int instituteId;
  final String instituteName;
  final String lastWebLogin;
  final String lastAppLogin;
  final String salesPerson;
  final String instituteStatus;

  Zeroactivitymodel({
    required this.instituteId,
    required this.instituteName,
    required this.lastWebLogin,
    required this.lastAppLogin,
    required this.salesPerson,
    required this.instituteStatus,
  });

  factory Zeroactivitymodel.fromJson(Map<String, dynamic> json) {
    return Zeroactivitymodel(
      instituteId: json['institute_id'] ?? 0,
      instituteName: json['institude_name'] ?? '',
      lastWebLogin: json['last_web_login'] ?? '',
      lastAppLogin: json['last_app_login'] ?? '',
      salesPerson: json['sales_person'] ?? '',
      instituteStatus: json['institute_status'] ?? '',
    );
  }

  String get displayStatus {
    return instituteStatus == "LIVE" ? "Active" : "Inactive";
  }
}