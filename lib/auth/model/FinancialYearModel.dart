class Financialyearmodel {
  final int id;
  final String label;
  final String startDate;
  final String endDate;
  final bool isActive;

  Financialyearmodel({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory Financialyearmodel.fromJson(Map<String, dynamic> json) {
    return Financialyearmodel(
      id: json['id'] ?? 0,
      label: json['label'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'startDate': startDate,
      'endDate': endDate,
      'isActive': isActive,
    };
  }
}
class Paymentmodemodel {
  final String value;
  final String label;

  Paymentmodemodel({
    required this.value,
    required this.label,
  });

  factory Paymentmodemodel.fromJson(Map<String, dynamic> json) {
    return Paymentmodemodel(
      value: json['value'] ?? '',
      label: json['label'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}