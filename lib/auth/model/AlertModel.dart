class AlertModel {
  final int id;
  final String alertType;
  final String alertTitle;
  final String alertContent;
  final String createdOn;
  final String createdFrom;
  final String extraInfo1;
  final String extraInfo2;

  AlertModel({
    required this.id,
    required this.alertType,
    required this.alertTitle,
    required this.alertContent,
    required this.createdOn,
    required this.createdFrom,
    required this.extraInfo1,
    required this.extraInfo2,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      alertType: json['alert_type'] ?? '',
      alertTitle: json['alert_title'] ?? '',
      alertContent: json['alert_content'] ?? '',
      createdOn: json['created_on'] ?? '',
      createdFrom: json['created_from'] ?? '',
      extraInfo1: json['extrainfo1'] ?? '',
      extraInfo2: json['extrainfo2'] ?? '',
    );
  }
}