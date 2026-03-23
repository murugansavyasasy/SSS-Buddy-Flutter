class Usagecount {
  int VoiceUsage;
  String VoiceAllocated;
  int SMSUsage;
  int SMSAllocated;
  int AppUsageCount;

  Usagecount({
    required this.VoiceUsage,
    required this.VoiceAllocated,
    required this.SMSUsage,
    required this.SMSAllocated,
    required this.AppUsageCount,
  });

  factory Usagecount.fromJson(Map<String, dynamic> json) {
    return Usagecount(
      VoiceUsage: json["VoiceUsage"] ?? 0,
      VoiceAllocated: json["VoiceAllocated"] ?? "0",
      SMSUsage: json["SMSUsage"] ?? 0,
      SMSAllocated: json["SMSAllocated"] ?? 0,
      AppUsageCount: json["AppUsageCount"] ?? 0,
    );
  }


  Map<String, dynamic> toJson() => {
    "VoiceUsage": VoiceUsage,
    "VoiceAllocated": VoiceAllocated,
    "SMSUsage": SMSUsage,
    "SMSAllocated": SMSAllocated,
    "AppUsageCount": AppUsageCount,
  };
}
