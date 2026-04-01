import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import 'AppInfoField.dart';

class ContactSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const ContactSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInfoField(label: "Contact Person", value: item.contactPerson),
        const SizedBox(height: 12),
        AppInfoField(
          label: "Contact Number",
          value: item.contactNumber,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        AppInfoField(
          label: "Email ID",
          value: item.mailId,
          prefixIcon: Icons.email_outlined,
        ),
      ],
    );
  }
}