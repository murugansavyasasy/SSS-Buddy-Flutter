class PoDetailsModel {
  final String poNumber;
  final String customerId;
  final String customerType;
  final String poType;
  final String nextInvoiceDate;
  final String poDetailsFrom;
  final String hardCopyReceived;
  final String hardCopyReceivedOn;
  final String scanCopyFilePath;
  final String purchaseOrderId;
  final String staffComponent;
  final String module;
  final String advanceAmount;
  final String callsType;
  final String poDate;
  final String poValidFrom;
  final String poValidTo;
  final String goLiveDate;
  final String paymentType;
  final String paymentCycle;
  final String studentCount;
  final String studentRate;
  final String studentRatePerMonth;
  final String taxRate;
  final String taxComponent;
  final String poAmountWithTax;
  final String poAmountWithoutTax;
  final String callsCost;
  final String smsCost;
  final String isInsufficient;
  final bool notToBill;
  final String resultMessage;

  const PoDetailsModel({
    required this.poNumber,
    required this.customerId,
    required this.customerType,
    required this.poType,
    required this.nextInvoiceDate,
    required this.poDetailsFrom,
    required this.hardCopyReceived,
    required this.hardCopyReceivedOn,
    required this.scanCopyFilePath,
    required this.purchaseOrderId,
    required this.staffComponent,
    required this.module,
    required this.advanceAmount,
    required this.callsType,
    required this.poDate,
    required this.poValidFrom,
    required this.poValidTo,
    required this.goLiveDate,
    required this.paymentType,
    required this.paymentCycle,
    required this.studentCount,
    required this.studentRate,
    required this.studentRatePerMonth,
    required this.taxRate,
    required this.taxComponent,
    required this.poAmountWithTax,
    required this.poAmountWithoutTax,
    required this.callsCost,
    required this.smsCost,
    required this.isInsufficient,
    required this.notToBill,
    required this.resultMessage,
  });

  factory PoDetailsModel.fromJson(Map<String, dynamic> json) {
    return PoDetailsModel(
      poNumber:            json['PONumber']?.toString() ?? '-',
      customerId:          json['CustomerId']?.toString() ?? '-',
      customerType:        json['CustomerType']?.toString() ?? '-',
      poType:              json['POType']?.toString() ?? '-',
      nextInvoiceDate:     json['NextInvoiceDate']?.toString() ?? '-',
      poDetailsFrom:       json['PODetailsFrom']?.toString() ?? '-',
      hardCopyReceived:    json['HardCopyReceived']?.toString() ?? '-',
      hardCopyReceivedOn:  json['HardCopyReceivedOn']?.toString() ?? '-',
      scanCopyFilePath:    json['ScanCopyFilePath']?.toString() ?? '',
      purchaseOrderId:     json['PurchaseOrderID']?.toString() ?? '-',
      staffComponent:      json['StaffComponent']?.toString() ?? '-',
      module:              json['Module']?.toString() ?? '-',
      advanceAmount:       json['AdvanceAmount']?.toString() ?? '0',
      callsType:           json['CallsType']?.toString() ?? '-',
      poDate:              json['PODate']?.toString() ?? '-',
      poValidFrom:         json['POValidFrom']?.toString() ?? '-',
      poValidTo:           json['POValidTo']?.toString() ?? '-',
      goLiveDate:          json['GoLiveDate']?.toString() ?? '-',
      paymentType:         json['PaymentType']?.toString() ?? '-',
      paymentCycle:        json['PaymentCycle']?.toString() ?? '-',
      studentCount:        json['StudentCount']?.toString() ?? '0',
      studentRate:         json['StudentRate']?.toString() ?? '0',
      studentRatePerMonth: json['StudentRatePerMonth']?.toString() ?? '0',
      taxRate:             json['TaxRate']?.toString() ?? '0',
      taxComponent:        json['TaxComponent']?.toString() ?? '-',
      poAmountWithTax:     json['POAmountWithTax']?.toString() ?? '0',
      poAmountWithoutTax:  json['POAmountWithoutTax']?.toString() ?? '0',
      callsCost:           json['CallsCost']?.toString() ?? '0',
      smsCost:             json['SMSCost']?.toString() ?? '0',
      isInsufficient:      json['isInsufficient']?.toString() ?? '-',
      notToBill:           json['NotToBill'] == true,
      resultMessage:       json['resultMessage']?.toString() ?? '-',
    );
  }
}