import 'package:flutter/cupertino.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import 'AppAddressBox.dart';
import 'AppInfoField.dart';

class BillingSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const BillingSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAddressBox(tag: "ADDRESS DETAILS", address: item.billingAddress),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "City", value: item.billingCity)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "State", value: item.billingState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Pincode", value: item.billingPincode)),
            const SizedBox(width: 10),
            Expanded(
                child:
                AppInfoField(label: "Country", value: item.billingCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Billing Phone", value: item.billingPhoneNumber)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Billing Person", value: item.billingPersonName)),
          ],
        ),
      ],
    );
  }
}