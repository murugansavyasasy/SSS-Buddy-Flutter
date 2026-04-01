class Schoolnamemodel {
  String CustomerID;
  String CustomerName;
  Schoolnamemodel({required this.CustomerID, required this.CustomerName});

  factory Schoolnamemodel.fromJson(Map<String, dynamic> json) {
    return Schoolnamemodel(
      CustomerID: json["CustomerID"] ?? "",
      CustomerName: json["CustomerName"] ?? "",
    );
  }
}
