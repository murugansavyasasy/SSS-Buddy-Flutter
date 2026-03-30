import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';
import 'dashboard.dart';

/// ✅ MAIN SCREEN (NO API)
class CustomerPOView extends StatelessWidget {
  const CustomerPOView({super.key});

  @override
  Widget build(BuildContext context) {

    /// 🔥 HARDCODE DATA
    final List<Map<String, String>> poList = [
      {
        "poNumber": "1001",
        "customerName": "ABC School",
        "date": "12 Mar 2026",
        "status": "Pending"
      },
      {
        "poNumber": "1002",
        "customerName": "XYZ College",
        "date": "10 Mar 2026",
        "status": "Completed"
      },
      {
        "poNumber": "1003",
        "customerName": "Sunrise Academy",
        "date": "08 Mar 2026",
        "status": "Cancelled"
      },
      {
        "poNumber": "1004",
        "customerName": "Green Valley School",
        "date": "05 Mar 2026",
        "status": "Pending"
      },
    ];

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
            /// 🔹 Toolbar
            ToolbarLayout(
              title: "Customer PO List",
              navigateTo: const Dashboard(),
              searchHint: "Search school name....",
              onSearch: (query) {},
            ),

            /// 🔹 List Section
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: poList.length,
                  itemBuilder: (context, index) {
                    final item = poList[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          /// Optional navigation
                        },
                        child: POCard(
                          poNumber: item["poNumber"]!,
                          customerName: item["customerName"]!,
                          date: item["date"]!,
                          status: item["status"]!,
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
class POCard extends StatelessWidget {
  final String poNumber;
  final String customerName;
  final String date;
  final String status;

  const POCard({
    Key? key,
    required this.poNumber,
    required this.customerName,
    required this.date,
    required this.status,
  }) : super(key: key);

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PO #$poNumber",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(customerName),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}