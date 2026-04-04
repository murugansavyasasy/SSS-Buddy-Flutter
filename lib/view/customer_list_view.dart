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
import 'dashboard.dart';

class CustomerListView extends ConsumerWidget {
  const CustomerListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerlistAsync = ref.watch(customerviewProvider);
    final salesAsync = ref.watch(salespersonProvider);
    final dropdownList = salesAsync.value?.map((e) => e.nameValue ?? "").toList() ?? [];
    final salesList = salesAsync.value ?? [];
    String? selectedValue;
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
              dropdownLists: dropdownList,
              selectedMonth: selectedValue != null
                  ? selectedValue ?? '0'
                  : null,
              onMonthChanged: (value) {
                if (value == null || salesList.isEmpty) return;

                final selected = salesList.firstWhere(
                      (e) => e.nameValue == value,
                  orElse: () => salesList.first,
                );

                ref.read(customerviewProvider.notifier)
                    .filterBySalesPerson(selected.idValue.toString());
              },
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
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomerInfoView(item: item),
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
    )
    );
  }
}
