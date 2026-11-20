import 'package:flutter/material.dart';
import 'package:sssbuddy/components/app_states.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/po_details_modal.dart';
import '../components/AppCard.dart';
import '../components/CustomerInfoSection.dart';
import '../components/PODetailsSection.dart';
import '../components/POHeaderCard.dart';
import '../components/PricingSection.dart';
import '../components/SummarySection.dart';
import '../components/ValiditySection.dart';
import '../components/toolbar_layout.dart';
import '../view/customer_list_view.dart';
import '../viewModel/po_preview_viewmodel.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(poDetailsProvider.notifier)
          .getPoDetails(widget.purchaseOrderId); // one-time fetch
    });
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
                loading: () => const AppListSkeleton(),
                error: (e, _) => AppErrorView(error: e, onRetry: () => ref.invalidate(poDetailsProvider)),
                data: (data) {
                  if (data.isEmpty) {
                    return const AppEmptyView(title: 'No PO details', message: 'This purchase order has no line items yet.', icon: Icons.receipt_long_outlined);
                  }
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        14, 14, 14, 14 + MediaQuery.paddingOf(context).bottom),
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
        AppCard(child: POHeaderCard(po: po)),
        AppCard(
          icon: Icons.person_outline,
          title: "Customer Info",
          child: CustomerInfoSection(po: po),
        ),
        AppCard(
          icon: Icons.receipt_outlined,
          title: "PO Details",
          child: PODetailsSection(po: po),
        ),
        AppCard(
          icon: Icons.payments_outlined,
          title: "Pricing & Tax",
          child: PricingSection(po: po),
        ),
        AppCard(
          icon: Icons.event_available_outlined,
          title: "Validity & Billing",
          child: ValiditySection(po: po),
        ),
        AppCard(
          icon: Icons.summarize_outlined,
          title: "Summary",
          child: SummarySection(po: po),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}