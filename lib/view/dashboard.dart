import 'package:flutter/material.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/Menulists.dart';
import 'package:sssbuddy/components/header_toolbar.dart';
import '../auth/model/Menuitem.dart';
import '../components/dashboard_card.dart';
import '../components/app_motion.dart';
import '../components/dashboard_tile.dart';
import '../components/menu_icon_style.dart';
import '../components/glass_card.dart';
import '../components/upcoming_demo_card.dart';
import 'leaderboard/widget/dashboard_leaderboard.dart';
import '../utils/routes/routes_name.dart';
import '../core/notifications/local_notifications.dart';
import '../viewModel/chat_viewmodel.dart';
import '../viewModel/followup_viewmodel.dart';
import '../viewModel/demolist_view_model.dart';
import '../viewModel/login_view_model.dart';
import '../viewModel/payment_submission_viewmodel.dart';
import '../viewModel/schoollist_view_model.dart';

/// Home leaderboard card is hidden for now; set to true to show it again.
const bool _showLeaderboardCard = false;

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  /// School stat cards: a horizontal scroll on phones; on tablets the cards
  /// share the full width equally. [children] holds the cards and their
  /// spacers.
  Widget _statsRow(BuildContext context, List<Widget Function(double parallax)> cards) {
    // Cards slide in from the right one after another.
    Widget enter(int i, Widget child) => AppEntrance(
          index: i,
          step: const Duration(milliseconds: 90),
          delay: const Duration(milliseconds: 120),
          offsetX: 48,
          offsetY: 0,
          child: child,
        );
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      // Phone: snapping carousel; the centred card is full size, the
      // others shrink / fade, bubbles drift (parallax), dots follow.
      return AppCarousel(
        itemCount: cards.length,
        itemWidth: dashboardCardWidth(context),
        height: 172,
        dotColor: HomeGlass.navy,
        builder: (context, i, offset) => enter(i, cards[i](offset)),
      );
    }
    return SizedBox(
      height: 172,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: enter(i, cards[i](0))),
          ],
        ],
      ),
    );
  }

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

    // Payment Submissions only once the server confirms the role may use it.
    final paymentAccess = ref.watch(paymentSubmissionAccessProvider).value ?? false;
    final menus = loginData.when(
      data: (data) => getMenuItems(
        vimsUserType: data?.roleName ?? "",
        schoolUserType: data?.roleCode ?? "",
      ).where((m) => m.id != 25 || paymentAccess).toList(),
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
          const AppEntrance(offsetY: -14, child: HeaderToolbar()),

          /// MAIN CONTENT
          Expanded(
            child: AppEntrance(
              offsetY: 60,
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
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await Future.wait([
                    ref.refresh(schoolStatsProvider.future),
                    ref.refresh(demoviewProvider.future),
                  ]).catchError((_) => <Object>[]);
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Keep the last menu row above the Android navigation bar.
                padding: EdgeInsets.fromLTRB(
                    16, 20, 16, 16 + MediaQuery.paddingOf(context).bottom),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      child: schoolStats.when(
                        loading: () => _statsRow(context, [
                            (p) => DashboardCard(
                              parallax: p,
                              title: "Live Schools",
                              activeLabel: "Active",
                              inactiveLabel: "Inactive",
                              color: HomeGlass.green,
                              icon: Icons.school_rounded,
                              isLoading: true,
                            ),
                            (p) => DashboardCard(
                              parallax: p,
                              title: "POC Schools",
                              activeLabel: "Active",
                              inactiveLabel: "Inactive",
                              color: HomeGlass.blue,
                              icon: Icons.science_rounded,
                              isLoading: true,
                            ),
                            (p) => DashboardCard(
                              parallax: p,
                              title: "Stopped Schools",
                              activeLabel: "",
                              inactiveLabel: "",
                              color: HomeGlass.orange,
                              icon: Icons.block_rounded,
                              isLoading: true,
                            ),
                          ]),

                        error: (e, _) => SizedBox(
                          height: 172,
                          child: Center(
                            child: Text(e.toString(),
                                style: TextStyle(color: HomeGlass.muted))),
                        ),

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

                          return _statsRow(context, [
                              (p) => DashboardCard(
                              parallax: p,
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

                              (p) => DashboardCard(
                              parallax: p,
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

                              (p) => DashboardCard(
                              parallax: p,
                                title: "Stopped Schools",
                                activeLabel: "Stopped",
                                inactiveLabel: "",
                                activeCount: stats.stopped.toString(),
                                totalStudent: totalStoppedStudents.toString(),
                                totalStaff: totalStoppedStaff.toString(),
                                color: HomeGlass.orange,
                                icon: Icons.block_rounded,
                              ),
                            ]);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    AppEntrance(
                      index: 3,
                      delay: const Duration(milliseconds: 120),
                      child: Row(
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

                              return AppEntrance(
                                index: index,
                                step: const Duration(milliseconds: 80),
                                delay: const Duration(milliseconds: 250),
                                offsetX: 56,
                                offsetY: 0,
                                child: UpcomingDemoCard(
                                demoId: demo.demoId.toString(),
                                schoolName: demo.schoolName,
                                principalNumber: demo.principalNumber,
                                onTap: () {
                                  Navigator.pushNamed(
                                      context,
                                      RoutesName.recordvoice,arguments: demo
                                  );
                                },
                              ),
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
                    const AppEntrance(
                      index: 4,
                      delay: Duration(milliseconds: 160),
                      child: Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: HomeGlass.ink,
                        ),
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
                      // Grow with large system font sizes so the 2-line
                      // title (2 × 12.5 × 1.35 ≈ 34 px at scale 1) still fits.
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(12.5) / 12.5;
                      final tileHeight = (columns > 2 ? 112.0 : 104.0) +
                          (textScale > 1 ? (textScale - 1) * 34 : 0);
                      return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(menus.length, (index) {
                        final item = menus[index];

                        return AppEntrance(
                          index: index,
                          step: const Duration(milliseconds: 40),
                          delay: const Duration(milliseconds: 380),
                          fromScale: 0.86,
                          offsetY: 12,
                          child: SizedBox(
                          width: tileWidth,
                          height: tileHeight, // same size for every tile, even with 2-line titles
                          child: DashboardTile(
                            // Light sweeps the grid row by row after the
                            // tiles have popped in.
                            shineDelay: Duration(
                                milliseconds: 950 +
                                    (index ~/ columns) * 110 +
                                    (index % columns) * 70),
                            title: item.title,
                            icon: menuIcon(item),
                            color: menuColor(item),
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
                                case 25:
                                  Navigator.pushNamed(context, RoutesName.paymentSubmissions);
                                  break;

                              }
                            },
                          ),
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
