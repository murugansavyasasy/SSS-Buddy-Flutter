class Reportingmembersmodel {
  int idmember;
  String membername;
  int usertype;

  Reportingmembersmodel({
    required this.idmember,
    required this.membername,
    required this.usertype,
  });

  factory Reportingmembersmodel.fromJson(Map<String, dynamic> json) {
    return Reportingmembersmodel(
      idmember: json["idmember"],
      membername: json["membername"],
      usertype: json["usertype"],
    );
  }
}
