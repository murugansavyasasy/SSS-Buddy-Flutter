class Uploadfilesmodel {
  int result;
  String resultMessage;
  dynamic MailMsg;
  dynamic WebUrl;
  dynamic AccountManagerMailId;
  int idTourExpense;
  int idDirectorExpense;
  int idLocalExpense;

  Uploadfilesmodel({
    required this.result,
    required this.resultMessage,
    required this.MailMsg,
    required this.WebUrl,
    required this.AccountManagerMailId,
    required this.idTourExpense,
    required this.idDirectorExpense,
    required this.idLocalExpense,
  });

  factory Uploadfilesmodel.fromJson(Map<String, dynamic> json) =>
      Uploadfilesmodel(
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
