
class Usagecount {
  String VoiceUsage;
  String VoiceAllocated;
  String SMSUsage;
  String SMSAllocated;
  String AppUsageCount;

  Usagecount({
    required this.VoiceUsage,
    required this.VoiceAllocated,
    required this.SMSUsage,
    required this.SMSAllocated,
    required this.AppUsageCount,
  });

  static String _parse(dynamic v) {
    if (v == null) return "0";
    if (v is num) {
      return v == v.truncate() ? v.toInt().toString() : v.toString();
    }
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == "null") return "0";
    final n = num.tryParse(s);
    if (n != null) return _parse(n);
    return s;
  }

  static String display(String v) =>
      v.toUpperCase() == "UL" ? "Unlimited" : v;

  factory Usagecount.fromJson(Map<String, dynamic> json) {
    return Usagecount(
      VoiceUsage: _parse(json["VoiceUsage"]),
      VoiceAllocated: _parse(json["VoiceAllocated"]),
      SMSUsage: _parse(json["SMSUsage"]),
      SMSAllocated: _parse(json["SMSAllocated"]),
      AppUsageCount: _parse(json["AppUsageCount"]),
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
