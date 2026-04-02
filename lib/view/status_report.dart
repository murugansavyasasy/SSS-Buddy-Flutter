import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/report_page.dart';
import 'package:sssbuddy/view/today_visit.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/MenuItemData.dart';
import '../components/MenuCard.dart';
import '../components/toolbar_layout.dart';
import 'dashboard.dart';
import 'overall_status_report.dart';

class StatusReport extends ConsumerWidget {
  const StatusReport({super.key});

  static const List<MenuItemData> _menus = [
    MenuItemData(
      title: "Today Visit",
      subtitle: "Update your today visit",
      icon: Icons.today_rounded,
      accent: Color(0xFF4F8EF7),
      page: TodayVisitPage(),
    ),
    MenuItemData(
      title: "Overall Status Report",
      subtitle: "Comprehensive overview of all statuses",
      icon: Icons.bar_chart_rounded,
      accent: Color(0xFF36C98E),
      page: OverallStatusReportPage(),
    ),
    MenuItemData(
      title: "Reports",
      subtitle: "Browse and export detailed reports",
      icon: Icons.description_rounded,
      accent: Color(0xFFF76B4F),
      page: ReportsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              title: "Status Report Menu",
              navigateTo: const Dashboard(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  children: [
                    ..._menus.map(
                          (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MenuCard(item: item),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
