class Advancetourexpensedetailmodel {
  int BoardLodge;
  int BusinessPromo;
  int ConvTravel;
  int Food;
  int Fuel;
  int PostageCourier;
  int Printing;
  int Travel;
  int Misc;
  int BoardLodgeWithoutBill;
  int BusinessPromoWithoutBill;
  int ConvTravelWithoutBill;
  int FoodWithoutBill;
  int FuelWithoutBill;
  int PostageCourierWithoutBill;
  int PrintingWithoutBill;
  int TravelWithoutBill;
  int MiscWithoutBill;

  Advancetourexpensedetailmodel({
    required this.BoardLodge,
    required this.BusinessPromo,
    required this.ConvTravel,
    required this.Food,
    required this.Fuel,
    required this.PostageCourier,
    required this.Printing,
    required this.Travel,
    required this.Misc,
    required this.BoardLodgeWithoutBill,
    required this.BusinessPromoWithoutBill,
    required this.ConvTravelWithoutBill,
    required this.FoodWithoutBill,
    required this.FuelWithoutBill,
    required this.PostageCourierWithoutBill,
    required this.PrintingWithoutBill,
    required this.TravelWithoutBill,
    required this.MiscWithoutBill,
  });

  factory Advancetourexpensedetailmodel.fromJson(Map<String, dynamic> json) {
    return Advancetourexpensedetailmodel(
      BoardLodge: json["BoardLodge"],
      BusinessPromo: json["BusinessPromo"],
      ConvTravel: json["ConvTravel"],
      Food: json["Food"],
      Fuel: json["Fuel"],
      PostageCourier: json["PostageCourier"],
      Printing: json["Printing"],
      Travel: json["Travel"],
      Misc: json["Misc"],
      BoardLodgeWithoutBill: json["BoardLodgeWithoutBill"],
      BusinessPromoWithoutBill: json["BusinessPromoWithoutBill"],
      ConvTravelWithoutBill: json["ConvTravelWithoutBill"],
      FoodWithoutBill: json["FoodWithoutBill"],
      FuelWithoutBill: json["FuelWithoutBill"],
      PostageCourierWithoutBill: json["PostageCourierWithoutBill"],
      PrintingWithoutBill: json["PrintingWithoutBill"],
      TravelWithoutBill: json["TravelWithoutBill"],
      MiscWithoutBill: json["MiscWithoutBill"],
    );
  }
}
