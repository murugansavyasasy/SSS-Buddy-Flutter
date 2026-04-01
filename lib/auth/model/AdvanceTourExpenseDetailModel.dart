class Advancetourexpensedetailmodel {
  final double boardLodge;
  final double businessPromo;
  final double convTravel;
  final double food;
  final double fuel;
  final double postageCourier;
  final double printing;
  final double travel;
  final double misc;
  final double boardLodgeWithoutBill;
  final double businessPromoWithoutBill;
  final double convTravelWithoutBill;
  final double foodWithoutBill;
  final double fuelWithoutBill;
  final double postageCourierWithoutBill;
  final double printingWithoutBill;
  final double travelWithoutBill;
  final double miscWithoutBill;

  Advancetourexpensedetailmodel({
    required this.boardLodge,
    required this.businessPromo,
    required this.convTravel,
    required this.food,
    required this.fuel,
    required this.postageCourier,
    required this.printing,
    required this.travel,
    required this.misc,
    required this.boardLodgeWithoutBill,
    required this.businessPromoWithoutBill,
    required this.convTravelWithoutBill,
    required this.foodWithoutBill,
    required this.fuelWithoutBill,
    required this.postageCourierWithoutBill,
    required this.printingWithoutBill,
    required this.travelWithoutBill,
    required this.miscWithoutBill,
  });

  factory Advancetourexpensedetailmodel.fromJson(Map<String, dynamic> json) {
    return Advancetourexpensedetailmodel(
      boardLodge: (json['BoardLodge'] as num).toDouble(),
      businessPromo: (json['BusinessPromo'] as num).toDouble(),
      convTravel: (json['ConvTravel'] as num).toDouble(),
      food: (json['Food'] as num).toDouble(),
      fuel: (json['Fuel'] as num).toDouble(),
      postageCourier: (json['PostageCourier'] as num).toDouble(),
      printing: (json['Printing'] as num).toDouble(),
      travel: (json['Travel'] as num).toDouble(),
      misc: (json['Misc'] as num).toDouble(),
      boardLodgeWithoutBill: (json['BoardLodgeWithoutBill'] as num).toDouble(),
      businessPromoWithoutBill: (json['BusinessPromoWithoutBill'] as num).toDouble(),
      convTravelWithoutBill: (json['ConvTravelWithoutBill'] as num).toDouble(),
      foodWithoutBill: (json['FoodWithoutBill'] as num).toDouble(),
      fuelWithoutBill: (json['FuelWithoutBill'] as num).toDouble(),
      postageCourierWithoutBill: (json['PostageCourierWithoutBill'] as num).toDouble(),
      printingWithoutBill: (json['PrintingWithoutBill'] as num).toDouble(),
      travelWithoutBill: (json['TravelWithoutBill'] as num).toDouble(),
      miscWithoutBill: (json['MiscWithoutBill'] as num).toDouble(),
    );
  }
}