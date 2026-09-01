import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/FinancialYearModel.dart';

import '../auth/model/RenewalPOModal.dart';
import '../provider/app_providers.dart';
import '../viewModel/login_view_model.dart';

class FinancialMonth {
  final String name;
  final String value;

  const FinancialMonth({
    required this.name,
    required this.value,
  });
}

class RenewalPOsViewModel extends AsyncNotifier<RenewalPOsState> {
  // MARK: - Financial Year (now sourced from API via financialyearProvider)

  String selectedFinancialYear = '';

  String? selectedFinancialYearId;

  // MARK: - Months

  List<String> selectedMonths = [];

  // MARK: - Months for a given FY name (e.g. "2026-2027")

  List<FinancialMonth> getMonthsForFinancialYear(
      String financialYear,
      ) {
    if (financialYear.isEmpty) {
      return [];
    }

    final years = financialYear.split('-');

    if (years.length != 2) {
      return [];
    }

    final startYear = int.tryParse(years[0]);

    if (startYear == null) {
      return [];
    }

    return [
      FinancialMonth(name: 'April', value: '$startYear-04'),
      FinancialMonth(name: 'May', value: '$startYear-05'),
      FinancialMonth(name: 'June', value: '$startYear-06'),
      FinancialMonth(name: 'July', value: '$startYear-07'),
      FinancialMonth(name: 'August', value: '$startYear-08'),
      FinancialMonth(name: 'September', value: '$startYear-09'),
      FinancialMonth(name: 'October', value: '$startYear-10'),
      FinancialMonth(name: 'November', value: '$startYear-11'),
      FinancialMonth(name: 'December', value: '$startYear-12'),
      FinancialMonth(name: 'January', value: '${startYear + 1}-01'),
      FinancialMonth(name: 'February', value: '${startYear + 1}-02'),
      FinancialMonth(name: 'March', value: '${startYear + 1}-03'),
    ];
  }

  // MARK: - Initial State

  @override
  Future<RenewalPOsState> build() async {
    return RenewalPOsState.initial();
  }

  // MARK: - Set default FY & current month (call this once FY list arrives from API)

  void setDefaultFinancialYearAndMonth(List<Financialyearmodel> years) {
    if (years.isNotEmpty && selectedFinancialYear.isEmpty) {
      selectedFinancialYearId = years.first.id.toString();
      selectedFinancialYear = years.first.label;

      final now = DateTime.now();

      final currentMonthValue =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      selectedMonths = [currentMonthValue];
    }
  }

  // MARK: - Select Financial Year

  void selectFinancialYear({
    required String id,
    required String year,
  }) {
    selectedFinancialYearId = id;
    selectedFinancialYear = year;

    // When FY changes, clear old month selection.
    selectedMonths = [];

    state = AsyncData(
      RenewalPOsState.initial(),
    );
  }

  // MARK: - Month Selection (multi-select)

  void toggleMonth(String month) {
    if (selectedMonths.contains(month)) {
      selectedMonths.remove(month);
    } else {
      selectedMonths.add(month);
    }

    final current = state.value ?? RenewalPOsState.initial();

    state = AsyncData(
      current.copyWith(expiredNotRenewed: false),
    );
  }

  bool isMonthSelected(String month) {
    return selectedMonths.contains(month);
  }

  // MARK: - Select All Months

  void selectAllMonths() {
    final months = getMonthsForFinancialYear(selectedFinancialYear);

    selectedMonths = months.map((month) => month.value).toList();

    final current = state.value ?? RenewalPOsState.initial();

    state = AsyncData(
      current.copyWith(expiredNotRenewed: false),
    );
  }

  // MARK: - Clear Months

  void clearMonths() {
    selectedMonths = [];
  }

  // MARK: - Expired & Not Renewed

  void setExpiredNotRenewed(bool value) {
    if (value) {
      selectedMonths = [];
    }

    state = AsyncData(
      RenewalPOsState.initial().copyWith(expiredNotRenewed: value),
    );
  }

  // MARK: - API Call

  Future<void> getRenewalPOs() async {
    final currentExpired = state.value?.expiredNotRenewed ?? false;

    if (!currentExpired) {
      if (selectedFinancialYear.isEmpty) {
        return;
      }
      if (selectedMonths.isEmpty) {
        return;
      }
    }

    state = const AsyncLoading();

    try {
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;

      if (loginData == null) {
        state = AsyncError(
          "User not logged in",
          StackTrace.current,
        );
        return;
      }

      final token = loginData.token;

      // TODO: replace with the actual field name from your LoginData model
      final customerId = loginData.employeeId;

      if (customerId == null) {
        state = AsyncError(
          "Customer ID not found",
          StackTrace.current,
        );
        return;
      }

      final repo = ref.read(repositoryProvider);

      // Multiple selected months -> comma-separated string
      // e.g. ["2026-06", "2026-07"] -> "2026-06,2026-07"
      final String? months = selectedMonths.isEmpty
          ? null
          : selectedMonths.join(',');

      final response = await repo.getRenivals(
        customerId: customerId,
        token: token,
        financialYearId: selectedFinancialYearId,
        months: months,
        expiredNotRenewed: currentExpired,
      );

      state = AsyncData(
        RenewalPOsState(
          renewalPOs: response.data,
          expiredNotRenewed: currentExpired,
        ),
      );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // MARK: - Clear Result

  void clearResults() {
    final current = state.value ?? RenewalPOsState.initial();

    state = AsyncData(
      current.copyWith(renewalPOs: []),
    );
  }
}

// MARK: - Provider

final renewalPOsViewModelProvider =
AsyncNotifierProvider.autoDispose<RenewalPOsViewModel, RenewalPOsState>(
  RenewalPOsViewModel.new,
);

class RenewalPOsState {
  final List<RenewalPO> renewalPOs;
  final bool expiredNotRenewed;

  const RenewalPOsState({
    required this.renewalPOs,
    required this.expiredNotRenewed,
  });

  factory RenewalPOsState.initial() {
    return const RenewalPOsState(
      renewalPOs: [],
      expiredNotRenewed: false,
    );
  }

  RenewalPOsState copyWith({
    List<RenewalPO>? renewalPOs,
    bool? expiredNotRenewed,
  }) {
    return RenewalPOsState(
      renewalPOs: renewalPOs ?? this.renewalPOs,
      expiredNotRenewed: expiredNotRenewed ?? this.expiredNotRenewed,
    );
  }
}