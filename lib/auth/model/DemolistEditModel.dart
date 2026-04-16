class Demolisteditmodel {
  final String SchoolName;
  final String PrincipalEmail;
  final String PrincipalNumber;
  final String PrincipalId;
  final List<String> ParentNos;

  Demolisteditmodel({

    required this.SchoolName,
    required this.PrincipalEmail,
    required this.PrincipalNumber,
    required this.PrincipalId,
    required this.ParentNos,

});
  factory Demolisteditmodel.fromJson(Map<String, dynamic> json) {
    return Demolisteditmodel(
      SchoolName: json['SchoolName'] ?? '',
      PrincipalEmail: json['PrincipalEmail'] ?? '',
      PrincipalNumber: json['PrincipalNumber'] ?? '',
      PrincipalId: json['PrincipalId'] ?? '',
      ParentNos: json['ParentNos'] != null
          ? (json['ParentNos'] as String).split(',')
          : [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'SchoolName': SchoolName,
      'PrincipalEmail': PrincipalEmail,
      'PrincipalNumber': PrincipalNumber,
      'PrincipalId': PrincipalId,
      'ParentNos': ParentNos.join(','),
    };
  }
}
