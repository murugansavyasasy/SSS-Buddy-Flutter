class Localexpensedetailmodel {
  dynamic idLocalExpense;
  String BoardLodge;
  String ConvTravel;
  String Food;
  String Fuel;
  String PostageCourier;
  String Printing;
  String Telephone;
  String Misc;
  String BoardLodgeWithoutBill;
  String ConvTravelWithoutBill;
  String FoodWithoutBill;
  String FuelWithoutBill;
  String PostageCourierWithoutBill;
  String PrintingWithoutBill;
  String TelephoneWithoutBill;
  String MiscWithoutBill;

  Localexpensedetailmodel({
    required this.idLocalExpense,
    required this.BoardLodge,
    required this.ConvTravel,
    required this.Food,
    required this.Fuel,
    required this.PostageCourier,
    required this.Printing,
    required this.Telephone,
    required this.Misc,
    required this.BoardLodgeWithoutBill,
    required this.ConvTravelWithoutBill,
    required this.FoodWithoutBill,
    required this.FuelWithoutBill,
    required this.PostageCourierWithoutBill,
    required this.PrintingWithoutBill,
    required this.TelephoneWithoutBill,
    required this.MiscWithoutBill,
  });

  factory Localexpensedetailmodel.fromJson(Map<String, dynamic> json) {
    return Localexpensedetailmodel(
      idLocalExpense: json["idLocalExpense"],
      BoardLodge: json["BoardLodge"],
      ConvTravel: json["ConvTravel"],
      Food: json["Food"],
      Fuel: json["Fuel"],
      PostageCourier: json["PostageCourier"],
      Printing: json["Printing"],
      Telephone: json["Telephone"],
      Misc: json["Misc"],
      BoardLodgeWithoutBill: json["BoardLodgeWithoutBill"],
      ConvTravelWithoutBill: json["ConvTravelWithoutBill"],
      FoodWithoutBill: json["FoodWithoutBill"],
      FuelWithoutBill: json["FuelWithoutBill"],
      PostageCourierWithoutBill: json["PostageCourierWithoutBill"],
      PrintingWithoutBill: json["PrintingWithoutBill"],
      TelephoneWithoutBill: json["TelephoneWithoutBill"],
      MiscWithoutBill: json["MiscWithoutBill"],
    );
  }
}
