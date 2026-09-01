class RenewalPOResponse {
  final String status;
  final List<RenewalPO> data;

  RenewalPOResponse({
    required this.status,
    required this.data,
  });

  factory RenewalPOResponse.fromJson(Map<String, dynamic> json) {
    return RenewalPOResponse(
      status: json['status'] ?? '',
      data: (json['data'] as List<dynamic>? ?? [])
          .map(
            (item) => RenewalPO.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList(),
    );
  }
}

class RenewalPO {
  final int id;
  final String poNumber;
  final String customerName;
  final String customerCode;
  final String vertical;
  final String verticalCode;
  final String validFrom;
  final String validTo;
  final double poValue;
  final String status;
  final String accountManager;

  RenewalPO({
    required this.id,
    required this.poNumber,
    required this.customerName,
    required this.customerCode,
    required this.vertical,
    required this.verticalCode,
    required this.validFrom,
    required this.validTo,
    required this.poValue,
    required this.status,
    required this.accountManager,
  });

  factory RenewalPO.fromJson(Map<String, dynamic> json) {
    return RenewalPO(
      id: json['id'] ?? 0,
      poNumber: json['poNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerCode: json['customerCode'] ?? '',
      vertical: json['vertical'] ?? '',
      verticalCode: json['verticalCode'] ?? '',
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      poValue: (json['poValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      accountManager: json['accountManager'] ?? '',
    );
  }
}