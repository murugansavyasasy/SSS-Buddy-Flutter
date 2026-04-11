import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/Alert/widget/alert_card.dart';

import '../../Values/Colors/app_colors.dart';
import '../../components/ComingSoonPage.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/alert_viewmodel.dart';
import '../dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Values/Colors/app_colors.dart';
import '../../components/toolbar_layout.dart';
import '../../viewModel/alert_viewmodel.dart';
import '../../auth/model/AlertModel.dart';
import '../dashboard.dart';

class AlertScreen extends ConsumerWidget {
  const AlertScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertAsync = ref.watch(AlertViewmodelProvider);

    return PopScope(
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
                title: "Alerts",
                navigateTo: const Dashboard(),
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
                  child: alertAsync.when(
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text("Error: $e",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(AlertViewmodelProvider.notifier).refresh(),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                    data: (alerts) {
                      if (alerts.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 64, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                "No alerts found",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(AlertViewmodelProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: alerts.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return AlertCard(alert: alerts[index]);
                          },
                        ),
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
