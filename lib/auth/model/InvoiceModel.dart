class Invoicemodel {
  String InvoiceId;
  String InvoiceNumber;
  String PendingAmount;

  Invoicemodel({
    required this.InvoiceId,
    required this.InvoiceNumber,
    required this.PendingAmount,
  });
  factory Invoicemodel.fromJson(Map<String, dynamic> json) {
    return Invoicemodel(
      InvoiceId: json["InvoiceId"],
      InvoiceNumber: json["InvoiceNumber"],
      PendingAmount: json["PendingAmount"],
    );
  }
}
