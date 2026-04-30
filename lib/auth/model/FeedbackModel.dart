class FeedbackModel {
  final String id;
  final String sentBy;
  final String title;
  final String description;
  final DateTime sentOn;

  FeedbackModel({
    required this.id,
    required this.sentBy,
    required this.title,
    required this.description,
    required this.sentOn,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['FeedBackID'],
      sentBy: json['SentBy'],
      title: (json['Title'] ?? "").trim(),
      description: json['Description'] ?? "",
      sentOn: parseDate(json['SentOn']),
    );
  }

  static DateTime parseDate(String date) {
    return DateTime.parse(
      _convertToISO(date),
    );
  }

  static String _convertToISO(String input) {
    // Convert "Sep 16 2019  5:48PM" → ISO format
    final cleaned = input.replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleaned.split(' ');

    final monthMap = {
      "Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04",
      "May": "05", "Jun": "06", "Jul": "07", "Aug": "08",
      "Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"
    };

    final month = monthMap[parts[0]]!;
    final day = parts[1].padLeft(2, '0');
    final year = parts[2];
    final time = parts[3];

    return "$year-$month-$day ${_formatTime(time)}:00";
  }

  static String _formatTime(String time) {
    final isPM = time.contains("PM");
    final cleaned = time.replaceAll(RegExp(r'[APM]'), '');
    final split = cleaned.split(":");

    int hour = int.parse(split[0]);
    final minute = split[1];

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return "${hour.toString().padLeft(2, '0')}:$minute";
  }
}