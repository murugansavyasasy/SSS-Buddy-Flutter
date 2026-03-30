class Advancetourexpensemodel {
  int idTourExpense;
  String EmpName;
  String TourPurpose;
  String monthOfClaim;
  String TourName;
  String TourId;
  String Date;
  String TourPlace;
  String PaidAmount;
  String BalanceAmount;
  String Description;
  String TotalTourExpense;
  int isApproved;
  int isClaimed;
  int result;
  String resultMessage;
  String Status;
  int IsTeamHeadVerfied;
  int FinalApproval;

  Advancetourexpensemodel({
    required this.idTourExpense,
    required this.EmpName,
    required this.TourPurpose,
    required this.monthOfClaim,
    required this.TourName,
    required this.TourId,
    required this.Date,
    required this.TourPlace,
    required this.PaidAmount,
    required this.BalanceAmount,
    required this.Description,
    required this.TotalTourExpense,
    required this.isApproved,
    required this.isClaimed,
    required this.result,
    required this.resultMessage,
    required this.Status,
    required this.IsTeamHeadVerfied,
    required this.FinalApproval,
  });

  factory Advancetourexpensemodel.fromJson(Map<String, dynamic> json) {
    return Advancetourexpensemodel(
      idTourExpense: json["idTourExpense"] ?? 0,
      EmpName: json["EmpName"] ?? "",
      TourPurpose: json["TourPurpose"] ?? "",
      monthOfClaim: json["monthOfClaim"] ?? "",
      TourName: json["TourName"] ?? "",
      TourId: json["TourId"] ?? "",
      Date: json["Date"] ?? "",
      TourPlace: json["TourPlace"] ?? "",
      PaidAmount: json["PaidAmount"] ?? "",
      BalanceAmount: json["BalanceAmount"] ?? "",
      Description: json["Description"] ?? "",
      TotalTourExpense: json["TotalTourExpense"] ?? "",
      isApproved: json["isApproved"] ?? "",
      isClaimed: json["isClaimed"] ?? "",
      result: json["result"] ?? "",
      resultMessage: json["resultMessage"] ?? "",
      Status: json["Status"] ?? "",
      IsTeamHeadVerfied: json["IsTeamHeadVerfied"] ?? "",
      FinalApproval: json["FinalApproval"] ?? "",
    );
  }
}
