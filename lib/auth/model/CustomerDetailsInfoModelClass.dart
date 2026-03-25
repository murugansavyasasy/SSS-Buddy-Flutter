class Customerdetailsinfomodelclass {
  int idCustomer;
  String tallyCustomerId;
  String customerName;
  String customerOtherName;
  String salesPersonName;
  String customerBranchType;
  String customerBranchTypeName;
  String customerType;
  String customerTypeName;
  String companyNameVS;
  String contactPerson;
  String contactNumber;
  String contactPersonDesignation;
  String mailId;
  String alternateContactPerson;
  String alternateContactNumber;
  String alternateMailId;
  String alternatePersonDesignation;
  String fax;
  String PANNumber;
  String TINNumber;
  String STCNumber;
  String GSTINNumber;
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
  String shipPhoneNumber;
  String remarks;
  String salesPersonId;
  String headCustomerId;
  String headCustomerName;
  String isDelete;
  int createdBy;
  String createdByName;
  String createdOn;
  int modifiedBy;
  String modifiedByName;
  String modifiedOn;
  int result;
  String resultMessage;
  String billingPersonName;
  String shipPersonName;
  String billingPersonNamePre;
  String shipPersonNamePre;
  int schoolServerID;
  String collegeServerID;
  String HuddleServerID;
  bool isActive;

  Customerdetailsinfomodelclass({
    required this.idCustomer,
    required this.tallyCustomerId,
    required this.customerName,
    required this.salesPersonName,
    required this.isActive,
    required this.customerOtherName,
    required this.customerBranchType,
    required this.customerBranchTypeName,
    required this.customerType,
    required this.customerTypeName,
    required this.companyNameVS,
    required this.contactPerson,
    required this.contactNumber,
    required this.contactPersonDesignation,
    required this.mailId,
    required this.alternateContactPerson,
    required this.alternateContactNumber,
    required this.alternateMailId,
    required this.alternatePersonDesignation,
    required this.fax,
    required this.PANNumber,
    required this.TINNumber,
    required this.STCNumber,
    required this.GSTINNumber,
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
    required this.headCustomerId,
    required this.headCustomerName,
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
    required this.schoolServerID,
    required this.collegeServerID,
    required this.HuddleServerID,
  });

  factory Customerdetailsinfomodelclass.fromJson(Map<String, dynamic> json) {
    return Customerdetailsinfomodelclass(
      idCustomer: json["idCustomer"] ?? 0,
      tallyCustomerId: json["tallyCustomerId"] ?? "",
      customerName: json["customerName"] ?? "",
      salesPersonName: json["salesPersonName"] ?? "",
      isActive: json["isActive"] ?? false,          // ← Fixed (bool)
      customerOtherName: json["customerOtherName"] ?? "",
      customerBranchType: json["customerBranchType"] ?? "",
      customerBranchTypeName: json["customerBranchTypeName"] ?? "",
      customerType: json["customerType"] ?? "",
      customerTypeName: json["customerTypeName"] ?? "",
      companyNameVS: json["companyNameVS"] ?? "",
      contactPerson: json["contactPerson"] ?? "",
      contactNumber: json["contactNumber"] ?? "",
      contactPersonDesignation: json["contactPersonDesignation"] ?? "",
      mailId: json["mailId"] ?? "",
      alternateContactPerson: json["alternateContactPerson"] ?? "",
      alternateContactNumber: json["alternateContactNumber"] ?? "",
      alternateMailId: json["alternateMailId"] ?? "",
      alternatePersonDesignation: json["alternatePersonDesignation"] ?? "",
      fax: json["fax"] ?? "",
      PANNumber: json["PANNumber"] ?? "",
      TINNumber: json["TINNumber"] ?? "",
      STCNumber: json["STCNumber"] ?? "",
      GSTINNumber: json["GSTINNumber"] ?? "",
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
      isDelete: json["isDelete"] ?? "",
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
      schoolServerID: json["schoolServerID"] ?? 0,
      collegeServerID: json["collegeServerID"] ?? "",
      HuddleServerID: json["HuddleServerID"] ?? "",
    );
  }
}