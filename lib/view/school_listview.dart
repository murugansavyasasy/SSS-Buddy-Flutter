import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/school_detail/schooldetail_view.dart';
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

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(schoolStatsProvider.notifier).filter('');
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              ToolbarLayout(
                title: "School List",
                navigateTo: Dashboard(),
                searchHint: "Search school name....",
                onSearch: (query) =>
                    ref.read(schoolStatsProvider.notifier).filter(query),
                onRefresh: () => ref.invalidate(schoolStatsProvider),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FB),
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─────────────────────────────
                        // FILTER CHIPS
                        // ─────────────────────────────
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
                          child: SizedBox(
                            height: 42,
                            child: schoolAsync.when(
                              data: (stats) {
                                return ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    filtercard("All", stats.totalSchools,
                                        SchoolFilter.all, ref,
                                        icon: Icons.apps_rounded,
                                        color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    filtercard("School Live", stats.liveActive,
                                        SchoolFilter.liveActive, ref,
                                        icon: Icons.check_circle_rounded,
                                        color: Colors.green),
                                    const SizedBox(width: 10),
                                    filtercard(
                                        "School Inactive",
                                        stats.liveInactive,
                                        SchoolFilter.liveInactive,
                                        ref,
                                        icon: Icons.pause_circle_rounded,
                                        color: Colors.orange),
                                    const SizedBox(width: 10),
                                    filtercard("POC Live", stats.pocActive,
                                        SchoolFilter.pocActive, ref,
                                        icon: Icons.rocket_launch_rounded,
                                        color: Colors.teal),
                                    const SizedBox(width: 10),
                                    filtercard("POC Inactive", stats.pocInactive,
                                        SchoolFilter.pocInactive, ref,
                                        icon: Icons.hourglass_bottom_rounded,
                                        color: Colors.amber.shade800),
                                    const SizedBox(width: 10),
                                    filtercard("Stopped", stats.stopped,
                                        SchoolFilter.stopped, ref,
                                        icon: Icons.cancel_rounded,
                                        color: Colors.red),
                                  ],
                                );
                              },
                              loading: () => const SizedBox(),
                              error: (e, _) => Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                                child: Text("Error: $e"),
                              ),
                            ),
                          ),
                        ),

                        // ─────────────────────────────
                        // LIST
                        // ─────────────────────────────
                        Expanded(
                          child: schoolAsync.when(
                            data: (stats) {
                              final schoolList = stats.rawList;
                              final filteredList =
                              applyFilter(schoolList, selectedFilter);

                              if (filteredList.isEmpty) {
                                return const _EmptyView();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 14, 20, 6),
                                    child: Text(
                                      '${filteredList.length} '
                                          '${filteredList.length == 1 ? 'school' : 'schools'}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: RefreshIndicator(
                                      color: AppColors.primary,
                                      onRefresh: () async {
                                        ref.invalidate(schoolStatsProvider);
                                        await Future.delayed(
                                          const Duration(milliseconds: 600),
                                        );
                                      },
                                      child: ListView.builder(
                                        physics:
                                        const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 4, 16, 24),
                                        itemCount: filteredList.length,
                                        itemBuilder: (context, index) {
                                          final item = filteredList[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SchooldetailView(
                                                            item: item),
                                                  ),
                                                );
                                              },
                                              child: SchoolCard(item: item),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline_rounded,
                                        size: 44, color: Colors.red.shade300),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Error: $e",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.red.shade400,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: () =>
                                          ref.invalidate(schoolStatsProvider),
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget filtercard(
    String text,
    int count,
    SchoolFilter filter,
    WidgetRef ref, {
      required IconData icon,
      required Color color,
    }) {
  final selected = ref.watch(selectedFilterProvider);
  final isSelected = selected == filter;

  return GestureDetector(
    onTap: () {
      ref.read(selectedFilterProvider.notifier).state = filter;
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 42,
      padding: const EdgeInsets.only(left: 12, right: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
        ),
        boxShadow: isSelected
            ? [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.25)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_outlined,
              size: 42,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No Data Found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try a different filter or search",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}