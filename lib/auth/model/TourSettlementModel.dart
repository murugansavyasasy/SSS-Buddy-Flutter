class Toursettlementmodel {
  int idTourExpense;
  String EmpName;
  String TourPurpose;
  String monthOfClaim;
  String TourName;
  String TourId;
  String Date;
  String TourPlace;
  String AdvanceTourAmount;
  dynamic PaidAmount;
  String BalanceToCompany;
  String BalanceToEmployee;
  String Description;
  String TotalTourExpense;
  String Status;
  int isApproved;
  int isClaimed;
  int result;
  String resultMessage;
  int IsTeamHeadVerfied;
  int FinalApproval;

  Toursettlementmodel({
    required this.idTourExpense,
    required this.EmpName,
    required this.TourPurpose,
    required this.monthOfClaim,
    required this.TourName,
    required this.TourId,
    required this.Date,
    required this.TourPlace,
    required this.AdvanceTourAmount,
    required this.PaidAmount,
    required this.BalanceToCompany,
    required this.BalanceToEmployee,
    required this.Description,
    required this.TotalTourExpense,
    required this.Status,
    required this.isApproved,
    required this.isClaimed,
    required this.result,
    required this.resultMessage,
    required this.IsTeamHeadVerfied,
    required this.FinalApproval,
});

  
}