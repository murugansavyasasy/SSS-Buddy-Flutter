class Localconveyencemodel {
  String idLocalExpense;
  String Username;
  String monthOfClaim;
  String RefId;
  double TotalLocalExpense;
  String Description;
  dynamic processBy;
  dynamic processType;
  int IsApproved;
  int IsPaid;
  dynamic Remarks;
  dynamic RemarksWithoutBill;
  int Result;
  String ResultMessage;
  String Status ;
  int FinalApproval;
  String PaidDate;
  String FilePath;
  dynamic LocalExpenseItems;

  Localconveyencemodel({
    required this.idLocalExpense,
    required this.Username,
    required this.monthOfClaim,
    required this.RefId,
    required this.TotalLocalExpense,
    required this.Description,
    required this.processBy,
    required this.processType,
    required this.IsApproved,
    required this.IsPaid,
    required this.Remarks,
    required this.RemarksWithoutBill,
    required this.Result,
    required this.ResultMessage,
    required this.Status,
    required this.FinalApproval,
    required this.PaidDate,
    required this.FilePath,
    required this.LocalExpenseItems,
  });

  factory Localconveyencemodel.fromJson(Map<String,dynamic> json) {
    return Localconveyencemodel(
      idLocalExpense: json["idLocalExpense"] ?? "",
      Username: json["Username"] ?? "",
      monthOfClaim: json["monthOfClaim"] ?? "",
      RefId: json["RefId"] ?? "",
      TotalLocalExpense: json["TotalLocalExpense"] ?? 0,
      Description: json["Description"] ?? "",
      processBy: json["processBy"] ?? "",
      processType: json["processType"] ?? "",
      IsApproved: json["IsApproved"] ?? 0,
      IsPaid: json["IsPaid"] ?? 0,
      Remarks: json["Remarks"] ?? "",
      RemarksWithoutBill: json["RemarksWithoutBill"] ?? "",
      Result: json["Result"] ?? 0,
      ResultMessage: json["ResultMessage"] ?? "",
      Status: json["Status"] ?? "",
      FinalApproval: json["FinalApproval"] ?? 0,
      PaidDate: json["PaidDate"] ?? "",
      FilePath: json["FilePath"] ?? "",
      LocalExpenseItems: json["LocalExpenseItems"] ?? "",
    );
  }
}