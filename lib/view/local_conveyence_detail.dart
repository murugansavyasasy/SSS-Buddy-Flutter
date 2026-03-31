import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/local_conveyence.dart';
import 'package:sssbuddy/viewModel/local_convience_detail_viewmodel.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/LocalConveyenceModel.dart';
import '../auth/model/LocalExpenseDetailModel.dart';
import '../components/toolbar_layout.dart';
import 'dashboard.dart';

class LocalConveyenceDetail extends ConsumerStatefulWidget {
  final Localconveyencemodel item;
  const LocalConveyenceDetail({super.key, required this.item});

  @override
  ConsumerState<LocalConveyenceDetail> createState() => _LocalConveyenceDetailState();
}

class _LocalConveyenceDetailState extends ConsumerState<LocalConveyenceDetail> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localconviencedetailProvider.notifier)
          .fetchDetail(widget.item.idLocalExpense.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final localconveyencedetailAsync = ref.watch(localconviencedetailProvider);

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
              title: "Local Conveyence Detail",
              navigateTo: const LocalConveyence(),
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
                child: localconveyencedetailAsync.when(
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(child: Text("No data found"));
                    }
                    final detail = data.first;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildSectionCard(
                            title: "With Bill",
                            color: Colors.blue.shade50,
                            titleColor: Colors.blue.shade800,
                            iconColor: Colors.blue,
                            entries: [
                              _ExpenseEntry("Board & Lodge", detail.BoardLodge),
                              _ExpenseEntry("Conv & Travel", detail.ConvTravel),
                              _ExpenseEntry("Food", detail.Food),
                              _ExpenseEntry("Fuel", detail.Fuel),
                              _ExpenseEntry("Postage & Courier", detail.PostageCourier),
                              _ExpenseEntry("Printing", detail.Printing),
                              _ExpenseEntry("Telephone", detail.Telephone),
                              _ExpenseEntry("Misc", detail.Misc),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            title: "Without Bill",
                            color: Colors.orange.shade50,
                            titleColor: Colors.orange.shade800,
                            iconColor: Colors.orange,
                            entries: [
                              _ExpenseEntry("Board & Lodge", detail.BoardLodgeWithoutBill),
                              _ExpenseEntry("Conv & Travel", detail.ConvTravelWithoutBill),
                              _ExpenseEntry("Food", detail.FoodWithoutBill),
                              _ExpenseEntry("Fuel", detail.FuelWithoutBill),
                              _ExpenseEntry("Postage & Courier", detail.PostageCourierWithoutBill),
                              _ExpenseEntry("Printing", detail.PrintingWithoutBill),
                              _ExpenseEntry("Telephone", detail.TelephoneWithoutBill),
                              _ExpenseEntry("Misc", detail.MiscWithoutBill),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTotalCard(detail),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required Color titleColor,
    required Color iconColor,
    required List<_ExpenseEntry> entries,
  }) {
    double total = entries.fold(0.0, (sum, e) => sum + (double.tryParse(e.value) ?? 0.0));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                Text(
                  "Total: ₹${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey.shade100,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final amount = double.tryParse(entry.value) ?? 0.0;
              final hasAmount = amount > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasAmount
                              ? Colors.grey.shade800
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Text(
                      "₹${entry.value}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasAmount ? FontWeight.w600 : FontWeight.w400,
                        color: hasAmount ? iconColor : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(Localexpensedetailmodel detail) {
    final withBillTotal = [
      detail.BoardLodge, detail.ConvTravel, detail.Food, detail.Fuel,
      detail.PostageCourier, detail.Printing, detail.Telephone, detail.Misc,
    ].fold(0.0, (sum, v) => sum + (double.tryParse(v) ?? 0.0));

    final withoutBillTotal = [
      detail.BoardLodgeWithoutBill, detail.ConvTravelWithoutBill,
      detail.FoodWithoutBill, detail.FuelWithoutBill,
      detail.PostageCourierWithoutBill, detail.PrintingWithoutBill,
      detail.TelephoneWithoutBill, detail.MiscWithoutBill,
    ].fold(0.0, (sum, v) => sum + (double.tryParse(v) ?? 0.0));

    final grandTotal = withBillTotal + withoutBillTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TotalChip(label: "With Bill", amount: withBillTotal, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TotalChip(label: "Without Bill", amount: withoutBillTotal, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TotalChip(label: "Grand Total", amount: grandTotal, color: Colors.yellow.shade300),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntry {
  final String label;
  final String value;
  const _ExpenseEntry(this.label, this.value);
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _TotalChip({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          "₹${amount.toStringAsFixed(2)}",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
