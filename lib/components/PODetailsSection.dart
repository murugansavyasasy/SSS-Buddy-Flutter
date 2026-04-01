import 'package:flutter/cupertino.dart';

import '../auth/model/po_details_modal.dart';
import 'AppAddressBox.dart';
import 'AppInfoField.dart';

class PODetailsSection extends StatelessWidget {
  final PoDetailsModel po;
  const PODetailsSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "PO ID", value: po.purchaseOrderId)),
            const SizedBox(width: 10),
            Expanded(child: AppInfoField(label: "PO Type", value: po.poType)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Calls Type", value: po.callsType)),
            const SizedBox(width: 10),
            Expanded(child: AppInfoField(label: "Module", value: po.module)),
          ],
        ),
        if (po.scanCopyFilePath.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppAddressBox(tag: "SCAN COPY PATH", address: po.scanCopyFilePath),
        ],
      ],
    );
  }
}