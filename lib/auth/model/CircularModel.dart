class Circularmodel {
  String SchoolName;
  int SchoolId;
  String MessageId;
  String Time;
  String TotalCalls;
  int Connected;
  int Requested;
  int Missed;
  String voiceFile;
  String endTime;
  String isinitiated;

  Circularmodel({
    required this.SchoolName,
    required this.SchoolId,
    required this.MessageId,
    required this.Time,
    required this.TotalCalls,
    required this.Connected,
    required this.Requested,
    required this.Missed,
    required this.voiceFile,
    required this.endTime,
    required this.isinitiated,
  });

  factory Circularmodel.fromJson(Map<String, dynamic> json) {
    return Circularmodel(
      SchoolName: json["SchoolName"] ?? "",
      SchoolId: json["SchoolId"] ?? 0,
      MessageId: json["MessageId"] ?? "",
      Time: json["Time"] ?? "",
      TotalCalls: json["TotalCalls"] ?? "",
      Connected: json["Connected"] ?? 0,
      Requested: json["Requested"] ?? 0,
      Missed: json["Missed"] ?? 0,
      voiceFile: json["voiceFile"] ?? "",
      endTime: json["endTime"] ?? "",
      isinitiated: json["isinitiated"] ?? "",
    );
  }
}
