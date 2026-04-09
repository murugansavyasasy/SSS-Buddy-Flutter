import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/add_advance_tour_expense.dart';
import 'package:sssbuddy/viewModel/advance_tourexpense_viewmodel.dart';

import '../Values/Colors/app_colors.dart';
import '../components/TourExpenseCard.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/login_view_model.dart';
import 'dashboard.dart';

class AdvanceTourExpense extends ConsumerWidget {
  const AdvanceTourExpense({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourAsync = ref.watch(tourexpenseprovider);
    final loginData = ref.read(loginProvider).value;
    final directorLogin = loginData?.VimsUserTypeId;
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(tourexpenseprovider.notifier).filter('');
        }
      },

      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AddAdvanceTourExpense()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              ToolbarLayout(
                title: "Advance Tour Expense",
                navigateTo: const Dashboard(),
                searchHint: "Search employee name....",
                onSearch: (query) =>
                    ref.read(tourexpenseprovider.notifier).filter(query),
              ),
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
                  child: tourAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                    data: (list) {
                      if (list.isEmpty) {
                        return const Center(child: Text("No Data Found"));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return TourExpenseCard(item: item, directorLogin: directorLogin ?? '');
                        },
                      );
                    },
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
