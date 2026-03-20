class Changepassword {
  int result;
  String? resultMessage;
  dynamic mailMsg;
  dynamic webUrl;
  dynamic accountManagerMailId;
  int idTourExpense;
  int idDirectorExpense;
  int idLocalExpense;

  Changepassword({
    required this.result,
    required this.resultMessage,
    required this.mailMsg,
    required this.webUrl,
    required this.accountManagerMailId,
    required this.idTourExpense,
    required this.idDirectorExpense,
    required this.idLocalExpense,
  });

  factory Changepassword.fromJson(Map<String, dynamic> json) => Changepassword(
    result: json["result"] ?? 0,
    resultMessage: json["resultMessage"],
    mailMsg: json["mailMsg"],
    webUrl: json["webUrl"],
    accountManagerMailId: json["accountManagerMailId"],
    idTourExpense: json["idTourExpense"] ?? 0,
    idDirectorExpense: json["idDirectorExpense"] ?? 0,
    idLocalExpense: json["idLocalExpense"] ?? 0,
  );
}
