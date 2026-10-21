import 'package:flutter/material.dart';

import '../components/ComingSoonPage.dart';
class ServerStatusScreen extends StatelessWidget {
  const ServerStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: "Server Status",
      icon: Icons.dns,
      message: "Server Status module is under development.\nLive server health coming soon.",
    );
  }
}
