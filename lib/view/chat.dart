import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/ComingSoonPage.dart';
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: "Chat",
      icon: Icons.chat_bubble_outline,
      message: "Chat module is under development.\nReal-time messaging coming soon.",
    );
  }
}