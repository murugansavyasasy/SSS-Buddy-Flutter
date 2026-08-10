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
      ref.read(PoListviewProvider.notifier).fetchPoList(widget.customerId);
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
              searchHint: "Search PO number...",
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
                      return const Center(
                        child: Text(
                          "No PO Found",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: poList.length,
                      itemBuilder: (context, index) {
                        final item = poList[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => POPreviewView(
                                    purchaseOrderId: item.id.toString(),
                                  ),
                                ),
                              );
                            },
                            child: POCard(
                              poNumber: item.poNumber,
                              classification: item.classification,
                              nature: item.nature,
                              poDate: item.poDate,
                              validFrom: item.validFrom,
                              validTo: item.validTo,
                              poValue: item.poValue,
                              status: item.status,
                              isBillable: item.isBillable,
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
  final String classification;
  final String nature;
  final String poDate;
  final String validFrom;
  final String validTo;
  final int poValue;
  final String status;
  final bool isBillable;

  const POCard({
    super.key,
    required this.poNumber,
    required this.classification,
    required this.nature,
    required this.poDate,
    required this.validFrom,
    required this.validTo,
    required this.poValue,
    required this.status,
    required this.isBillable,
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case "active":
        return const Color(0xFF2E7D32);
      case "suspended":
        return const Color(0xFFE65100);
      case "cancelled":
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: PO number + status chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  poNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Tags: classification + nature
          Row(
            children: [
              _Tag(label: classification.toUpperCase()),
              const SizedBox(width: 6),
              _Tag(label: nature.toUpperCase(), color: const Color(0xFF5C6BC0)),
              if (isBillable) ...[
                const SizedBox(width: 6),
                const _Tag(
                  label: "BILLABLE",
                  color: Color(0xFF00897B),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),

          // Dates row
          Row(
            children: [
              Expanded(
                child: _InfoBit(
                  icon: Icons.event_outlined,
                  label: "PO Date",
                  value: poDate,
                ),
              ),
              Expanded(
                child: _InfoBit(
                  icon: Icons.date_range_outlined,
                  label: "Valid From",
                  value: validFrom,
                ),
              ),
              Expanded(
                child: _InfoBit(
                  icon: Icons.event_busy_outlined,
                  label: "Valid To",
                  value: validTo,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // PO Value
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "PO VALUE",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  "₹${_formatValue(poValue)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, this.color = const Color(0xFF9E9E9E)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _InfoBit extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBit({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}