import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/po_preview_view.dart';

import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/po_list_viewmodal.dart';
import 'dashboard.dart';

class CustomerPOView extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerPOView({super.key, required this.customerId});

  @override
  ConsumerState<CustomerPOView> createState() => _CustomerPOViewState();
}

class _CustomerPOViewState extends ConsumerState<CustomerPOView> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(PoListviewProvider.notifier)
          .fetchPoList(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final poState = ref.watch(PoListviewProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: "Customer PO List",
              navigateTo: const Dashboard(),
              searchHint: "Search...",
              onSearch: (query) {
                ref.read(PoListviewProvider.notifier).filter(query);
              },
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: poState.when(
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                  const Center(child: Text("Failed to load data")),
                  data: (poList) {
                    if (poList.isEmpty) {
                      return const Center(child: Text("No PO Found"));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: poList.length,
                      itemBuilder: (context, index) {
                        final item = poList[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => POPreviewView(
                                    purchaseOrderId: item.idValue.toString(),
                                  ),
                                ),
                              );
                            },
                            child: POCard(
                              poNumber: item.idValue.toString(),
                              customerName: item.nameValue,
                              date: "N/A",
                              status: "Pending",
                            ),
                          ),
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
    );
  }
}
class POCard extends StatelessWidget {
  final String poNumber;
  final String customerName;
  final String date;
  final String status;

  const POCard({
    super.key,
    required this.poNumber,
    required this.customerName,
    required this.date,
    required this.status,
  });

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "PO #$poNumber",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              /// 🔥 Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(customerName),
            ],
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                date,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}