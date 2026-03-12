import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:sssbuddy/auth/Menulists.dart';
import 'package:sssbuddy/components/header_toolbar.dart';
import '../components/dashboard_card.dart';
import '../components/dashboard_tile.dart';
import '../components/upcoming_demo_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

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
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const HeaderToolbar(),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// Dashboard cards
                          Row(
                            children: [
                              DashboardCard(
                                title: "Active",
                                subtitle: "Schools",
                                count: "100",
                                description: "Out of 150",
                                color: const Color(0xff2E4F7D),
                                icon: Icons.school_outlined,
                              ),
                              const SizedBox(width: 12),
                              DashboardCard(
                                title: "Active",
                                subtitle: "POC",
                                count: "51",
                                description: "Out of 100",
                                color: Colors.green,
                                icon: Icons.person_outline,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// Upcoming demos header
                          Row(
                            children: [
                              const Text(
                                "Upcoming Demos",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "View all",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// Upcoming demo list
                          SizedBox(
                            height: 95,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 5,
                              separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return const UpcomingDemoCard();
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          /// Menu title
                          const Text(
                            "Menus",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 15),

                          /// Menu grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemCount: menuItems.length,
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 100,
                            ),
                            itemBuilder: (context, index) {
                              final item = menuItems[index];
                              return DashboardTile(
                                title: item.title,
                                icon: item.icon,
                                color: item.color,
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview()
Widget mySampleText() {
  return const Dashboard();
}