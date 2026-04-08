class Initiatedemocall {
  String message;
  String status;
  String reason;

  Initiatedemocall({
    required this.message,
    required this.status,
    required this.reason,
  });

  factory Initiatedemocall.fromJson(Map<String, dynamic> json) {
    return Initiatedemocall(
      message: json["Message"] ?? "",
      status: json["Status"] ?? "",
      reason: json["Reason"] ?? "",
    );
  }
}