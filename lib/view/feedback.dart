import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/ComingSoonPage.dart';
class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: "Feedback",
      icon: Icons.rate_review,
      message: "Feedback system is under development.\nStay tuned!",
    );
  }
}