import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/ComingSoonPage.dart';

class ZeroActivityScreen extends StatelessWidget {
  const ZeroActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: "Zero Activity",
      icon: Icons.do_not_disturb,
      message: "No activity features are available yet.\nWill be released soon.",
    );
  }
}