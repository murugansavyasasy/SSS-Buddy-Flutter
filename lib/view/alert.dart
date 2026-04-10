import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/ComingSoonPage.dart';
class AlertScreen extends StatelessWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: "Alert",
      icon: Icons.notifications_active,
      message: "Alerts & notifications will be available soon.",
    );
  }
}