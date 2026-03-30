import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/po_details_modal.dart';
import '../components/toolbar_layout.dart';
import '../view/customer_list_view.dart';
import '../viewModel/po_preview_viewmodel.dart';
import 'customer_info_view.dart'; // AppCard, AppInfoField, AppAddressBox, AppCopyField

class POPreviewView extends ConsumerStatefulWidget {
  final String purchaseOrderId;
  const POPreviewView({super.key, required this.purchaseOrderId});

  @override
  ConsumerState<POPreviewView> createState() => _POPreviewViewState();
}

class _POPreviewViewState extends ConsumerState<POPreviewView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    await ref
        .read(poDetailsProvider.notifier)
        .getPoDetails(widget.purchaseOrderId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(poDetailsProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          const ToolbarLayout(
            title: "PO Preview",
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
                  if (data.isEmpty) {
                    return const Center(child: Text("No PO data found"));
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: POPreviewBody(po: data.first),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class POPreviewBody extends StatelessWidget {
  final PoDetailsModel po;
  const POPreviewBody({super.key, required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(child: _POHeaderCard(po: po)),
        AppCard(
          icon: Icons.person_outline,
          title: "Customer Info",
          child: _CustomerInfoSection(po: po),
        ),
        AppCard(
          icon: Icons.receipt_outlined,
          title: "PO Details",
          child: _PODetailsSection(po: po),
        ),
        AppCard(
          icon: Icons.payments_outlined,
          title: "Pricing & Tax",
          child: _PricingSection(po: po),
        ),
        AppCard(
          icon: Icons.event_available_outlined,
          title: "Validity & Billing",
          child: _ValiditySection(po: po),
        ),
        AppCard(
          icon: Icons.summarize_outlined,
          title: "Summary",
          child: _SummarySection(po: po),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _POHeaderCard extends StatelessWidget {
  final PoDetailsModel po;
  const _POHeaderCard({required this.po});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.description, size: 26, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                po.poNumber,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "PO Date: ${po.poDate}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            po.resultMessage,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700),
          ),
        ),
      ],
    );
  }
}

class _CustomerInfoSection extends StatelessWidget {
  final PoDetailsModel po;
  const _CustomerInfoSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Customer ID", value: po.customerId)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Customer Type", value: po.customerType)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Staff Component", value: po.staffComponent)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Details From", value: po.poDetailsFrom)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Hard Copy", value: po.hardCopyReceived)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Received On", value: po.hardCopyReceivedOn)),
          ],
        ),
      ],
    );
  }
}

class _PODetailsSection extends StatelessWidget {
  final PoDetailsModel po;
  const _PODetailsSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "PO ID", value: po.purchaseOrderId)),
            const SizedBox(width: 10),
            Expanded(child: AppInfoField(label: "PO Type", value: po.poType)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Calls Type", value: po.callsType)),
            const SizedBox(width: 10),
            Expanded(child: AppInfoField(label: "Module", value: po.module)),
          ],
        ),
        if (po.scanCopyFilePath.isNotEmpty) ...[
          const SizedBox(height: 10),
          AppAddressBox(tag: "SCAN COPY PATH", address: po.scanCopyFilePath),
        ],
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  final PoDetailsModel po;
  const _PricingSection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Student Rate/yr",
                    value: "₹ ${po.studentRate}")),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Rate/month",
                    value: "₹ ${po.studentRatePerMonth}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Student Count", value: po.studentCount)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Tax Rate", value: "${po.taxRate}%")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Tax Component", value: po.taxComponent)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Advance Amount",
                    value: "₹ ${po.advanceAmount}")),
          ],
        ),
      ],
    );
  }
}

class _ValiditySection extends StatelessWidget {
  final PoDetailsModel po;
  const _ValiditySection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Valid From", value: po.poValidFrom)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "Valid To", value: po.poValidTo)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Go Live Date", value: po.goLiveDate)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Next Invoice", value: po.nextInvoiceDate)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Payment Type", value: po.paymentType)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Payment Cycle",
                    value: "${po.paymentCycle} months")),
          ],
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  final PoDetailsModel po;
  const _SummarySection({required this.po});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Amount (with tax)",
                    value: "₹ ${po.poAmountWithTax}")),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Amount (excl. tax)",
                    value: "₹ ${po.poAmountWithoutTax}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Calls Cost", value: "₹ ${po.callsCost}")),
            const SizedBox(width: 10),
            Expanded(
                child:
                AppInfoField(label: "SMS Cost", value: "₹ ${po.smsCost}")),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Insufficient", value: po.isInsufficient)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Not to Bill",
                    value: po.notToBill ? "Yes" : "No")),
          ],
        ),
      ],
    );
  }
}