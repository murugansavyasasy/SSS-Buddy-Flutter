class Managementinfo {
  final String memberName;
  final String appPassword;
  final String memberType;
  final String designation;
  final String ivrPassword;
  final String mobileNumber;
  final int memberId;

  Managementinfo({
    required this.memberName,
    required this.appPassword,
    required this.memberType,
    required this.designation,
    required this.ivrPassword,
    required this.mobileNumber,
    required this.memberId,
  });

  factory Managementinfo.fromJson(Map<String, dynamic> json) {
    return Managementinfo(
      memberName:   json["MemberName"]   ?? "",
      appPassword:  json["AppPassword"]  ?? "",
      memberType:   json["MemberType"]   ?? "",
      designation:  json["Designation"]  ?? "",
      ivrPassword:  json["IVRPassword"]  ?? "",
      mobileNumber: json["MobileNumber"] ?? "",
      memberId:     json["MemberId"]     ?? 0,
    );
  }
}