import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../auth/model/CustomerdetailsModel.dart';
import '../components/AppCard.dart';
import '../components/BillingSection.dart';
import '../components/CompanySection.dart';
import '../components/ContactSection.dart';
import '../components/HeaderCard.dart';
import '../components/SalesSection.dart';
import '../components/ShippingSection.dart';
import '../components/toolbar_layout.dart';
import '../view/customer_list_view.dart';
import '../viewModel/customer_details_info_model.dart';
import 'customerpo_view.dart';

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
    await ref
        .read(customerviewinfoProvider.notifier)
        .fetchCustomerInfo(widget.item.idCustomer);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerviewinfoProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const ToolbarLayout(
            title: "Customer Info",
            navigateTo: CustomerListView(),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (data) {
                  if (data.isEmpty) return const Center(child: Text("No data"));
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: CustomerInfoBody(item: data.first),
                  );
                },
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(30, 12, 30, 24),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryprimary,
                    foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomerPOView(customerId: widget.item.idCustomer),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Continue"),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerInfoBody extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const CustomerInfoBody({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(child: HeaderCard(item: item)),
        AppCard(
          icon: Icons.contacts_outlined,
          title: "Contact Information",
          child: ContactSection(item: item),
        ),
        AppCard(
          icon: Icons.business_outlined,
          title: "Company Details",
          child: CompanySection(item: item),
        ),
        AppCard(
          icon: Icons.receipt_outlined,
          title: "Billing Address",
          child: BillingSection(item: item),
        ),
        AppCard(
          icon: Icons.local_shipping_outlined,
          title: "Shipping Address",
          child: ShippingSection(item: item),
        ),
        AppCard(
          icon: Icons.trending_up,
          title: "Sales Information",
          child: SalesSection(item: item),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}