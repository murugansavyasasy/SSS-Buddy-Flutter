class Customerdetailsinfomodelclass {
  int idCustomer;
  String tallyCustomerId;
  String customerName;
  String customerOtherName;
  String customerBranchType;
  dynamic customerBranchTypeName;
  String customerType;
  String customerTypeName;
  String companyNameVs;
  String contactPerson;
  String contactNumber;
  String contactPersonDesignation;
  String mailId;
  dynamic alternateContactPerson;
  dynamic alternateContactNumber;
  dynamic alternateMailId;
  dynamic alternatePersonDesignation;
  dynamic fax;
  String panNumber;
  String tinNumber;
  String stcNumber;
  String gstinNumber;
  String billingAddress;
  String billingCity;
  String billingDistrict;
  String billingState;
  String billingCountry;
  String billingPincode;
  String billingPhoneNumber;
  String shipAddress;
  String shipCity;
  String shipDistrict;
  String shipState;
  String shipCountry;
  String shipPincode;
  dynamic shipPhoneNumber;
  dynamic remarks;
  String salesPersonId;
  String salesPersonName;
  dynamic headCustomerId;
  dynamic headCustomerName;
  bool isActive;
  bool isDelete;
  int createdBy;
  dynamic createdByName;
  dynamic createdOn;
  int modifiedBy;
  dynamic modifiedByName;
  dynamic modifiedOn;
  int result;
  String resultMessage;
  String billingPersonName;
  dynamic shipPersonName;
  dynamic billingPersonNamePre;
  dynamic shipPersonNamePre;
  int schoolServerId;
  int collegeServerId;
  dynamic huddleServerId;

  Customerdetailsinfomodelclass({
    required this.idCustomer,
    required this.tallyCustomerId,
    required this.customerName,
    required this.customerOtherName,
    required this.customerBranchType,
    required this.customerBranchTypeName,
    required this.customerType,
    required this.customerTypeName,
    required this.companyNameVs,
    required this.contactPerson,
    required this.contactNumber,
    required this.contactPersonDesignation,
    required this.mailId,
    required this.alternateContactPerson,
    required this.alternateContactNumber,
    required this.alternateMailId,
    required this.alternatePersonDesignation,
    required this.fax,
    required this.panNumber,
    required this.tinNumber,
    required this.stcNumber,
    required this.gstinNumber,
    required this.billingAddress,
    required this.billingCity,
    required this.billingDistrict,
    required this.billingState,
    required this.billingCountry,
    required this.billingPincode,
    required this.billingPhoneNumber,
    required this.shipAddress,
    required this.shipCity,
    required this.shipDistrict,
    required this.shipState,
    required this.shipCountry,
    required this.shipPincode,
    required this.shipPhoneNumber,
    required this.remarks,
    required this.salesPersonId,
    required this.salesPersonName,
    required this.headCustomerId,
    required this.headCustomerName,
    required this.isActive,
    required this.isDelete,
    required this.createdBy,
    required this.createdByName,
    required this.createdOn,
    required this.modifiedBy,
    required this.modifiedByName,
    required this.modifiedOn,
    required this.result,
    required this.resultMessage,
    required this.billingPersonName,
    required this.shipPersonName,
    required this.billingPersonNamePre,
    required this.shipPersonNamePre,
    required this.schoolServerId,
    required this.collegeServerId,
    required this.huddleServerId,
  });

  factory Customerdetailsinfomodelclass.fromJson(Map<String, dynamic> json) {
    return Customerdetailsinfomodelclass(
      idCustomer: json["idCustomer"] ?? 0,
      tallyCustomerId: json["tallyCustomerId"] ?? "",
      customerName: json["customerName"] ?? "",
      salesPersonName: json["salesPersonName"] ?? "",
      isActive: json["isActive"] ?? false,
      customerOtherName: json["customerOtherName"] ?? "",
      customerBranchType: json["customerBranchType"] ?? "",
      customerBranchTypeName: json["customerBranchTypeName"] ?? "",
      customerType: json["customerType"] ?? "",
      customerTypeName: json["customerTypeName"] ?? "",
      companyNameVs: json["companyNameVS"] ?? "",
      contactPerson: json["contactPerson"] ?? "",
      contactNumber: json["contactNumber"] ?? "",
      contactPersonDesignation: json["contactPersonDesignation"] ?? "",
      mailId: json["mailId"] ?? "",
      alternateContactPerson: json["alternateContactPerson"] ?? "",
      alternateContactNumber: json["alternateContactNumber"] ?? "",
      alternateMailId: json["alternateMailId"] ?? "",
      alternatePersonDesignation: json["alternatePersonDesignation"] ?? "",
      fax: json["fax"] ?? "",
      panNumber: json["PANNumber"] ?? "",
      tinNumber: json["TINNumber"] ?? "",
      stcNumber: json["STCNumber"] ?? "",
      gstinNumber: json["GSTINNumber"] ?? "",
      billingAddress: json["billingAddress"] ?? "",
      billingCity: json["billingCity"] ?? "",
      billingDistrict: json["billingDistrict"] ?? "",
      billingState: json["billingState"] ?? "",
      billingCountry: json["billingCountry"] ?? "",
      billingPincode: json["billingPincode"] ?? "",
      billingPhoneNumber: json["billingPhoneNumber"] ?? "",
      billingPersonName: json["billingPersonName"] ?? "",
      shipAddress: json["shipAddress"] ?? "",
      shipCity: json["shipCity"] ?? "",
      shipDistrict: json["shipDistrict"] ?? "",
      shipState: json["shipState"] ?? "",
      shipCountry: json["shipCountry"] ?? "",
      shipPincode: json["shipPincode"] ?? "",
      shipPhoneNumber: json["shipPhoneNumber"] ?? "",
      shipPersonName: json["shipPersonName"] ?? "",
      remarks: json["remarks"] ?? "",
      salesPersonId: json["salesPersonId"] ?? "",
      headCustomerId: json["headCustomerId"] ?? "",
      headCustomerName: json["headCustomerName"] ?? "",
      isDelete: json["isDelete"] ?? false,
      createdBy: json["createdBy"] ?? 0,
      createdByName: json["createdByName"] ?? "",
      createdOn: json["createdOn"] ?? "",
      modifiedBy: json["modifiedBy"] ?? 0,
      modifiedByName: json["modifiedByName"] ?? "",
      modifiedOn: json["modifiedOn"] ?? "",
      result: json["result"] ?? 0,
      resultMessage: json["resultMessage"] ?? "",
      billingPersonNamePre: json["billingPersonNamePre"] ?? "",
      shipPersonNamePre: json["shipPersonNamePre"] ?? "",
      schoolServerId: json["schoolServerID"] ?? 0,
      collegeServerId: json["collegeServerID"] ?? 0,
      huddleServerId: json["HuddleServerID"] ?? "",
    );
  }
}