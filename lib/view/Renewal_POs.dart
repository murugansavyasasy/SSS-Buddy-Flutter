import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:sssbuddy/auth/model/FinancialYearModel.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/RenewalPOModal.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/renewalPOs_viewModal.dart';
import '../viewModel/financialyear_dd_viewmodel.dart'; // adjust path/filename as needed
import 'dashboard.dart';

class RenewalPOsPage extends ConsumerWidget {
  const RenewalPOsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final vm = ref.watch(renewalPOsViewModelProvider.notifier);
    final state = ref.watch(renewalPOsViewModelProvider);
    final fyState = ref.watch(financialyearProvider);

    ref.listen<AsyncValue<List<Financialyearmodel>>>(
      financialyearProvider,
          (previous, next) {
        next.whenData((years) {
          vm.setDefaultFinancialYearAndMonth(years);
        });
      },
    );

    final months = vm.getMonthsForFinancialYear(vm.selectedFinancialYear);
    final renewalPOs = state.value?.renewalPOs ?? [];
    final isLoading = state is AsyncLoading;

    return PopScope(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                title: "Renewal POs",
                navigateTo: const Dashboard(),

                financialYearList: fyState.value
                    ?.map(
                      (y) => {
                    'id': y.id.toString(),
                    'name': y.label.toString(),
                  },
                )
                    .toList() ??
                    [],

                selectedFinancialYearId: vm.selectedFinancialYearId,

                onFinancialYearChanged: (id, name) {
                  vm.selectFinancialYear(
                    id: id,
                    year: name,
                  );
                },
              ),
              // MARK: - Purple header (month scroller + search)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _monthScroller(vm, months),
                    const SizedBox(height: 16),
                    _searchButton(vm, state),
                  ],
                ),
              ),

              // MARK: - White content sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Renewal POs",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _expiredFilterChip(vm, state.value),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          _renewalPOList(renewalPOs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MARK: - Compact FY Dropdown (API-driven, shown in the toolbar)

  Widget _compactFyDropdown(
      RenewalPOsViewModel vm,
      AsyncValue<List<Financialyearmodel>> fyState,
      ) {
    return fyState.when(
      loading: () => const SizedBox(
        width: 60,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
      error: (e, st) => const SizedBox.shrink(),
      data: (years) {
        if (years.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedNotifier = ValueNotifier<String?>(
          vm.selectedFinancialYear.isEmpty
              ? years.first.label
              : vm.selectedFinancialYear,
        );

        return Container(
          height: 36,
          constraints: const BoxConstraints(maxWidth: 130),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white30),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              valueListenable: selectedNotifier,
              customButton: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      vm.selectedFinancialYear.isEmpty
                          ? years.first.label
                          : vm.selectedFinancialYear,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
              dropdownStyleData: DropdownStyleData(
                width: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                offset: const Offset(-20, 8),
              ),
              items: years.map((year) {
                return DropdownItem<String>(
                  value: year.label,
                  child: Text(
                    year.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final selectedYear = years.firstWhere(
                        (y) => y.label == value,
                  );

                  vm.selectFinancialYear(
                    id: selectedYear.id.toString(),
                    year: selectedYear.label,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  // MARK: - Month Scroller (multi-select)

  Widget _monthScroller(
      RenewalPOsViewModel vm,
      List<FinancialMonth> months,
      ) {
    if (months.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final month = months[index];
          final selected = vm.isMonthSelected(month.value);

          return GestureDetector(
            onTap: () {
              vm.toggleMonth(month.value);
            },
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: selected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    month.name.substring(0, 3),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: selected ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.primary,
                    )
                  else
                    Text(
                      month.value.split('-').first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // MARK: - Search Button

  Widget _searchButton(
      RenewalPOsViewModel vm,
      AsyncValue<RenewalPOsState> state,
      ) {
    final isLoading = state is AsyncLoading;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: vm.selectedMonths.isEmpty || isLoading
            ? null
            : () {
          vm.getRenewalPOs();
        },
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        )
            : Text(
          vm.selectedMonths.isEmpty
              ? "Select Months"
              : "Search ${vm.selectedMonths.length} "
              "${vm.selectedMonths.length == 1 ? 'Month' : 'Months'}",
        ),
      ),
    );
  }

  // MARK: - Expired / All Filter

  Widget _expiredFilterChip(
      RenewalPOsViewModel vm,
      RenewalPOsState? currentState,
      ) {
    final expired = currentState?.expiredNotRenewed ?? false;

    return GestureDetector(
      onTap: () {
        vm.setExpiredNotRenewed(!expired);
        if (!expired) {
          vm.getRenewalPOs();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: expired
              ? AppColors.primary.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expired ? "Expired" : "All",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: expired ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: expired ? AppColors.primary : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _renewalPOList(List<RenewalPO> renewalPOs) {
    if (renewalPOs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Text(
            "No Renewal POs found",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: renewalPOs.map((po) => _poCard(po)).toList(),
    );
  }

  Widget _poCard(RenewalPO po) {
    final isActive = po.status.toLowerCase() == "active";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  po.poNumber,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  po.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  po.customerCode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const Divider(height: 20),

                _infoRow("Vertical", po.vertical),
                _infoRow("PO Value", "₹ ${po.poValue.toStringAsFixed(2)}"),
                _infoRow(
                  "Validity",
                  "${po.validFrom} - ${po.validTo}",
                ),
                _infoRow("Account Manager", po.accountManager),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.green.withOpacity(0.15)
                  : Colors.orange.withOpacity(0.15),
            ),
            child: Icon(
              isActive ? Icons.check : Icons.hourglass_bottom,
              size: 16,
              color: isActive ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}