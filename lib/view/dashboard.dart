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

            /// MAIN CONTENT
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),

                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔥 DASHBOARD CARDS (HORIZONTAL)
                      SizedBox(
                        height: 200,
                        child: schoolStats.when(
                          loading: () => ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              DashboardCard(
                                title: "Live Schools",
                                activeLabel: "Active",
                                inactiveLabel: "Inactive",
                                color: const Color(0xFF1DB954),
                                icon: Icons.school_rounded,
                                isLoading: true,
                              ),
                              const SizedBox(width: 12),
                              DashboardCard(
                                title: "POC Schools",
                                activeLabel: "Active",
                                inactiveLabel: "Inactive",
                                color: const Color(0xFF2E4F7D),
                                icon: Icons.science_rounded,
                                isLoading: true,
                              ),
                              const SizedBox(width: 12),
                              DashboardCard(
                                title: "Stopped Schools",
                                activeLabel: "",
                                inactiveLabel: "",
                                color: const Color(0xFFE53935),
                                icon: Icons.block_rounded,
                                isLoading: true,
                              ),
                            ],
                          ),

                          error: (e, _) => Center(child: Text(e.toString())),

                          data: (stats) {
                            final schoolList = stats.rawList;

                            int totalLiveStudents = schoolList.fold(0, (
                              sum,
                              item,
                            ) {
                              if (item["Status"] == "LIVE" &&
                                  item["isActive"] == "1") {
                                return sum +
                                    (int.tryParse(
                                          item["Students"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });
                            int totalLiveStaff = schoolList.fold(0, (
                              sum,
                              item,
                            ) {
                              if (item["Status"] == "LIVE" &&
                                  item["isActive"] == "1") {
                                return sum +
                                    (int.tryParse(
                                          item["Staff"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });

                            int totalPOCStudents = schoolList.fold(0, (
                              sum,
                              item,
                            ) {
                              if (item["Status"] == "POC") {
                                return sum +
                                    (int.tryParse(
                                          item["Students"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });
                            int totalPOCStaff = schoolList.fold(0, (sum, item) {
                              if (item["Status"] == "POC") {
                                return sum +
                                    (int.tryParse(
                                          item["Staff"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });

                            int totalStoppedStudents = schoolList.fold(0, (
                              sum,
                              item,
                            ) {
                              if (item["Status"] == "STOPPED") {
                                return sum +
                                    (int.tryParse(
                                          item["Students"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });
                            int totalStoppedStaff = schoolList.fold(0, (
                              sum,
                              item,
                            ) {
                              if (item["Status"] == "STOPPED") {
                                return sum +
                                    (int.tryParse(
                                          item["Staff"]?.toString() ?? "0",
                                        ) ??
                                        0);
                              }
                              return sum;
                            });

                            return ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                DashboardCard(
                                  title: "Live Schools",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  activeCount: stats.liveActive.toString(),
                                  inactiveCount: stats.liveInactive.toString(),
                                  totalStudent: totalLiveStudents.toString(),
                                  totalStaff: totalLiveStaff.toString(),
                                  color: const Color(
                                    0xFF1DB954,
                                  ), // vibrant green
                                  icon: Icons.school_rounded,
                                ),

                                const SizedBox(width: 12),

                                DashboardCard(
                                  title: "POC Schools",
                                  activeLabel: "Active",
                                  inactiveLabel: "Inactive",
                                  activeCount: stats.pocActive.toString(),
                                  inactiveCount: stats.pocInactive.toString(),
                                  totalStudent: totalPOCStudents.toString(),
                                  totalStaff: totalPOCStaff.toString(),
                                  color: const Color(0xFF2E4F7D),
                                  icon: Icons.science_rounded,
                                ),

                                const SizedBox(width: 12),

                                DashboardCard(
                                  title: "Stopped Schools",
                                  activeLabel: "Stopped",
                                  inactiveLabel: "",
                                  activeCount: stats.stopped.toString(),
                                  totalStudent: totalStoppedStudents.toString(),
                                  totalStaff: totalStoppedStaff.toString(),
                                  color: const Color(0xFFE53935),
                                  icon: Icons.block_rounded,
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Text(
                            "Recent Demo",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RoutesName.demolistview,
                              );
                            },
                            child: Text(
                              "View all",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      SizedBox(
                        height: 95,
                        child: demoState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),

                          error: (e, _) => Center(child: Text(e.toString())),

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
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      RoutesName.recordvoice,arguments: demo
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// 🔥 MENU HEADER
                      /// 🔥 MENU HEADER
                      Row(
                        children: [
                          const Text(
                            "Menus",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // child: const Icon(
                            //   Icons.search_rounded,
                            //   size: 18,
                            //   color: Color(0xFF2E4F7D),
                            // ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// 🔥 GRID MENU
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: menuItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 18,
                              mainAxisExtent: 95,
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
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.createdemo,
                                  );
                                  break;

                                case 2:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.demolistview,
                                  );
                                  break;

                                case 3:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.schoollistview,
                                  );
                                  break;

                                case 4:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.circularlist,
                                  );
                                  break;

                                case 5:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.statusreport,
                                  );
                                  break;

                                case 6:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.recordcollection,
                                  );
                                  break;

                                case 7:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.toursettlement,
                                  );
                                  break;

                                case 8:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.advancetourexpense,
                                  );
                                  break;

                                case 9:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.localconveyence,
                                  );
                                  break;

                                case 10:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.customerListView,
                                  );
                                  break;

                                case 11:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.schooldocuments,
                                  );
                                  break;

                                case 12:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.importantinfo,
                                  );
                                  break;

                                case 13:
                                  Navigator.pushNamed(
                                    context,
                                    RoutesName.managementvideos,
                                  );
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
          ],
        ),
      ),
    );
  }
}
