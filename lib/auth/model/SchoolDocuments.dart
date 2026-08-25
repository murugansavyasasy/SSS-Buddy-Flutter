class Schooldocuments {
  final int id;
  final String documentName;
  final String documentDescription;
  final String documentUrl;
  final String documentType;
  final String projectType;

  Schooldocuments({
    required this.id,
    required this.documentName,
    required this.documentDescription,
    required this.documentUrl,
    required this.documentType,
    required this.projectType,
  });

  factory Schooldocuments.fromJson(Map<String, dynamic> json) {
    return Schooldocuments(
      id: json['id'] ?? 0,
      documentName: json['DocumentName'] ?? '',
      documentDescription: json['DocumentDescription'] ?? '',
      documentUrl: json['DocumentURL'] ?? '',
      documentType: json['DocumentType'] ?? '',
      projectType: json['project_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'DocumentName': documentName,
      'DocumentDescription': documentDescription,
      'DocumentURL': documentUrl,
      'DocumentType': documentType,
      'project_type': projectType,
    };
  }
}