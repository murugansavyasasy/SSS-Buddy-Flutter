import 'AddTourExpenceModal.dart';


class Movetosettlementtourrequest {
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
  final String remarks;
  final String description;
  final String totalTourExpense;
  final String processBy;
  final String processType;
  final List<TourItem> tourItemList;
  final List<TourItem> tourItemListWithoutBill; // ← NEW

  Movetosettlementtourrequest({
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
    required this.remarks,
    required this.description,
    required this.totalTourExpense,
    required this.processBy,
    required this.processType,
    required this.tourItemList,
    required this.tourItemListWithoutBill,
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
      "Remarks": remarks,
      "Description": description,
      "TotalTourExpense": totalTourExpense,
      "processBy": processBy,
      "processType": processType,
      "TourItemList": tourItemList.map((e) => e.toJson()).toList(),
      "TourItemListWithoutBill":
      tourItemListWithoutBill.map((e) => e.toJson()).toList(), // ← NEW
    };
  }
}