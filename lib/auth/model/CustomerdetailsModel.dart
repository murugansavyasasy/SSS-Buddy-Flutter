class Customerdetailsmodel {
  // Required — always present in API response
  final int id;
  final String customerCode;
  final String companyName;
  final String? invoiceName;
  final String dashboardId;
  final String? city;
  final String state;
  final String status;
  final String accountManager;

  // Optional — everything else
  String? tallyCustomerId;
  String? customerName;
  String? customerOtherName;
  String? customerBranchType;
  dynamic customerBranchTypeName;
  String? customerType;
  String? customerTypeName;
  String? contactPerson;
  String? contactNumber;
  String? contactPersonDesignation;
  String? mailId;
  dynamic alternateContactPerson;
  dynamic alternateContactNumber;
  dynamic alternateMailId;
  dynamic alternatePersonDesignation;
  dynamic fax;
  String? panNumber;
  String? tinNumber;
  String? stcNumber;
  String? gstinNumber;
  String? billingAddress;
  String? billingCity;
  String? billingDistrict;
  String? billingState;
  String? billingCountry;
  String? billingPincode;
  String? billingPhoneNumber;
  String? billingPersonName;
  String? shipAddress;
  String? shipCity;
  String? shipDistrict;
  String? shipState;
  String? shipCountry;
  String? shipPincode;
  dynamic shipPhoneNumber;
  dynamic shipPersonName;
  dynamic remarks;
  String? salesPersonId;
  String? salesPersonName;
  dynamic headCustomerId;
  dynamic headCustomerName;
  bool? isActive;
  bool? isDelete;
  int? createdBy;
  dynamic createdByName;
  dynamic createdOn;
  int? modifiedBy;
  dynamic modifiedByName;
  dynamic modifiedOn;
  int? result;
  String? resultMessage;
  dynamic billingPersonNamePre;
  dynamic shipPersonNamePre;
  int? schoolServerId;
  int? collegeServerId;
  dynamic huddleServerId;

  Customerdetailsmodel({
    required this.id,
    required this.customerCode,
    required this.companyName,
    required this.dashboardId,
    required this.state,
    required this.status,
    required this.accountManager,
    this.invoiceName,
    this.city,
    this.tallyCustomerId,
    this.customerName,
    this.customerOtherName,
    this.customerBranchType,
    this.customerBranchTypeName,
    this.customerType,
    this.customerTypeName,
    this.contactPerson,
    this.contactNumber,
    this.contactPersonDesignation,
    this.mailId,
    this.alternateContactPerson,
    this.alternateContactNumber,
    this.alternateMailId,
    this.alternatePersonDesignation,
    this.fax,
    this.panNumber,
    this.tinNumber,
    this.stcNumber,
    this.gstinNumber,
    this.billingAddress,
    this.billingCity,
    this.billingDistrict,
    this.billingState,
    this.billingCountry,
    this.billingPincode,
    this.billingPhoneNumber,
    this.billingPersonName,
    this.shipAddress,
    this.shipCity,
    this.shipDistrict,
    this.shipState,
    this.shipCountry,
    this.shipPincode,
    this.shipPhoneNumber,
    this.shipPersonName,
    this.remarks,
    this.salesPersonId,
    this.salesPersonName,
    this.headCustomerId,
    this.headCustomerName,
    this.isActive,
    this.isDelete,
    this.createdBy,
    this.createdByName,
    this.createdOn,
    this.modifiedBy,
    this.modifiedByName,
    this.modifiedOn,
    this.result,
    this.resultMessage,
    this.billingPersonNamePre,
    this.shipPersonNamePre,
    this.schoolServerId,
    this.collegeServerId,
    this.huddleServerId,
  });

  factory Customerdetailsmodel.fromJson(Map<String, dynamic> json) {
    return Customerdetailsmodel(
      // Required
      id: json["id"] ?? 0,
      customerCode: json["customerCode"]?.toString() ?? "",
      companyName: json["companyName"]?.toString() ?? "",
      dashboardId: json["dashboardId"]?.toString() ?? "",
      state: json["state"]?.toString() ?? "",
      status: json["status"]?.toString() ?? "",
      accountManager: json["accountManager"]?.toString() ?? "",

      // Optional
      invoiceName: json["invoiceName"]?.toString(),
      city: json["city"]?.toString(),
      tallyCustomerId: json["tallyCustomerId"],
      customerName: json["customerName"],
      customerOtherName: json["customerOtherName"],
      customerBranchType: json["customerBranchType"],
      customerBranchTypeName: json["customerBranchTypeName"],
      customerType: json["customerType"],
      customerTypeName: json["customerTypeName"],
      contactPerson: json["contactPerson"],
      contactNumber: json["contactNumber"],
      contactPersonDesignation: json["contactPersonDesignation"],
      mailId: json["mailId"],
      alternateContactPerson: json["alternateContactPerson"],
      alternateContactNumber: json["alternateContactNumber"],
      alternateMailId: json["alternateMailId"],
      alternatePersonDesignation: json["alternatePersonDesignation"],
      fax: json["fax"],
      panNumber: json["PANNumber"],
      tinNumber: json["TINNumber"],
      stcNumber: json["STCNumber"],
      gstinNumber: json["GSTINNumber"],
      billingAddress: json["billingAddress"],
      billingCity: json["billingCity"],
      billingDistrict: json["billingDistrict"],
      billingState: json["billingState"],
      billingCountry: json["billingCountry"],
      billingPincode: json["billingPincode"],
      billingPhoneNumber: json["billingPhoneNumber"],
      billingPersonName: json["billingPersonName"],
      shipAddress: json["shipAddress"],
      shipCity: json["shipCity"],
      shipDistrict: json["shipDistrict"],
      shipState: json["shipState"],
      shipCountry: json["shipCountry"],
      shipPincode: json["shipPincode"],
      shipPhoneNumber: json["shipPhoneNumber"],
      shipPersonName: json["shipPersonName"],
      remarks: json["remarks"],
      salesPersonId: json["salesPersonId"],
      salesPersonName: json["salesPersonName"],
      headCustomerId: json["headCustomerId"],
      headCustomerName: json["headCustomerName"],
      isActive: json["isActive"],
      isDelete: json["isDelete"],
      createdBy: json["createdBy"],
      createdByName: json["createdByName"],
      createdOn: json["createdOn"],
      modifiedBy: json["modifiedBy"],
      modifiedByName: json["modifiedByName"],
      modifiedOn: json["modifiedOn"],
      result: json["result"],
      resultMessage: json["resultMessage"],
      billingPersonNamePre: json["billingPersonNamePre"],
      shipPersonNamePre: json["shipPersonNamePre"],
      schoolServerId: json["schoolServerID"],
      collegeServerId: json["collegeServerID"],
      huddleServerId: json["HuddleServerID"],
    );
  }
}
class CustomerListResponse {
  final List<Customerdetailsmodel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  CustomerListResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory CustomerListResponse.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] ?? {};
    return CustomerListResponse(
      data: (json['data'] as List? ?? [])
          .map((e) => Customerdetailsmodel.fromJson(e))
          .toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 25,
      total: pagination['total'] ?? 0,
      totalPages: pagination['totalPages'] ?? 1,
    );
  }
}