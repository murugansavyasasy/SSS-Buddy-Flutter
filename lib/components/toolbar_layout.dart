import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';

class ToolbarLayout extends ConsumerWidget {
  final Widget? navigateTo;
  final String title;

  const ToolbarLayout({
    super.key,
    this.navigateTo,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(
          top: topPadding,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                },
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}