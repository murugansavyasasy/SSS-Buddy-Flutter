import 'dart:ffi';

class Validatelogin {
  String VimsIdUser;
  String VimsUserName;
  String VimsEmployeeId;
  String VimsUserTypeId;
  String SchooluserType;
  String SchoolLoginId;
  String VimsNumber;
  String Location;
  String Region;
  int result;
  String SchoolStatus;
  String resultMessage;

  Validatelogin({
    required this.VimsIdUser,
    required this.VimsUserName,
    required this.VimsEmployeeId,
    required this.VimsUserTypeId,
    required this.SchooluserType,
    required this.SchoolLoginId,
    required this.VimsNumber,
    required this.Location,
    required this.Region,
    required this.result,
    required this.SchoolStatus,
    required this.resultMessage,
  });

  factory Validatelogin.fromJson(Map<String, dynamic> json) {
    return Validatelogin(
      VimsIdUser: json["VimsIdUser"] ?? "",
      VimsUserName: json["VimsUserName"] ?? "",
      VimsEmployeeId: json["VimsEmployeeId"] ?? "",
      VimsUserTypeId: json["VimsUserTypeId"] ?? "",
      SchooluserType: json["SchooluserType"] ?? "",
      SchoolLoginId: json["SchoolLoginId"] ?? "",
      VimsNumber: json["VimsNumber"] ?? "",
      Location: json["Location"] ?? "",
      Region: json["Region"] ?? "",
      result: json["result"] ?? 0,
      SchoolStatus: json["SchoolStatus"] ?? "",
      resultMessage: json["resultMessage"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
    "VimsIdUser": VimsIdUser,
    "VimsUserName": VimsUserName,
    "VimsEmployeeId": VimsEmployeeId,
    "VimsUserTypeId": VimsUserTypeId,
    "SchooluserType": SchooluserType,
    "SchoolLoginId": SchoolLoginId,
    "VimsNumber": VimsNumber,
    "Location": Location,
    "Region": Region,
    "result": result,
    "SchoolStatus": SchoolStatus,
    "resultMessage": resultMessage,
  };
}