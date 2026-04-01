import 'package:flutter/cupertino.dart';

import '../auth/model/po_details_modal.dart';
import 'AppInfoField.dart';

class ValiditySection extends StatelessWidget {
  final PoDetailsModel po;
  const ValiditySection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Valid From", value: po.poValidFrom)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "Valid To", value: po.poValidTo)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Go Live Date", value: po.goLiveDate)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Next Invoice", value: po.nextInvoiceDate)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Payment Type", value: po.paymentType)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Payment Cycle",
                    value: "${po.paymentCycle} months")),
          ],
        ),
      ],
    );
  }
}