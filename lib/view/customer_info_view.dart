import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../viewModel/customer_details_info_model.dart';
import '../viewModel/customer_details_viewmodel.dart';


class CustomerInfoView extends ConsumerStatefulWidget {
  final dynamic item;
  const CustomerInfoView({super.key, required this.item});

  @override
  ConsumerState<CustomerInfoView> createState() => _CustomerInfoScreenState();
}

class _CustomerInfoScreenState extends ConsumerState<CustomerInfoView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerId = widget.item['idCustomer']?.toString() ?? '0';
      ref.read(customerviewinfoProvider.notifier).fetchCustomerInfo(customerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerDetailAsync = ref.watch(customerviewinfoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: customerDetailAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white)),
          error: (e, _) => Center(
              child: Text("Error: $e",
                  style: const TextStyle(color: Colors.white))),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                  child: Text("No Data",
                      style: TextStyle(color: Colors.white)));
            }
            return _CustomerInfoBody(
              info: list.first,
              tabController: _tabController,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Body
// ─────────────────────────────────────────────────────────────
class _CustomerInfoBody extends StatelessWidget {
  final Customerdetailsinfomodelclass info;
  final TabController tabController;

  const _CustomerInfoBody({required this.info, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final initials = info.customerName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Column(
      children: [
        // ── Hero header ──
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Customer Details",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: info.isActive
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          info.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.customerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.tag,
                                size: 13, color: Colors.white60),
                            const SizedBox(width: 3),
                            Text(info.tallyCustomerId,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            if (info.customerTypeName.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.apartment,
                                  size: 13, color: Colors.white60),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  info.customerTypeName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _QuickChip(
                    icon: Icons.support_agent_outlined,
                    label: info.salesPersonName.isNotEmpty
                        ? info.salesPersonName
                        : 'No sales person',
                  ),
                  const SizedBox(width: 10),
                  _QuickChip(
                    icon: Icons.mail_outline,
                    label: info.mailId.isNotEmpty ? info.mailId : 'No email',
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Tab section ──
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF8E8EA0),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: "Contact Info"),
                      Tab(text: "Address"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _ContactTab(info: info),
                      _AddressTab(info: info),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Tab 1 — Contact Info
// ─────────────────────────────────────────────────────────────
class _ContactTab extends StatelessWidget {
  final Customerdetailsinfomodelclass info;
  const _ContactTab({required this.info});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _InfoCard(
            title: "Primary Contact",
            icon: Icons.person_outline,
            iconColor: const Color(0xFF534AB7),
            iconBg: const Color(0xFFEEEDFE),
            entries: [
              if (info.contactPerson.isNotEmpty)
                _InfoEntry("Contact Person", info.contactPerson),
              if (info.contactNumber.isNotEmpty)
                _InfoEntry("Phone", info.contactNumber),
              if (info.contactPersonDesignation.isNotEmpty)
                _InfoEntry("Designation", info.contactPersonDesignation),
              if (info.mailId.isNotEmpty)
                _InfoEntry("Email", info.mailId),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: "Alternate Contact",
            icon: Icons.people_outline,
            iconColor: const Color(0xFF0F6E56),
            iconBg: const Color(0xFFE1F5EE),
            entries: [
              if (info.alternateContactPerson.isNotEmpty)
                _InfoEntry("Alt. Person", info.alternateContactPerson),
              if (info.alternateContactNumber.isNotEmpty)
                _InfoEntry("Alt. Phone", info.alternateContactNumber),
              if (info.alternateMailId.isNotEmpty)
                _InfoEntry("Alt. Email", info.alternateMailId),
              if (info.alternatePersonDesignation.isNotEmpty)
                _InfoEntry("Alt. Designation", info.alternatePersonDesignation),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: "Tax & Compliance",
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFFBA7517),
            iconBg: const Color(0xFFFAEEDA),
            entries: [
              if (info.PANNumber.isNotEmpty)
                _InfoEntry("PAN Number", info.PANNumber),
              if (info.TINNumber.isNotEmpty)
                _InfoEntry("TIN Number", info.TINNumber),
              if (info.STCNumber.isNotEmpty)
                _InfoEntry("STC Number", info.STCNumber),
              if (info.GSTINNumber.isNotEmpty)
                _InfoEntry("GSTIN", info.GSTINNumber),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Tab 2 — Address
// ─────────────────────────────────────────────────────────────
class _AddressTab extends StatelessWidget {
  final Customerdetailsinfomodelclass info;
  const _AddressTab({required this.info});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          _InfoCard(
            title: "Billing Address",
            icon: Icons.receipt_outlined,
            iconColor: const Color(0xFFE24B4A),
            iconBg: const Color(0xFFFCEBEB),
            entries: [
              if (info.billingPersonName.isNotEmpty)
                _InfoEntry("Person", info.billingPersonName),
              if (info.billingPhoneNumber.isNotEmpty)
                _InfoEntry("Phone", info.billingPhoneNumber),
              if (info.billingAddress.isNotEmpty)
                _InfoEntry("Address", info.billingAddress),
              if (info.billingCity.isNotEmpty)
                _InfoEntry("City", info.billingCity),
              if (info.billingDistrict.isNotEmpty)
                _InfoEntry("District", info.billingDistrict),
              if (info.billingState.isNotEmpty)
                _InfoEntry("State", info.billingState),
              if (info.billingCountry.isNotEmpty)
                _InfoEntry("Country", info.billingCountry),
              if (info.billingPincode.isNotEmpty)
                _InfoEntry("Pincode", info.billingPincode),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: "Shipping Address",
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF185FA5),
            iconBg: const Color(0xFFE6F1FB),
            entries: [
              if (info.shipPersonName.isNotEmpty)
                _InfoEntry("Person", info.shipPersonName),
              if (info.shipPhoneNumber.isNotEmpty)
                _InfoEntry("Phone", info.shipPhoneNumber),
              if (info.shipAddress.isNotEmpty)
                _InfoEntry("Address", info.shipAddress),
              if (info.shipCity.isNotEmpty)
                _InfoEntry("City", info.shipCity),
              if (info.shipDistrict.isNotEmpty)
                _InfoEntry("District", info.shipDistrict),
              if (info.shipState.isNotEmpty)
                _InfoEntry("State", info.shipState),
              if (info.shipCountry.isNotEmpty)
                _InfoEntry("Country", info.shipCountry),
              if (info.shipPincode.isNotEmpty)
                _InfoEntry("Pincode", info.shipPincode),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _InfoEntry  — plain class, no typedef
// ─────────────────────────────────────────────────────────────
class _InfoEntry {
  final String label;
  final String value;
  const _InfoEntry(this.label, this.value);
}

// ─────────────────────────────────────────────────────────────
//  _InfoCard
// ─────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final List<_InfoEntry> entries;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
          ...entries.asMap().entries.map((mapEntry) {
            final isLast = mapEntry.key == entries.length - 1;
            final e = mapEntry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(
                          e.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8EA0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Color(0xFFF0F0F5),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  _QuickChip
// ─────────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
