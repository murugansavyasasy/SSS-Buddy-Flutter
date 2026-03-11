class Versioncheck {
  int IsVersionUpdateAvailable;
  int IsForceUpdateRequired;
  int result;
  String resultMessage;
  String SchoolURL;
  String VimsURL;

  Versioncheck({
    required this.IsVersionUpdateAvailable,
    required this.IsForceUpdateRequired,
    required this.result,
    required this.resultMessage,
    required this.SchoolURL,
    required this.VimsURL,
  });

  factory Versioncheck.fromJson(Map<String, dynamic> json) {
    return Versioncheck(
      IsVersionUpdateAvailable: json["IsVersionUpdateAvailable"],
      IsForceUpdateRequired: json["IsForceUpdateRequired"],
      result: json["result"],
      resultMessage: json["resultMessage"],
      SchoolURL: json["SchoolURL"],
      VimsURL: json["VimsURL"],
    );
  }

  Map<String, dynamic> toJson() => {
    "IsVersionUpdateAvailable": IsVersionUpdateAvailable,
    "IsForceUpdateRequired": IsForceUpdateRequired,
    "result": result,
    "resultMessage": resultMessage,
    "SchoolURL": SchoolURL,
    "VimsURL": VimsURL,
  };
}
