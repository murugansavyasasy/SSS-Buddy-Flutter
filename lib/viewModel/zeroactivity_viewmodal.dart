import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ZeroActivityModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class ZeroactivityViewmodal
    extends AsyncNotifier<List<ZeroActivityModel>> {
  List<ZeroActivityModel> _all = [];

  String status = "All";
  String searchQuery = "";

  @override
  Future<List<ZeroActivityModel>> build() async {
    final loginData = ref.read(loginProvider).value;

    if (loginData == null) {
      throw Exception("User not logged in");
    }

    final repo = ref.read(repositoryProvider);

    final response = await repo.getInstuetList(
      loginData.userId.toString(),
    );
    _all = response;

    return response;
  }

  List<String> get statusList {
    final uniqueStatus = _all
        .map((item) => item.instituteStatus.trim())
        .where((status) => status.isNotEmpty)
        .toSet()
        .toList();

    return [
      "All",
      ...uniqueStatus,
    ];
  }


  void filterByStatus(String selectedStatus) {
    status = selectedStatus;

    _applyFilters();
  }

  void filter(String query) {
    searchQuery = query;

    _applyFilters();
  }

  void _applyFilters() {
    List<ZeroActivityModel> filtered = List.from(_all);

    if (status != "All") {
      filtered = filtered.where((item) {
        return item.instituteStatus.toLowerCase() ==
            status.toLowerCase();
      }).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final lowerQuery =
      searchQuery.trim().toLowerCase();

      filtered = filtered.where((item) {
        return item.instituteName
            .toLowerCase()
            .contains(lowerQuery) ||
            item.salesPerson
                .toLowerCase()
                .contains(lowerQuery) ||
            item.instituteId
                .toString()
                .contains(lowerQuery);
      }).toList();
    }

    state = AsyncData(filtered);
  }
}

final zeroActivityProvider =
AsyncNotifierProvider<
    ZeroactivityViewmodal,
    List<ZeroActivityModel>
>(
  ZeroactivityViewmodal.new,
);