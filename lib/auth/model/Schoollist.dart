class Schoollist {
  String schoolId;
  String schoolName;
  String city;
  String address;
  DateTime periodFrom;
  DateTime periodTo;
  String userName;
  String password;
  String isActive;
  String status;
  String students;
  String staff;
  String schoolDid;
  String contactPerson1;
  String contactNumber1;
  String contactPerson2;
  String contactNumber2;
  String contactEmail;
  String salesPerson;

  Schoollist({
    required this.schoolId,
    required this.schoolName,
    required this.city,
    required this.address,
    required this.periodFrom,
    required this.periodTo,
    required this.userName,
    required this.password,
    required this.isActive,
    required this.status,
    required this.students,
    required this.staff,
    required this.schoolDid,
    required this.contactPerson1,
    required this.contactNumber1,
    required this.contactPerson2,
    required this.contactNumber2,
    required this.contactEmail,
    required this.salesPerson,
});

  factory Schoollist.fromJson(Map<String,dynamic> json) => Schoollist(

    schoolId: json["SchoolID"],
    schoolName: json["SchoolName"],
    city: json["City"],
    address: json["Address"],
    periodFrom: DateTime.parse(json["PeriodFrom"]),
    periodTo: DateTime.parse(json["PeriodTo"]),
    userName: json["UserName"],
    password: json["Password"],
    isActive: json["isActive"],
    status: json["Status"],
    students: json["Students"],
    staff: json["Staff"],
    schoolDid: json["SchoolDID"],
    contactPerson1: json["ContactPerson1"],
    contactNumber1: json["ContactNumber1"],
    contactPerson2: json["ContactPerson2"],
    contactNumber2: json["ContactNumber2"],
    contactEmail: json["ContactEmail"],
    salesPerson: json["sales_person"],
  );

  Map<String, dynamic> toJson() => {
    "SchoolID": schoolId,
    "SchoolName": schoolName,
    "City": city,
    "Address": address,
    "PeriodFrom": "${periodFrom.year.toString().padLeft(4, '0')}-${periodFrom.month.toString().padLeft(2, '0')}-${periodFrom.day.toString().padLeft(2, '0')}",
    "PeriodTo": "${periodTo.year.toString().padLeft(4, '0')}-${periodTo.month.toString().padLeft(2, '0')}-${periodTo.day.toString().padLeft(2, '0')}",
    "UserName": userName,
    "Password": password,
    "isActive": isActive,
    "Status": status,
    "Students": students,
    "Staff": staff,
    "SchoolDID": schoolDid,
    "ContactPerson1": contactPerson1,
    "ContactNumber1": contactNumber1,
    "ContactPerson2": contactPerson2,
    "ContactNumber2": contactNumber2,
    "ContactEmail": contactEmail,
    "sales_person": salesPerson,
  };
}