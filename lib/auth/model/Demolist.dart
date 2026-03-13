class Demolist {
  final String schoolName;
  final int principalNumber;
  final int demoId;

  Demolist({
    required this.schoolName,
    required this.principalNumber,
    required this.demoId,
  });

  factory Demolist.fromJson(Map<String, dynamic> json) {
    return Demolist(
      schoolName: json["SchoolName"] ?? "",
      principalNumber: json["PrincipalNumber"] ?? 0,
      demoId: json["DemoId"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "SchoolName": schoolName,
    "PrincipalNumber": principalNumber,
    "DemoId": demoId,
  };
}
