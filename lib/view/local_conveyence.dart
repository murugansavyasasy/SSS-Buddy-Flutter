import 'package:sssbuddy/components/ResponsiveCardList.dart';
import 'package:sssbuddy/components/app_states.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../components/LocalConveyenceCard.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/local_conveyence_viewmodel.dart';
import '../viewModel/login_view_model.dart';
import 'add_localconvenyence.dart';
import 'dashboard.dart';
import 'local_conveyence_detail.dart';

class LocalConveyence extends ConsumerWidget {
  const LocalConveyence({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localconveyenceAsync = ref.watch(localConvienceProvider);
    final loginState = ref.watch(loginProvider);
    final loginData = loginState.value;
    final VimsUserTypeId = loginData?.roleName;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(localConvienceProvider.notifier).filter('');
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddLocalConveyence()),
              );
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),

          body: Column(
            children: [
              ToolbarLayout(
                title: "Local Conveyence",
                navigateTo: const Dashboard(),
                searchHint: "Search name....",
                onSearch: (query) =>
                    ref.read(localConvienceProvider.notifier).filter(query),
                onRefresh: () => ref.invalidate(localConvienceProvider),

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
                        return const AppEmptyView(title: 'No conveyance entries', message: 'Your local travel claims will show up here.', icon: Icons.directions_car_outlined);
                      }
                      return ResponsiveCardList(
                        spacing: 0,
                        // Bottom: clear the add button (ResponsiveCardList
                        // adds the navigation-bar inset).
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return LocalConveyenceCard(
                            item: item,
                            VimsUserTypeId: VimsUserTypeId,
                            onDelete: () {
                              print("Delete Type: $item");
                            },
                            onDetails: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LocalConveyenceDetail(item: item),
                                ),
                              );
                            },
                            // ✏️ EDIT
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddLocalConveyence(),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    error: (e, _) => AppErrorView(error: e, onRetry: () => ref.invalidate(localConvienceProvider)),
                    loading: () => const AppListSkeleton(),
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
