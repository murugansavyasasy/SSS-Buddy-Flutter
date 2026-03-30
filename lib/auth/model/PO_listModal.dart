class PoListModel {
  final int idValue;
  final String nameValue;
  final int processby;
  final int? tallyCustomerId;
  final String? extraString;
  final int userType;

  PoListModel({
    required this.idValue,
    required this.nameValue,
    required this.processby,
    this.tallyCustomerId,
    this.extraString,
    required this.userType,
  });

  factory PoListModel.fromJson(Map<String, dynamic> json) {
    return PoListModel(
      idValue: json['idValue'],
      nameValue: json['nameValue'],
      processby: json['processby'],
      tallyCustomerId: json['tallyCustomerId'],
      extraString: json['extraString'],
      userType: json['UserType'],
    );
  }
}