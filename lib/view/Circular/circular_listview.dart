import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Values/Colors/app_colors.dart';
import 'CircularCard.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/circular_post_viewmodel.dart';
import '../dashboard.dart';

class CircularListview extends ConsumerWidget {
  const CircularListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circularAsync = ref.watch(circularviewProvider);
    return PopScope(
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            ref.read(circularviewProvider.notifier).filter('');
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
              title: "Circular List",
              navigateTo: const Dashboard(),
              searchHint: "Search school name....",
              onSearch: (query) =>
                  ref.read(circularviewProvider.notifier).filter(query),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25)),
                ),
                child: circularAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text("Error: $e"),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(
                          child: Text("No Data Found"));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Circularcard(item: item);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    )
    );
  }
}
