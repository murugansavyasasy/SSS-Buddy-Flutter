import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:sssbuddy/auth/Menulists.dart';
import 'package:sssbuddy/components/header_toolbar.dart';
import '../components/dashboard_card.dart';
import '../components/dashboard_tile.dart';
import '../components/upcoming_demo_card.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/demolist_view_model.dart';
import '../viewModel/schoollist_view_model.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoviewProvider);
    final schoolStats = ref.watch(schoolStatsProvider);
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
                    color: Colors.grey.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              schoolStats.when(
                                loading: () => const DashboardCard(
                                  title: "Schools",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  color: Color(0xff2E4F7D),
                                  isLoading: true,
                                ),
                                error: (e, _) => const DashboardCard(
                                  title: "Schools",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  color: Color(0xff2E4F7D),
                                ),
                                data: (stats) {
                                  return DashboardCard(
                                    title: "Schools",
                                    activeLabel: "Active",
                                    inactiveLabel: "Inactive",
                                    activeCount: stats.liveActive.toString(),
                                    inactiveCount: stats.liveInactive
                                        .toString(),
                                    color: const Color(0xff2E4F7D),
                                  );
                                },
                              ),

                              const SizedBox(width: 12),

                              schoolStats.when(
                                loading: () => const DashboardCard(
                                  title: "POC",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  color: Colors.green,
                                  isLoading: true,
                                ),
                                error: (e, _) => const DashboardCard(
                                  title: "POC",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  color: Colors.green,
                                ),
                                data: (stats) {
                                  return DashboardCard(
                                    title: "POC",
                                    activeLabel: "Active",
                                    inactiveLabel: "Inactive",
                                    activeCount: stats.pocActive.toString(),
                                    inactiveCount: stats.pocInactive.toString(),
                                    color: Colors.green,
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Text(
                                "Demo List",
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

                          SizedBox(
                            height: 95,
                            child: demoState.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),

                              error: (e, _) =>
                                  Center(child: Text(e.toString())),

                              data: (demos) {
                                if (demos.isEmpty) {
                                  return const Center(
                                    child: Text("No demo list found"),
                                  );
                                }
                                final limitedList = demos.take(5).toList();
                                return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: limitedList.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final demo = limitedList[index];
                                    return UpcomingDemoCard(
                                      demoId: demo.demoId.toString(),
                                      schoolName: demo.schoolName,
                                      principalNumber: demo.principalNumber,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            children: const [
                              Text(
                                "Menus",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.search, color: Colors.black, size: 20),
                            ],
                          ),

                          const SizedBox(height: 15),

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
                                onTap: () {
                                  switch (item.id) {
                                    case 1:
                                      Navigator.pushReplacementNamed(context, RoutesName.createdemo);
                                      break;

                                    case 2:
                                      Navigator.pushReplacementNamed(context, RoutesName.demolistview);
                                      break;

                                    case 3:
                                      Navigator.pushReplacementNamed(context, RoutesName.schoollistview);
                                      break;
                                      
                                    default:
                                      break;
                                  }
                                },
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
