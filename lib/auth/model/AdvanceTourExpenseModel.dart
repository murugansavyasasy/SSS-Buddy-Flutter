class Advancetourexpensemodel {
  int idTourExpense;
  String EmpName;
  String TourPurpose;
  String monthOfClaim;
  String TourName;
  String TourId;
  String Date;
  String TourPlace;
  int PaidAmount;
  int BalanceAmount;
  String Description;
  int TotalTourExpense;
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
      PaidAmount: json["PaidAmount"] ?? 0,
      BalanceAmount: json["BalanceAmount"] ?? 0,
      Description: json["Description"] ?? "",
      TotalTourExpense: json["TotalTourExpense"] ?? 0,
      isApproved: json["isApproved"] ?? 0,
      isClaimed: json["isClaimed"] ?? 0,
      result: json["result"] ?? 0,
      resultMessage: json["resultMessage"] ?? "",
      Status: json["Status"] ?? "",
      IsTeamHeadVerfied: json["IsTeamHeadVerfied"] ?? 0,
      FinalApproval: json["FinalApproval"] ?? 0,
    );
  }
}

class ButtonVisibilityHelper {
  final Advancetourexpensemodel item;
  final String directorLogin;

  ButtonVisibilityHelper(
      this.item,
      this.directorLogin,
      );

  bool get canEditDelete {
    // Director + Pending approval
    if (item.isApproved == 0 && directorLogin == "3") {
      return false;
    }

    // Non-director + Pending approval
    // OR rejected
    if ((directorLogin != "3" && item.isApproved == 0) ||
        item.isApproved == 2) {
      return true;
    }

    return false;
  }

  bool get canMove {
    return item.isClaimed == 1;
  }
}
