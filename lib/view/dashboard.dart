import 'package:flutter/material.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/Menulists.dart';
import 'package:sssbuddy/components/header_toolbar.dart';
import '../auth/model/Menuitem.dart';
import '../components/dashboard_card.dart';
import '../components/dashboard_tile.dart';
import '../components/glass_card.dart';
import '../components/upcoming_demo_card.dart';
import 'leaderboard/widget/dashboard_leaderboard.dart';
import '../utils/routes/routes_name.dart';
import '../core/notifications/local_notifications.dart';
import '../viewModel/chat_viewmodel.dart';
import '../viewModel/followup_viewmodel.dart';
import '../viewModel/demolist_view_model.dart';
import '../viewModel/login_view_model.dart';
import '../viewModel/schoollist_view_model.dart';

/// Home leaderboard card is hidden for now; set to true to show it again.
const bool _showLeaderboardCard = false;

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoviewProvider);
    final schoolStats = ref.watch(schoolStatsProvider);
    final loginData = ref.watch(loginProvider);
    final chatUnread = ref.watch(chatUnreadTotalProvider);
    final followUpsDue = ref.watch(followUpDueCountProvider);

    // Open the screen of a notification tapped while the app was closed.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => LocalNotifications.instance.flushPending(),
    );

    final menus = loginData.when(
      data: (data) => getMenuItems(
        vimsUserType: data?.roleName ?? "",
        schoolUserType: data?.roleCode ?? "",
      ),
      loading: () => <MenuItem>[],
      error: (_, __) => <MenuItem>[],
    );
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Exit App"),
              content: const Text("Are you sure you want to exit?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("No"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Yes"),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        },  child:Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Column(
        children: [
          const HeaderToolbar(),

          /// MAIN CONTENT
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                color: HomeGlass.bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 172,
                      child: schoolStats.when(
                        loading: () => ListView(
                          scrollDirection: Axis.horizontal,
                          // Let card glows show instead of being cut off.
                          clipBehavior: Clip.none,
                          children: [
                            DashboardCard(
                              title: "Live Schools",
                              activeLabel: "Active",
                              inactiveLabel: "Inactive",
                              color: HomeGlass.green,
                              icon: Icons.school_rounded,
                              isLoading: true,
                            ),
                            const SizedBox(width: 12),
                            DashboardCard(
                              title: "POC Schools",
                              activeLabel: "Active",
                              inactiveLabel: "Inactive",
                              color: HomeGlass.blue,
                              icon: Icons.science_rounded,
                              isLoading: true,
                            ),
                            const SizedBox(width: 12),
                            DashboardCard(
                              title: "Stopped Schools",
                              activeLabel: "",
                              inactiveLabel: "",
                              color: HomeGlass.orange,
                              icon: Icons.block_rounded,
                              isLoading: true,
                            ),
                          ],
                        ),

                        error: (e, _) => Center(
                            child: Text(e.toString(),
                                style: TextStyle(color: HomeGlass.muted))),

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
                            clipBehavior: Clip.none,
                            children: [
                              DashboardCard(
                                title: "Live Schools",
                                activeLabel: "Active",
                                inactiveLabel: "Inactive",
                                activeCount: stats.liveActive.toString(),
                                inactiveCount: stats.liveInactive.toString(),
                                totalStudent: totalLiveStudents.toString(),
                                totalStaff: totalLiveStaff.toString(),
                                color: HomeGlass.green,
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
                                color: HomeGlass.blue,
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
                                color: HomeGlass.orange,
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
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: HomeGlass.ink,
                          ),
                        ),
                        const Spacer(),
                        GlassPill(
                          light: true,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RoutesName.demolistview,
                            );
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "View all",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: HomeGlass.ink,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  size: 17, color: HomeGlass.ink),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      height: 84,
                      child: demoState.when(
                        loading: () =>
                        const Center(
                            child: CircularProgressIndicator(color: HomeGlass.ink)),

                        error: (e, _) => Center(
                            child: Text(e.toString(),
                                style: TextStyle(color: HomeGlass.muted))),

                        data: (demos) {
                          if (demos.isEmpty) {
                            return const Center(
                              child: Text("No demo list found",
                                  style: TextStyle(color: Color(0xFF6B7280))),
                            );
                          }

                          final limitedList = demos.take(5).toList();

                          return ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
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

                    /// LEADERBOARD (this month: top 3 + my rank) — hidden for now.
                    if (_showLeaderboardCard) ...[
                      const DashboardLeaderboard(),
                      const SizedBox(height: 16),
                    ],

                    /// 🔥 MENU HEADER
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: HomeGlass.ink,
                      ),
                    ),

                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, constraints) {
                      // 2 columns on phones, 3 on small tablets, 4 on iPad / large screens.
                      final maxW = constraints.maxWidth;
                      final columns = maxW >= 900
                          ? 4
                          : maxW >= 600
                              ? 3
                              : 2;
                      const spacing = 12.0;
                      final tileWidth =
                          ((maxW - spacing * (columns - 1)) / columns).floorToDouble();
                      final tileHeight = columns > 2 ? 108.0 : 98.0;
                      return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(menus.length, (index) {
                        final item = menus[index];

                        return SizedBox(
                          width: tileWidth,
                          height: tileHeight, // same size for every tile, even with 2-line titles
                          child: DashboardTile(
                            title: item.title,
                            icon: item.icon,
                            color: item.color,
                            badgeCount: item.id == 20
                                ? chatUnread
                                : item.id == 21
                                    ? followUpsDue
                                    : 0,
                            onTap: () {
                              switch (item.id) {
                                case 1:
                                  Navigator.pushNamed(context, RoutesName.createdemo);
                                  break;
                                case 2:
                                  Navigator.pushNamed(context, RoutesName.demolistview);
                                  break;
                                case 3:
                                  Navigator.pushNamed(context, RoutesName.schoollistview);
                                  break;
                                case 4:
                                  Navigator.pushNamed(context, RoutesName.circularlist);
                                  break;
                                case 5:
                                  Navigator.pushNamed(context, RoutesName.statusreport);
                                  break;
                                case 6:
                                  Navigator.pushNamed(context, RoutesName.recordcollection);
                                  break;
                                case 7:
                                  Navigator.pushNamed(context, RoutesName.toursettlement);
                                  break;
                                case 8:
                                  Navigator.pushNamed(context, RoutesName.advancetourexpense);
                                  break;
                                case 9:
                                  Navigator.pushNamed(context, RoutesName.localconveyence);
                                  break;
                                case 10:
                                  Navigator.pushNamed(context, RoutesName.customerListView);
                                  break;
                                case 11:
                                  Navigator.pushNamed(context, RoutesName.schooldocuments);
                                  break;
                                case 12:
                                  Navigator.pushNamed(context, RoutesName.importantinfo);
                                  break;
                                case 13:
                                  Navigator.pushNamed(context, RoutesName.managementvideos);
                                  break;
                                case 14:
                                  Navigator.pushNamed(context, RoutesName.zero_activity);
                                  break;
                                case 15:
                                  Navigator.pushNamed(context, RoutesName.renewalPOs);
                                  break;
                                case 16:
                                  Navigator.pushNamed(context, RoutesName.alert);
                                  break;
                                case 17:
                                  Navigator.pushNamed(context, RoutesName.feedback);
                                  break;
                                case 18:
                                  Navigator.pushNamed(context, RoutesName.serverstatus);
                                  break;
                                case 19:
                                  Navigator.pushNamed(context, RoutesName.roottracker);
                                  break;
                                case 20:
                                  Navigator.pushNamed(context, RoutesName.chat);
                                  break;
                                case 21:
                                  Navigator.pushNamed(context, RoutesName.followups);
                                  break;
                                case 22:
                                  Navigator.pushNamed(context, RoutesName.leaderboard);
                                  break;
                                case 23:
                                  Navigator.pushNamed(context, RoutesName.exhibitions);
                                  break;

                              }
                            },
                          ),
                        );
                      }),
                    );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    ));
  }
  double _getTileRatio(List<MenuItem> menus) {
    if (menus.isEmpty) return 1.5;

    final maxLen = menus
        .map((e) => e.title.length)
        .reduce((a, b) => a > b ? a : b);

    if (maxLen <= 10) return 1.5;
    if (maxLen <= 16) return 1.35;
    return 1.2;
  }
}
