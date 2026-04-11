import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/ComingSoonPage.dart';

class TourSettlement extends ConsumerWidget {
  const TourSettlement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ComingSoonPage(
      title: "Tour Settlement",
      icon: Icons.receipt_long,
      message:
      "Tour Settlement is under development.\n\nIt will be released in the next batch.\nStay tuned!",
    );
  }
}