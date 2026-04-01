import 'package:flutter/cupertino.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import 'AppCopyField.dart';
import 'AppInfoField.dart';

class CompanySection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const CompanySection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppCopyField(label: "GST NUMBER", value: item.gstinNumber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppCopyField(label: "PAN NUMBER", value: item.panNumber),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppInfoField(label: "TIN Number", value: item.tinNumber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppInfoField(label: "STC Number", value: item.stcNumber),
            ),
          ],
        ),
      ],
    );
  }
}