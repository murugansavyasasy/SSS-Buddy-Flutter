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
                    loading: () =>
                    const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text("Error: $e")),
                    data: (list) {
                      if (list.isEmpty) {
                        return const Center(child: Text("No Data Found"));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding:
                        const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        itemCount: list.length + (isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= list.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

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