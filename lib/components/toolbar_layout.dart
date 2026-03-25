import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../provider/app_providers.dart';

class ToolbarLayout extends ConsumerWidget {
  final Widget? navigateTo;
  final String title;
  final bool isSearch;

  const ToolbarLayout({
    super.key,
    this.navigateTo,
    required this.title,
    required this.isSearch,

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
          top: topPadding + 10,
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
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(23),
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
            const Spacer(),

            isSearch? IconButton(
              icon: const Icon(Icons.search,color: Colors.white),
              onPressed: (){
                ref.read(searchProvider.notifier).state = true;
                },
            ) :SizedBox()

          ],
        ),
      ),
    );
  }
}