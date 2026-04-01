import 'package:flutter/cupertino.dart';

import '../auth/model/po_details_modal.dart';
import 'AppInfoField.dart';

class CustomerInfoSection extends StatelessWidget {
  final PoDetailsModel po;
  const CustomerInfoSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Customer ID", value: po.customerId)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Customer Type", value: po.customerType)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Staff Component", value: po.staffComponent)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Details From", value: po.poDetailsFrom)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Hard Copy", value: po.hardCopyReceived)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Received On", value: po.hardCopyReceivedOn)),
          ],
        ),
      ],
    );
  }
}