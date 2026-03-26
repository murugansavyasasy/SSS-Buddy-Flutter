class Schooldocuments {
  String id;
  String DocumentName;
  String DocumentDescription;
  String DocumentURL;
  String DocumentType;
  String project_type;

  Schooldocuments({
    required this.id,
    required this.DocumentName,
    required this.DocumentDescription,
    required this.DocumentURL,
    required this.DocumentType,
    required this.project_type,
  });

  factory Schooldocuments.fromJson(Map<String,dynamic> json) => Schooldocuments(
    id: json["id"],
    DocumentName: json["DocumentName"],
    DocumentDescription: json["DocumentDescription"],
    DocumentURL: json["DocumentURL"],
    DocumentType: json["DocumentType"],
    project_type: json["project_type"],
  );
}
