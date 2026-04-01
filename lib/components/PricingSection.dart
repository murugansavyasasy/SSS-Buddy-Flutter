import 'package:flutter/cupertino.dart';

import '../auth/model/po_details_modal.dart';
import 'AppInfoField.dart';

class PricingSection extends StatelessWidget {
  final PoDetailsModel po;
  const PricingSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Student Rate/yr",
                    value: "₹ ${po.studentRate}")),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Rate/month",
                    value: "₹ ${po.studentRatePerMonth}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Student Count", value: po.studentCount)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Tax Rate", value: "${po.taxRate}%")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Tax Component", value: po.taxComponent)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Advance Amount",
                    value: "₹ ${po.advanceAmount}")),
          ],
        ),
      ],
    );
  }
}