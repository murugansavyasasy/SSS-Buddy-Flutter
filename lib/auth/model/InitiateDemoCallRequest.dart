class InitiateDemoCallRequest {
  final String demoId;
  final String loginId;
  final int duration;
  final String voiceUrl;
  final String fileName;

  InitiateDemoCallRequest({
    required this.demoId,
    required this.loginId,
    required this.duration,
    required this.voiceUrl,
    required this.fileName,
  });

  Map<String, dynamic> toJson() => {
    "Demoid": demoId,
    "LoginID": loginId,
    "Duration": duration,
    "voiceurl": voiceUrl,
    "fileName": fileName,
  };
}