import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/customer_list_view.dart';
import 'package:sssbuddy/view/school_listview.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../auth/model/CustomerdetailsModel.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/customer_details_info_model.dart';

class CustomerInfoView extends ConsumerStatefulWidget {
  final Customerdetailsmodel item;
  const CustomerInfoView({super.key, required this.item});

  @override
  ConsumerState<CustomerInfoView> createState() => _CustomerInfoScreenState();
}

class _CustomerInfoScreenState extends ConsumerState<CustomerInfoView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final vm = ref.read(customerviewinfoProvider.notifier);
    await vm.fetchCustomerInfo(widget.item.idCustomer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerviewinfoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Customer Info",
              navigateTo: CustomerListView(),
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (data) {
                  if (data.isEmpty) {
                    return const Center(child: Text("No data found"));
                  }

                  final item = data.first;

                  return Column(
                    children: [
                      Text(item.customerName ?? '-'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
