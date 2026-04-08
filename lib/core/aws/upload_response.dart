class UploadResponse {
  final UploadData? data;
  final String? message;
  final int? status;

  UploadResponse({this.data, this.message, this.status});
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      data: json['data'] != null ? UploadData.fromJson(json['data']) : null,
      message: json['message'],
      status: json['status'],
    );
  }
  Map<String, dynamic> toJson() {
    return {'data': data?.toJson(), 'message': message, 'status': status};
  }
}

class UploadData {
  final String? fileUrl;
  final String? presignedUrl;

  UploadData({this.fileUrl, this.presignedUrl});

  factory UploadData.fromJson(Map<String, dynamic> json) {
    return UploadData(
      fileUrl: json['fileUrl'],
      presignedUrl: json['presignedUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'fileUrl': fileUrl, 'presignedUrl': presignedUrl};
  }
}
