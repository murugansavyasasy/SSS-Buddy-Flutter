import 'package:flutter/cupertino.dart';

import '../auth/model/po_details_modal.dart';
import 'AppInfoField.dart';

class SummarySection extends StatelessWidget {
  final PoDetailsModel po;
  const SummarySection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Amount (with tax)",
                    value: "₹ ${po.poAmountWithTax}")),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Amount (excl. tax)",
                    value: "₹ ${po.poAmountWithoutTax}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Calls Cost", value: "₹ ${po.callsCost}")),
            const SizedBox(width: 10),
            Expanded(
                child:
                AppInfoField(label: "SMS Cost", value: "₹ ${po.smsCost}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Insufficient", value: po.isInsufficient)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Not to Bill",
                    value: po.notToBill ? "Yes" : "No")),
          ],
        ),
      ],
    );
  }
}