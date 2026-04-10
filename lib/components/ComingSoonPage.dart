import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sssbuddy/components/toolbar_layout.dart';
import '../view/dashboard.dart';
import '../values/colors/app_colors.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: title,
              navigateTo: const Dashboard(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),

                /// 🔹 Scroll Safe Content
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// Icon
                            Icon(
                              icon,
                              size: 110,
                              color: Colors.grey.shade400,
                            ),

                            const SizedBox(height: 28),

                            /// Title
                            Text(
                              "Coming Soon!",
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// Message
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}