import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/school_listview.dart';
import 'package:sssbuddy/view/UsageCount/usage_count.dart';
import '../../Values/Colors/app_colors.dart';
import '../../components/toolbar_layout.dart';
import '../../utils/routes/routes_name.dart';
import '../ManagementInfo/management_info.dart';
import '../dashboard.dart';
import 'exam_table.dart';
import 'table_row_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/school_listview.dart';
import 'package:sssbuddy/view/UsageCount/usage_count.dart';
import '../../Values/Colors/app_colors.dart';
import '../../components/toolbar_layout.dart';
import '../dashboard.dart';
import 'exam_table.dart';
import 'table_row_model.dart';

class SchooldetailView extends ConsumerWidget {
  final Map<String, dynamic> item;

  const SchooldetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "School List Detail",
              navigateTo: SchoolListview(),
                isSearch : false
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      ExamTable(rows: _buildRows()),
                      const SizedBox(height: 8),
                      _buildFooter(context),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A5C),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Text(
        (item['SchoolName'] ?? '_').toString().toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  List<TableRowModel> _buildRows() {
    return [
      TableRowModel(label: 'School Id', value: item['SchoolID']),
      TableRowModel(label: 'School Address', value: item['Address']),
      TableRowModel(label: 'School City', value: item['City']),
      TableRowModel(label: 'Contact No', value: item['UserName']),
      TableRowModel(label: 'Email', value: item['ContactEmail']),
      TableRowModel(label: 'Status', value: item['Status']),
      TableRowModel(label: 'From Date', value: item['PeriodFrom']),
      TableRowModel(label: 'To Date', value: item['PeriodTo']),
      TableRowModel(label: 'Student Count', value: item['Students']),
      TableRowModel(label: 'Staff Count', value: item['Staff']),
      TableRowModel(label: 'Contact Person 1', value: item['ContactPerson1']),
      TableRowModel(label: 'Contact Number 1', value: item['ContactNumber1']),
      TableRowModel(label: 'Contact Person 2', value: item['ContactPerson2']),
      TableRowModel(label: 'Contact Number 2', value: item['ContactNumber2']),
      TableRowModel(label: 'Contact Email', value: item['ContactEmail']),
      TableRowModel(
        label: 'Web User Name',
        value: item['UserName'],
        isLast: true,
      ),
    ];
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C).withOpacity(0.05),
        border: Border.all(color: const Color(0xFF1A3A5C).withOpacity(0.25)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UsageCountScreen(item: item),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
              ),
              child: const Text("Usage Count"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManagementInfo(item: item),
                  ),
                );
              },
              child: const Text("Management Info"),
            ),
          ),
        ],
      ),
    );
  }
}
