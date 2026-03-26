class Importantinfomodel {
  final String playStoreLinkSchoolChimes;
  final String appleStoreLinkSchoolChimes;
  final String helplineNumber;
  final String schoolSupportEmailId;
  final String salesEnquiryEmailId;
  final String salesEnquiryNumber;
  final String playStoreLinkLetsReach;
  final String callsWillBeReceivedFrom;
  final String productPresentation;

  Importantinfomodel({
    required this.playStoreLinkSchoolChimes,
    required this.appleStoreLinkSchoolChimes,
    required this.helplineNumber,
    required this.schoolSupportEmailId,
    required this.salesEnquiryEmailId,
    required this.salesEnquiryNumber,
    required this.playStoreLinkLetsReach,
    required this.callsWillBeReceivedFrom,
    required this.productPresentation,
  });

  factory Importantinfomodel.fromJson(Map<String, dynamic> json) => Importantinfomodel(
    playStoreLinkSchoolChimes: json['PlayStoreLinkForSchoolChimes'] ?? '',
    appleStoreLinkSchoolChimes: json['AppleStoreLinkForSchoolChimes'] ?? '',
    helplineNumber: json['HelplineNumber'] ?? '',
    schoolSupportEmailId: json['SchoolSupportEmailId'] ?? '',
    salesEnquiryEmailId: json['SalesEnquiryEmailId'] ?? '',
    salesEnquiryNumber: json['SalesEnquiryNumber'] ?? '',
    playStoreLinkLetsReach: json['PlayStoreLinkForLetsReach'] ?? '',
    callsWillBeReceivedFrom: json['CallsWillBeReceivedFrom'] ?? '',
    productPresentation: json['ProductPresentation'] ?? '',
  );
}
