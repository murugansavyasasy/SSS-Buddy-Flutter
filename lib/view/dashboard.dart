import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:sssbuddy/Values/Colors/app_colors.dart';
import '../components/dashboard_card.dart';
import '../components/dashboard_tile.dart';

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.primary,
        body: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          "BS",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Balu Saran",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Admin",
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(Icons.search, color: Colors.white, size: 27),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: bottomPadding,
                      left: 16,
                      right: 16,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.3,
                            children: [
                              DashboardCard(
                                Icons.person,
                                "Create Demo",
                                Colors.purple,
                              ),

                              DashboardCard(
                                Icons.account_balance_wallet,
                                "Demo List",
                                Colors.pink,
                              ),

                              DashboardCard(
                                Icons.payments,
                                "School List",
                                Colors.blue,
                              ),

                              DashboardCard(
                                Icons.folder,
                                "Circular List",
                                Colors.green,
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          DashboardTile(
                            Icons.person,
                            "Status Report",
                            Colors.blue,
                          ),
                          DashboardTile(
                            Icons.description,
                            "Record Collection",
                            Colors.orange,
                          ),
                          DashboardTile(
                            Icons.campaign,
                            "Important Info",
                            Colors.green,
                          ),
                          DashboardTile(
                            Icons.star,
                            "Zero Activity",
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview()
Widget mySampleText() {
  return Dashboard();
}
