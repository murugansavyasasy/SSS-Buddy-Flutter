class Invoicemodel {
  String invoiceId;
  String invoiceNumber;
  String pendingAmount;

  Invoicemodel({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.pendingAmount,
  });
  factory Invoicemodel.fromJson(Map<String, dynamic> json) {
    return Invoicemodel(
      invoiceId: json["invoiceId"],
      invoiceNumber: json["invoiceNumber"],
      pendingAmount: json["pendingAmount"],
    );
  }
}
