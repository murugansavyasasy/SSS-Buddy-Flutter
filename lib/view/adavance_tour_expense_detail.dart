import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/AdvanceTourExpenseModel.dart';
import 'package:sssbuddy/view/advance_tour_expense.dart';
import 'package:sssbuddy/viewModel/advance_tour_detail_viewmodel.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/AdvanceTourExpenseDetailModel.dart';
import '../components/ExpenseCard.dart';
import '../components/ExpenseItem.dart';
import '../components/GrandTotalCard.dart';
import '../components/SectionHeader.dart';
import '../components/toolbar_layout.dart';

class AdavanceTourExpenseDetail extends ConsumerStatefulWidget {
  final Advancetourexpensemodel item;
  const AdavanceTourExpenseDetail({super.key, required this.item});

  @override
  ConsumerState<AdavanceTourExpenseDetail> createState() =>
      _AdavanceTourExpenseDetailState();
}

class _AdavanceTourExpenseDetailState
    extends ConsumerState<AdavanceTourExpenseDetail> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(advancetourdetailProvider.notifier)
          .fetchDetail(widget.item.idTourExpense.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final advancetourdetailProviderAsync = ref.watch(advancetourdetailProvider);

    //changed by chanthru

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
              title: "Advance Tour Expense Detail",
              navigateTo: const AdvanceTourExpense(),
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
                child: advancetourdetailProviderAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(child: Text("No data found"));
                    }
                    final detail = data.first;
                    return _buildDetailContent(detail);
                  },
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(Advancetourexpensedetailmodel detail) {
    final withBillItems = [
      ExpenseItem("Board & Lodge", detail.boardLodge),
      ExpenseItem("Business Promo", detail.businessPromo),
      ExpenseItem("Conv & Travel", detail.convTravel),
      ExpenseItem("Food", detail.food),
      ExpenseItem("Fuel", detail.fuel),
      ExpenseItem("Postage & Courier", detail.postageCourier),
      ExpenseItem("Printing", detail.printing),
      ExpenseItem("Travel", detail.travel),
      ExpenseItem("Miscellaneous", detail.misc),
    ];

    final withoutBillItems = [
      ExpenseItem("Board & Lodge", detail.boardLodgeWithoutBill),
      ExpenseItem("Business Promo", detail.businessPromoWithoutBill),
      ExpenseItem("Conv & Travel", detail.convTravelWithoutBill),
      ExpenseItem("Food", detail.foodWithoutBill),
      ExpenseItem("Fuel", detail.fuelWithoutBill),
      ExpenseItem("Postage & Courier", detail.postageCourierWithoutBill),
      ExpenseItem("Printing", detail.printingWithoutBill),
      ExpenseItem("Travel", detail.travelWithoutBill),
      ExpenseItem("Miscellaneous", detail.miscWithoutBill),
    ];

    final totalWithBill =
    withBillItems.fold<double>(0, (sum, e) => sum + e.amount);
    final totalWithoutBill =
    withoutBillItems.fold<double>(0, (sum, e) => sum + e.amount);
    final grandTotal = totalWithBill + totalWithoutBill;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: "With Bill",
            icon: Icons.receipt_long_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          ExpenseCard(
            items: withBillItems,
            totalLabel: "Total (With Bill)",
            total: totalWithBill,
            accentColor: AppColors.primary,
          ),

          const SizedBox(height: 20),

          SectionHeader(
            title: "Without Bill",
            icon: Icons.receipt_outlined,
            color: Colors.orange,
          ),
          const SizedBox(height: 10),
          ExpenseCard(
            items: withoutBillItems,
            totalLabel: "Total (Without Bill)",
            total: totalWithoutBill,
            accentColor: Colors.orange,
          ),

          const SizedBox(height: 20),

          GrandTotalCard(grandTotal: grandTotal),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}