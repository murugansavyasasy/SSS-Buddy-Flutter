import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/DemoCard.dart';
import '../components/toolbar_layout.dart';
import '../Values/Colors/app_colors.dart';
import '../viewModel/demolist_view_model.dart';
import 'dashboard.dart';

class DemoListView extends ConsumerWidget {
  const DemoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoAsync = ref.watch(demoviewProvider);
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
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [

            const ToolbarLayout(
              title: "Demo List",
              navigateTo: Dashboard(),
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


              child: demoAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),

                error: (e, _) => Center(
                  child: Text("Error: $e"),
                ),

                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text("No Data Found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return DemoCard(item: item);
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