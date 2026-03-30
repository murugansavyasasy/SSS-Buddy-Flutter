import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Customer Info",
              navigateTo: CustomerListView(),
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
                child: state.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text("Error: $e")),
                  data: (data) {
                    if (data.isEmpty) {
                      return const Center(child: Text("No data found"));
                    }

                    final item = data.first;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical:6),
                      child: _CustomerInfoBody(item: item),
                    );
                  },
                ),
              ),
            ),

            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(30, 12, 30, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
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
                        builder: (context) =>
                            CustomerPOView(),
                      ),
                    );
                  },
                  child: Row(
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
      ),
    );
  }
}

class _CustomerInfoBody extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _CustomerInfoBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        children: [
          _HeaderCard(item: item),
          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.contacts_outlined,
            title: "Contact Information",
            child: _ContactSection(item: item),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.business_outlined,
            title: "Company Details",
            child: _CompanySection(item: item),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.receipt_long_outlined,
            title: "Billing Address",
            child: _BillingSection(item: item),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.local_shipping_outlined,
            title: "Shipping Address",
            child: _ShippingSection(item: item),
          ),

          const SizedBox(height: 12),

          _SectionCard(
            icon: Icons.trending_up_outlined,
            title: "Sales Information",
            child: _SalesSection(item: item),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _HeaderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                item.isActive ? "STATUS: ACTIVE" : "STATUS: INACTIVE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: item.isActive
                      ? const Color(0xFF22C55E)
                      : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name + image
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName.isNotEmpty
                          ? item.customerName
                          : '-',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    if (item.companyNameVs.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.companyNameVs,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 28),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (item.customerTypeName.isNotEmpty)
                _TagChip(label: item.customerTypeName.toUpperCase()),
              if (item.customerBranchType.isNotEmpty)
                _TagChip(label: item.customerBranchType.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4F46E5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: const Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
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
        _InfoField(label: "Contact Person", value: item.contactPerson),
        const SizedBox(height: 12),
        _InfoFieldWithIcon(
          label: "Contact Number",
          value: item.contactNumber,
          icon: Icons.phone_outlined,
          iconColor: const Color(0xFF4F46E5),
        ),
        const SizedBox(height: 12),
        _InfoFieldWithIcon(
          label: "Email ID",
          value: item.mailId,
          icon: Icons.mail_outline,
          iconColor: const Color(0xFF4F46E5),
        ),
        if (_hasValue(item.alternateContactPerson)) ...[
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          _InfoField(
            label: "Alt. Contact Person",
            value: item.alternateContactPerson?.toString() ?? '-',
          ),
          const SizedBox(height: 12),
          _InfoField(
            label: "Alt. Number",
            value: item.alternateContactNumber?.toString() ?? '-',
          ),
          const SizedBox(height: 12),
          _InfoField(
            label: "Alt. Email",
            value: item.alternateMailId?.toString() ?? '-',
          ),
        ],
      ],
    );
  }

  bool _hasValue(dynamic v) =>
      v != null && v.toString().trim().isNotEmpty;
}

class _CompanySection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _CompanySection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _HighlightBox(
                label: "GST NUMBER",
                value: item.gstinNumber,
                trailingIcon: Icons.copy_outlined,
                onCopy: () => _copy(context, item.gstinNumber),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HighlightBox(
                label: "PAN NUMBER",
                value: item.panNumber,
                trailingIcon: Icons.copy_outlined,
                onCopy: () => _copy(context, item.panNumber),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoField(label: "TIN Number", value: item.tinNumber),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoField(label: "STC Number", value: item.stcNumber),
            ),
          ],
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard"), duration: Duration(seconds: 1)),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData trailingIcon;
  final VoidCallback onCopy;
  const _HighlightBox({
    required this.label,
    required this.value,
    required this.trailingIcon,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onCopy,
                child: Icon(trailingIcon, size: 15, color: const Color(0xFF4F46E5)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillingSection extends StatelessWidget {
  final Customerdetailsinfomodelclass item;
  const _BillingSection({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressBox(
          tag: "ADDRESS DETAILS",
          address: item.billingAddress,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _InfoField(label: "City", value: item.billingCity)),
            const SizedBox(width: 10),
            Expanded(child: _InfoField(label: "State", value: item.billingState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _InfoField(label: "Pincode", value: item.billingPincode)),
            const SizedBox(width: 10),
            Expanded(child: _InfoField(label: "Country", value: item.billingCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _InfoField(label: "Billing Phone", value: item.billingPhoneNumber)),
            const SizedBox(width: 10),
            Expanded(child: _InfoField(label: "Billing Person", value: item.billingPersonName)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AddressBox(
          tag: "WAREHOUSE LOCATION",
          address: item.shipAddress,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _InfoField(label: "City", value: item.shipCity)),
            const SizedBox(width: 10),
            Expanded(child: _InfoField(label: "State", value: item.shipState)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _InfoField(label: "Pincode", value: item.shipPincode)),
            const SizedBox(width: 10),
            Expanded(child: _InfoField(label: "Country", value: item.shipCountry)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _InfoField(
                label: "Shipping Phone",
                value: item.shipPhoneNumber?.toString() ?? '-',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InfoField(
                label: "Shipping Person",
                value: item.shipPersonName?.toString() ?? '-',
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4F46E5),
                child: Text(
                  item.salesPersonName.isNotEmpty
                      ? item.salesPersonName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ACCOUNT MANAGER",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.salesPersonName.isNotEmpty
                        ? item.salesPersonName
                        : '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        if (item.headCustomerName != null &&
            item.headCustomerName.toString().isNotEmpty) ...[
          const SizedBox(height: 14),
          _InfoField(
            label: "Head Customer Name",
            value: item.headCustomerName.toString(),
          ),
        ],

        if (item.remarks != null && item.remarks.toString().isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            "Remarks",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              '"${item.remarks}"',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF78350F),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  const _InfoField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}

class _InfoFieldWithIcon extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _InfoFieldWithIcon({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddressBox extends StatelessWidget {
  final String tag;
  final String address;
  const _AddressBox({required this.tag, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            address.isNotEmpty ? address : '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A2E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}