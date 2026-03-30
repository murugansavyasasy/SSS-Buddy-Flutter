import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../auth/model/CustomerdetailsModel.dart';
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

          /// BODY
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

          /// BUTTON
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
        AppCard(child: _HeaderCard(item: item)),
        AppCard(
          icon: Icons.contacts_outlined,
          title: "Contact Information",
          child: _ContactSection(item: item),
        ),
        AppCard(
          icon: Icons.business_outlined,
          title: "Company Details",
          child: _CompanySection(item: item),
        ),
        AppCard(
          icon: Icons.receipt_outlined,
          title: "Billing Address",
          child: _BillingSection(item: item),
        ),
        AppCard(
          icon: Icons.local_shipping_outlined,
          title: "Shipping Address",
          child: _ShippingSection(item: item),
        ),
        AppCard(
          icon: Icons.trending_up,
          title: "Sales Information",
          child: _SalesSection(item: item),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _HeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.isActive ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "STATUS: ${item.isActive ? 'ACTIVE' : 'INACTIVE'}",
              style: TextStyle(
                fontSize: 11,
                color: item.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Name + icon ───────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.companyNameVs,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF5C6BC0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.domain, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tags  (customerTypeName  +  customerBranchType) ───────
        Row(
          children: [
            if (item.customerTypeName.isNotEmpty)
              _TagChip(label: item.customerTypeName.toUpperCase()),
            const SizedBox(width: 8),
            if (item.customerBranchType.isNotEmpty)
              _TagChip(label: item.customerBranchType),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEFF8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF5C6BC0),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _ContactSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInfoField(label: "Contact Person", value: item.contactPerson),
        const SizedBox(height: 12),
        AppInfoField(
          label: "Contact Number",
          value: item.contactNumber,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: 12),
        AppInfoField(
          label: "Email ID",
          value: item.mailId,
          prefixIcon: Icons.email_outlined,
        ),
      ],
    );
  }
}

class _CompanySection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _CompanySection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppCopyField(label: "GST NUMBER", value: item.gstinNumber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppCopyField(label: "PAN NUMBER", value: item.panNumber),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppInfoField(label: "TIN Number", value: item.tinNumber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppInfoField(label: "STC Number", value: item.stcNumber),
            ),
          ],
        ),
      ],
    );
  }
}

class _BillingSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _BillingSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAddressBox(tag: "ADDRESS DETAILS", address: item.billingAddress),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "City", value: item.billingCity)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "State", value: item.billingState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child:
                AppInfoField(label: "Pincode", value: item.billingPincode)),
            const SizedBox(width: 10),
            Expanded(
                child:
                AppInfoField(label: "Country", value: item.billingCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Billing Phone", value: item.billingPhoneNumber)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Billing Person", value: item.billingPersonName)),
          ],
        ),
      ],
    );
  }
}

class _ShippingSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _ShippingSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAddressBox(tag: "WAREHOUSE LOCATION", address: item.shipAddress),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "City", value: item.shipCity)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "State", value: item.shipState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(label: "Pincode", value: item.shipPincode)),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(label: "Country", value: item.shipCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: AppInfoField(
                    label: "Shipping Phone",
                    value: item.shipPhoneNumber?.toString() ?? '')),
            const SizedBox(width: 10),
            Expanded(
                child: AppInfoField(
                    label: "Shipping Person",
                    value: item.shipPersonName?.toString() ?? '')),
          ],
        ),
      ],
    );
  }
}

class _SalesSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _SalesSection({required this.item});

  @override
  Widget build(BuildContext context) {
    final name = item.salesPersonName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF5C6BC0),
            child: Text(
              initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ACCOUNT MANAGER",
                style: TextStyle(
                    fontSize: 10, color: Colors.grey, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                name.isEmpty ? '-' : name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// White card with optional icon-badge + title header.
class AppCard extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final Widget child;

  const AppCard({super.key, this.icon, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEFF8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                    Icon(icon, color: const Color(0xFF5C6BC0), size: 18),
                  ),
                const SizedBox(width: 8),
                Text(title!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const Divider(height: 20),
          ],
          child,
        ],
      ),
    );
  }
}

/// Plain label + optional prefix icon + value.
class AppInfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? prefixIcon;

  const AppInfoField({
    super.key,
    required this.label,
    required this.value,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 14, color: const Color(0xFF5C6BC0)),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AppAddressBox extends StatelessWidget {
  final String tag;
  final String address;

  const AppAddressBox({
    super.key,
    required this.tag,
    required this.address,
  });

  bool isUrl(String text) {
    return text.startsWith("http://") || text.startsWith("https://");
  }
  Future<void> openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw "Error";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayText = address.isEmpty ? '-' : address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          isUrl(displayText)
              ? GestureDetector(
            onTap: () => openUrl(context, displayText),
            child: Text(
              displayText,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
              : Text(displayText),
        ],
      ),
    );
  }
}

/// Outlined field with copy-to-clipboard button (GST, PAN …).
class AppCopyField extends StatelessWidget {
  final String label;
  final String value;

  const AppCopyField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (value.isNotEmpty) {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$label copied"),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Icon(Icons.copy_outlined,
                size: 18, color: Color(0xFF5C6BC0)),
          ),
        ],
      ),
    );
  }
}