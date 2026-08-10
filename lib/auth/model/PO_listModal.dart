class PurchaseOrderResponse {
  final String status;
  final PurchaseOrderData data;

  PurchaseOrderResponse({
    required this.status,
    required this.data,
  });

  factory PurchaseOrderResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderResponse(
      status: json['status'] ?? '',
      data: PurchaseOrderData.fromJson(json['data'] ?? {}),
    );
  }
}

class PurchaseOrderData {
  final Customer customer;
  final List<PurchaseOrder> purchaseOrders;
  final List<dynamic> pendingInvoices;
  final int pendingTotal;

  PurchaseOrderData({
    required this.customer,
    required this.purchaseOrders,
    required this.pendingInvoices,
    required this.pendingTotal,
  });

  factory PurchaseOrderData.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderData(
      customer: Customer.fromJson(json['customer'] ?? {}),
      purchaseOrders: (json['purchaseOrders'] as List? ?? [])
          .map((e) => PurchaseOrder.fromJson(e))
          .toList(),
      pendingInvoices: json['pendingInvoices'] ?? [],
      pendingTotal: json['pendingTotal'] ?? 0,
    );
  }
}

class Customer {
  final int id;
  final String customerCode;
  final String companyName;
  final String? invoiceName;
  final String dashboardId;
  final String? city;
  final String state;
  final String accountManager;

  Customer({
    required this.id,
    required this.customerCode,
    required this.companyName,
    this.invoiceName,
    required this.dashboardId,
    this.city,
    required this.state,
    required this.accountManager,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      customerCode: json['customerCode'] ?? '',
      companyName: json['companyName'] ?? '',
      invoiceName: json['invoiceName'],
      dashboardId: json['dashboardId'] ?? '',
      city: json['city'],
      state: json['state'] ?? '',
      accountManager: json['accountManager'] ?? '',
    );
  }
}

class PurchaseOrder {
  final int id;
  final String poNumber;
  final String classification;
  final String nature;
  final String poDate;
  final String validFrom;
  final String validTo;
  final String status;
  final int poValue;
  final bool isBillable;

  PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.classification,
    required this.nature,
    required this.poDate,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.poValue,
    required this.isBillable,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] ?? 0,
      poNumber: json['poNumber'] ?? '',
      classification: json['classification'] ?? '',
      nature: json['nature'] ?? '',
      poDate: json['poDate'] ?? '',
      validFrom: json['validFrom'] ?? '',
      validTo: json['validTo'] ?? '',
      status: json['status'] ?? '',
      poValue: json['poValue'] ?? 0,
      isBillable: json['isBillable'] ?? false,
    );
  }
}