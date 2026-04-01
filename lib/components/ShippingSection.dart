import 'package:flutter/cupertino.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import 'AppAddressBox.dart';
import 'AppInfoField.dart';

class ShippingSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const ShippingSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAddressBox(tag: "WAREHOUSE LOCATION", address: item.shipAddress),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "City", value: item.shipCity)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "State", value: item.shipState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "Pincode", value: item.shipPincode)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "Country", value: item.shipCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Shipping Phone",
                    value: item.shipPhoneNumber?.toString() ?? '')),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Shipping Person",
                    value: item.shipPersonName?.toString() ?? '')),
          ],
        ),
      ],
    );
  }
}