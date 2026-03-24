class Managementvideosmodel {
  String videoName;
  String videoURL;
  String videoType;

  Managementvideosmodel({
    required this.videoName,
    required this.videoURL,
    required this.videoType,
  });

  factory Managementvideosmodel.fromJson(Map<String, dynamic> json) {
    return Managementvideosmodel(
      videoName: json["VideoName"] ?? "",
      videoURL:  json["VideoURL"]  ?? "",
      videoType: json["VideoType"] ?? "",
    );
  }
}