class Demolist {
  final String schoolName;
  final int principalNumber;
  final int demoId;
  final int DemoID;

  Demolist({
    required this.schoolName,
    required this.principalNumber,
    required this.demoId,
    required this.DemoID,
  });

  factory Demolist.fromJson(Map<String, dynamic> json) {
    return Demolist(
      schoolName: json["SchoolName"] ?? "",
      principalNumber: json["PrincipalNumber"] ?? 0,
      demoId: json["DemoId"] ?? 0,
      DemoID: json["DemoID"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "SchoolName": schoolName,
    "PrincipalNumber": principalNumber,
    "DemoId": demoId,
    "DemoID": DemoID,
  };
}
