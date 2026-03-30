import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../components/LocalConveyenceCard.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/local_conveyence_viewmodel.dart';
import '../viewModel/login_view_model.dart';
import 'dashboard.dart';

class LocalConveyence extends ConsumerWidget {
  const LocalConveyence({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localconveyenceAsync = ref.watch(localConvienceProvider);
    final loginState = ref.watch(loginProvider);
    final loginData = loginState.value;
    final VimsUserTypeId = loginData?.VimsUserTypeId;
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
            ToolbarLayout(
              title: "Local Conveyence",
              navigateTo: const Dashboard(),
              searchHint: "Search name....",
              onSearch: (query) =>  ref.read(localConvienceProvider.notifier).filter(query),
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
                child: localconveyenceAsync.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(child: Text("No Data Found"));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return LocalConveyenceCard(item: item,VimsUserTypeId:VimsUserTypeId);
                      },
                    );
                  },
                  error: (e, _) => Center(child: Text("Error: $e")),
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
