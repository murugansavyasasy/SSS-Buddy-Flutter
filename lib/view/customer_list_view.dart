import 'package:sssbuddy/components/ResponsiveCardList.dart';
import 'package:sssbuddy/components/app_states.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/customer_info_view.dart';
import '../Values/Colors/app_colors.dart';
import '../components/customer_card_details.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/customer_details_viewmodel.dart';
import '../viewModel/sales_person_viewmodel.dart';
import 'customerpo_view.dart';
import 'dashboard.dart';

class CustomerListView extends ConsumerStatefulWidget {
  const CustomerListView({super.key});

  @override
  ConsumerState<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends ConsumerState<CustomerListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(customerviewProvider.notifier).refreshList();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerviewProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerlistAsync = ref.watch(customerviewProvider);
    final isLoadingMore = ref.watch(isLoadingMoreProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(customerviewProvider.notifier).filter('');
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
                title: "Customer List",
                navigateTo: const Dashboard(),
                backendSearch: true,
                searchHint: "Search school name....",
                onSearch: (query) =>
                    ref.read(customerviewProvider.notifier).filter(query),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: customerlistAsync.when(
                    loading: () => const AppListSkeleton(),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              e.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(customerviewProvider.notifier)
                                  .refreshList(),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (list) {
                      if (list.isEmpty) {
                        return const AppEmptyView(title: 'No customers found', message: 'Try a different search.', icon: Icons.business_outlined);
                      }
                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(customerviewProvider.notifier)
                            .refreshList(),
                        child: ResponsiveCardList(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                          spacing: 0,
                          itemCount: list.length,
                          footer: isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : null,
                          itemBuilder: (context, index) {
                            final item = list[index];

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        // CustomerInfoView(item: item),
                                        CustomerPOView(customerId: item.id),
                                  ),
                                );
                              },
                              child: CustomerCardDetails(item: item),
                            );
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
