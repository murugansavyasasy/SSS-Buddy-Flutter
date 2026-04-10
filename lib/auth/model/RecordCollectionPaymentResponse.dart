class Recordcollectionpaymentresponse {
  int result;
  String resultMessage;
  dynamic MailMsg;
  dynamic WebUrl;
  dynamic AccountManagerMailId;
  int idTourExpense;
  int idDirectorExpense;
  int idLocalExpense;

  Recordcollectionpaymentresponse({
    required this.result,
    required this.resultMessage,
    required this.MailMsg,
    required this.WebUrl,
    required this.AccountManagerMailId,
    required this.idTourExpense,
    required this.idDirectorExpense,
    required this.idLocalExpense,
  });

  factory Recordcollectionpaymentresponse.fromJson(Map<String, dynamic> json) {
    return Recordcollectionpaymentresponse(
      result: json["result"],
      resultMessage: json["resultMessage"],
      MailMsg: json["MailMsg"],
      WebUrl: json["WebUrl"],
      AccountManagerMailId: json["AccountManagerMailId"],
      idTourExpense: json["idTourExpense"],
      idDirectorExpense: json["idDirectorExpense"],
      idLocalExpense: json["idLocalExpense"],
    );
  }
}
