class Createdemoresponse {
  final int status;
  final String message;
  final String reason;
  final int demoId;

  Createdemoresponse({
    required this.status,
    required this.message,
    required this.reason,
    required this.demoId,
  });

  factory Createdemoresponse.fromJson(Map<String, dynamic> json) {
    return Createdemoresponse(
      status: json["Status"] ?? 0,
      message: json["Message"] ?? "",
      reason: json["Reason"] ?? "",
      demoId: json["DemoID"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "Status": status,
    "Message": message,
    "Reason": reason,
    "DemoID": demoId,
  };
}
