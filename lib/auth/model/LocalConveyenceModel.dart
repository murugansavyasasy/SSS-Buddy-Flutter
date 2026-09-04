class Localconveyencemodel {
  final String idLocalExpense;
  final String Username;
  final String monthOfClaim;
  final String RefId;
  final double TotalLocalExpense;
  final String Description;
  final dynamic processBy;
  final dynamic processType;
  final int IsApproved;
  final int IsPaid;
  final dynamic Remarks;
  final dynamic RemarksWithoutBill;
  final int Result;
  final String ResultMessage;
  final String Status;
  final int FinalApproval;
  final String PaidDate;
  final String FilePath;

  final dynamic LocalExpenseItems;

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

  factory Localconveyencemodel.fromJson( Map<String, dynamic> json,) {
    return Localconveyencemodel(
      idLocalExpense:json["idLocalExpense"]?.toString() ?? "",
      Username:json["Username"]?.toString() ?? "",
      monthOfClaim:json["monthOfClaim"]?.toString() ?? "",
      RefId:json["RefId"]?.toString() ?? "",
      TotalLocalExpense:double.tryParse(json["TotalLocalExpense"]?.toString() ?? "0",) ?? 0.0,
      Description:
      json["Description"]?.toString() ?? "",
      processBy:json["processBy"],
      processType:json["processType"],
      IsApproved:int.tryParse(json["IsApproved"]?.toString() ?? "0",) ?? 0,
      IsPaid:int.tryParse(json["IsPaid"]?.toString() ?? "0",) ?? 0,
      Remarks:json["Remarks"],
      RemarksWithoutBill:json["RemarksWithoutBill"],
      Result:int.tryParse(json["Result"]?.toString() ?? "0",) ?? 0,
      ResultMessage:json["ResultMessage"]?.toString() ?? "",
      Status:json["Status"]?.toString() ?? "",
      FinalApproval: int.tryParse(json["FinalApproval"]?.toString() ?? "0",) ?? 0,
      PaidDate:json["PaidDate"]?.toString() ?? "",
      FilePath:json["FilePath"]?.toString() ?? "",
      LocalExpenseItems:json["LocalExpenseItems"],
    );
  }
}