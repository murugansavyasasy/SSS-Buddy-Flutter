class Financialyearmodel {
  int idValue;
  String nameValue;
  int processby;
  dynamic tallyCustomerId;
  dynamic extraString;
  int UserType;

  Financialyearmodel({
    required this.idValue,
    required this.nameValue,
    required this.processby,
    required this.tallyCustomerId,
    required this.extraString,
    required this.UserType,
});

  factory Financialyearmodel.fromJson(Map<String,dynamic> json) {
    return Financialyearmodel(
      idValue: json["idValue"] ?? "",
      nameValue: json["nameValue"] ?? "",
      processby: json["processby"] ?? "",
      tallyCustomerId: json["tallyCustomerId"] ?? "",
      extraString: json["extraString"] ?? "",
      UserType: json["UserType"] ?? "",
    );
  }
}