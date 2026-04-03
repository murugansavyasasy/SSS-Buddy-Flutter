class Salespersonmodel {
  int idValue;
  String nameValue;
  int processby;
  dynamic tallyCustomerId;
  dynamic extraString;
  int userType;

  Salespersonmodel({
    required this.idValue,
    required this.nameValue,
    required this.processby,
    required this.tallyCustomerId,
    required this.extraString,
    required this.userType,
  });

  factory Salespersonmodel.fromJson(Map<String, dynamic> json) {
    return Salespersonmodel(
      idValue: int.tryParse(json["idValue"].toString()) ?? 0,
      nameValue: json["nameValue"]?.toString() ?? "",
      processby: int.tryParse(json["processby"].toString()) ?? 0,
      tallyCustomerId: json["tallyCustomerId"],
      extraString: json["extraString"],
      userType: int.tryParse(json["UserType"].toString()) ?? 0,
    );
  }
}