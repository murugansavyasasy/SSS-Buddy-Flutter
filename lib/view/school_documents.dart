import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/viewModel/schooldocuments_view_model.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/SchoolDocuments.dart';
import '../components/SchoolDocumentCard.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/demolist_view_model.dart';
import 'dashboard.dart';

class SchoolDocuments extends ConsumerWidget {
  const SchoolDocuments({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schooldocumentsAsync = ref.watch(schooldocumentsviewProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(schooldocumentsviewProvider.notifier).filter('');
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
          body: Column(
            children: [
              ToolbarLayout(
                title: "School Documents",
                navigateTo: const Dashboard(),
                searchHint: "Search document name....",
                onSearch: (query) => ref
                    .read(schooldocumentsviewProvider.notifier)
                    .filter(query),
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
                  child: schooldocumentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                    data: (list) {
                      if (list.isEmpty) {
                        return const Center(child: Text("No Data Found"));
                      }

                      final Map<String, List<Schooldocuments>> grouped = {};
                      for (final item in list) {
                        final key = item.project_type.isEmpty
                            ? 'Videos'
                            : item.project_type;
                        grouped.putIfAbsent(key, () => []).add(item);
                      }
                      final sections = grouped.entries.toList();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: sections.length,
                        itemBuilder: (context, i) {
                          final section = sections[i];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 10,
                                  top: i == 0 ? 0 : 20,
                                ),
                                child: Text(
                                  section.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    letterSpacing: 0.06 * 12,
                                  ),
                                ),
                              ),
                              ...section.value.map(
                                (item) => SchoolDocumentCard(item: item),
                              ),
                            ],
                          );
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
