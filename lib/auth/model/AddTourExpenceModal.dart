class TourExpenseRequest {
  final String idTourExpense;
  final String idUser;
  final String tourPurpose;
  final String monthOfClaim;
  final String tourName;
  final String tourId;
  final String startDate;
  final String endDate;
  final String tourPlace1;
  final String tourPlace2;
  final String tourPlace3;
  final String remarksWithoutBill;
  final String description;
  final String totalTourExpense;
  final String processBy;
  final String processType;
  final List<TourItem> tourItemList;

  TourExpenseRequest({
    required this.idTourExpense,
    required this.idUser,
    required this.tourPurpose,
    required this.monthOfClaim,
    required this.tourName,
    required this.tourId,
    required this.startDate,
    required this.endDate,
    required this.tourPlace1,
    required this.tourPlace2,
    required this.tourPlace3,
    required this.remarksWithoutBill,
    required this.description,
    required this.totalTourExpense,
    required this.processBy,
    required this.processType,
    required this.tourItemList,
  });

  Map<String, dynamic> toJson() {
    return {
      "idTourExpense": idTourExpense,
      "idUser": idUser,
      "TourPurpose": tourPurpose,
      "monthOfClaim": monthOfClaim,
      "TourName": tourName,
      "TourId": tourId,
      "StartDate": startDate,
      "EndDate": endDate,
      "TourPlace1": tourPlace1,
      "TourPlace2": tourPlace2,
      "TourPlace3": tourPlace3,
      "RemarksWithoutBill": remarksWithoutBill,
      "Description": description,
      "TotalTourExpense": totalTourExpense,
      "processBy": processBy,
      "processType": processType,
      "TourItemList":
      tourItemList.map((e) => e.toJson()).toList(),
    };
  }
}
class TourExpenseResponse {
  final int result;
  final String resultMessage;
  final String? mailMsg;
  final String? webUrl;
  final String? accountManagerMailId;
  final int idTourExpense;
  final int idDirectorExpense;
  final int idLocalExpense;

  TourExpenseResponse({
    required this.result,
    required this.resultMessage,
    this.mailMsg,
    this.webUrl,
    this.accountManagerMailId,
    required this.idTourExpense,
    required this.idDirectorExpense,
    required this.idLocalExpense,
  });

  factory TourExpenseResponse.fromJson(Map<String, dynamic> json) {
    return TourExpenseResponse(
      result: json["result"] ?? 0,
      resultMessage: json["resultMessage"] ?? "",
      mailMsg: json["MailMsg"],
      webUrl: json["WebUrl"],
      accountManagerMailId: json["AccountManagerMailId"],
      idTourExpense: json["idTourExpense"] ?? 0,
      idDirectorExpense: json["idDirectorExpense"] ?? 0,
      idLocalExpense: json["idLocalExpense"] ?? 0,
    );
  }
}
class TourItem {
  String boardLodge;
  String businessPromo;
  String convTravel;
  String food;
  String fuel;
  String postageCourier;
  String printing;
  String travel;
  String misc;

  TourItem({
    required this.boardLodge,
    required this.businessPromo,
    required this.convTravel,
    required this.food,
    required this.fuel,
    required this.postageCourier,
    required this.printing,
    required this.travel,
    required this.misc,
  });

  Map<String, dynamic> toJson() {
    return {
      "BoardLodge": boardLodge,
      "BusinessPromo": businessPromo,
      "ConvTravel": convTravel,
      "Food": food,
      "Fuel": fuel,
      "PostageCourier": postageCourier,
      "Printing": printing,
      "Travel": travel,
      "Misc": misc,
    };
  }
}