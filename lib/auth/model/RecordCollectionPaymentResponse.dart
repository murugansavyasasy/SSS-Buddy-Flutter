class Recordcollectionpaymentresponse {
  String message;
  String status;
  String reason;

  Recordcollectionpaymentresponse({
    required this.message,
    required this.status,
    required this.reason,
  });

  factory Recordcollectionpaymentresponse.fromJson(Map<String, dynamic> json) {
    return Recordcollectionpaymentresponse(
      message: json["message"],
      status: json["status"],
      reason: json["reason"],
    );
  }
}
