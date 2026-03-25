class Customerdetailsmodel {
  int idCustomer;
  String tallyCustomerId;
  String SchoolServerId;
  String customerName;
  String customerTypeName;
  String customerBranchTypeName;
  String headCustomerName;
  String contactPerson;
  String contactNumber;
  String customerMailId;
  String salesPersonName;
  bool isActive;
  String billingPersonName;
  String billingPhoneNumber;
  String billingAddress;
  String billingCity;
  String billingDistrict;
  String billingState;
  String billingCountry;
  String billingPincode;
  int result;
  String resultMessage;
  String customerOtherName;
  int customerBranchType;
  String companyNameVS;
  String createdByName;
  String createdOn;
  String modifiedByName;
  String modifiedOn;
  Customerdetailsmodel({
    required this.idCustomer,
    required this.tallyCustomerId,
    required this.SchoolServerId,
    required this.customerName,
    required this.customerTypeName,
    required this.customerBranchTypeName,
    required this.headCustomerName,
    required this.contactPerson,
    required this.contactNumber,
    required this.customerMailId,
    required this.salesPersonName,
    required this.isActive,
    required this.billingPersonName,
    required this.billingPhoneNumber,
    required this.billingAddress,
    required this.billingCity,
    required this.billingDistrict,
    required this.billingState,
    required this.billingCountry,
    required this.billingPincode,
    required this.result,
    required this.resultMessage,
    required this.customerOtherName,
    required this.customerBranchType,
    required this.companyNameVS,
    required this.createdOn,
    required this.createdByName,
    required this.modifiedByName,
    required this.modifiedOn,
  });
  factory Customerdetailsmodel.fromJson(Map<String, dynamic> json) {
    return Customerdetailsmodel(
      idCustomer: json["idCustomer"] ?? 0,
      tallyCustomerId: json["tallyCustomerId"] ?? "",
      SchoolServerId: json["SchoolServerId"] ?? "",
      customerName: json["customerName"] ?? "",
      customerTypeName: json["customerTypeName"] ?? "",
      customerBranchTypeName: json["customerBranchTypeName"] ?? "",
      headCustomerName: json["headCustomerName"] ?? "",
      contactPerson: json["contactPerson"] ?? "",
      contactNumber: json["contactNumber"] ?? "",
      customerMailId: json["customerMailId"] ?? "",
      salesPersonName: json["salesPersonName"] ?? "",
      isActive: json["isActive"] ?? "",
      billingPersonName: json["billingPersonName"] ?? "",
      billingPhoneNumber: json["billingPhoneNumber"] ?? "",
      billingAddress: json["billingAddress"] ?? "",
      billingCity: json["billingCity"] ?? "",
      billingDistrict: json["billingDistrict"] ?? "",
      billingState: json["billingState"] ?? "",
      billingCountry: json["billingCountry"] ?? "",
      billingPincode: json["billingPincode"] ?? "",
      result: json["result"] ?? "",
      resultMessage: json["resultMessage"] ?? "",
      customerOtherName: json["customerOtherName"] ?? "",
      customerBranchType: json["customerBranchType"] ?? "",
      companyNameVS: json["companyNameVS"] ?? "",
      createdByName: json["createdByName"] ?? "",
      createdOn: json["createdOn"] ?? "",
      modifiedByName: json["modifiedByName"] ?? "",
      modifiedOn: json["modifiedOn"] ?? "",
    );
  }
}
