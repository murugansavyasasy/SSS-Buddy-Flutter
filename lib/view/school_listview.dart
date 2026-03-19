import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/SchoolFilter.dart';
import '../components/school_card.dart';
import '../components/toolbar_layout.dart';
import '../provider/app_providers.dart';
import '../utils/filter_utils.dart';
import '../viewModel/schoollist_view_model.dart';
import 'dashboard.dart';

class SchoolListview extends ConsumerWidget {
  const SchoolListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolAsync = ref.watch(schoolStatsProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);

    return WillPopScope(
      onWillPop: () async {
        print("Back pressed");
        // custom logic here
        return true; // allow back
      },

    child:  AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "School List",
              navigateTo: Dashboard(),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                      child: schoolAsync.when(
                        data: (stats) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                filtercard("All (${stats.totalSchools})", SchoolFilter.all, ref),
                                const SizedBox(width: 12),
                                filtercard("School Live (${stats.liveActive})", SchoolFilter.liveActive, ref),
                                const SizedBox(width: 12),
                                filtercard("School Inactive (${stats.liveInactive})", SchoolFilter.liveInactive, ref),
                                const SizedBox(width: 12),
                                filtercard("POC Live (${stats.pocActive})", SchoolFilter.pocActive, ref),
                                const SizedBox(width: 12),
                                filtercard("POC Inactive (${stats.pocInactive})", SchoolFilter.pocInactive, ref),
                                const SizedBox(width: 12),
                                filtercard("Stopped (${stats.stopped})", SchoolFilter.stopped, ref),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (e, _) => Text("Error: $e"),
                      ),
                    ),


                    const SizedBox(height: 8),


                    Expanded(
                      child: schoolAsync.when(
                        data: (stats) {
                          final schoolList = stats.rawList;
                          final filteredList = applyFilter(schoolList, selectedFilter);

                          if (filteredList.isEmpty) {
                            return const Center(child: Text("No Data Found"));
                          }

                          return MediaQuery.removePadding(
                            context: context,
                            removeTop: true,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                return SchoolCard(item: item);
                              },
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text("Error: $e"),
                      ),
                    ),
                  ],
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


Widget filtercard(String text, SchoolFilter filter, WidgetRef ref) {
  final selected = ref.watch(selectedFilterProvider);
  final isSelected = selected == filter;

  return GestureDetector(
    onTap: () {
      ref.read(selectedFilterProvider.notifier).state = filter;
    },
    child: Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}