import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/ZeroActivityModel.dart';
import '../provider/app_providers.dart';

class ZeroactivityViewmodal extends AsyncNotifier<List<Zeroactivitymodel>> {
  List<Zeroactivitymodel> _all = [];
  String status = "All";

  @override
  Future<List<Zeroactivitymodel>> build() async {
    if (globalVimsIdUser.isEmpty) {
      print('❌ globalVimsIdUser empty');
      return [];
    }

    print('🚀 API Call Started');
    print('👤 VimsIdUser: $globalVimsIdUser');

    final repo = ref.read(repositoryProvider);
    final response = await repo.getInstuetList(globalVimsIdUser);

    print('✅ Total Records: ${response.length}');

    _all = response;
    return response;
  }

  void filterByStatus(String selectedStatus) {
    status = selectedStatus;

    if (selectedStatus == "All") {
      state = AsyncData(_all);
      return;
    }

    state = AsyncData(
      _all.where((item) =>
      (item.instituteStatus ?? "").toLowerCase() ==
          selectedStatus.toLowerCase()
      ).toList(),
    );
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }

    final lower = query.toLowerCase();

    state = AsyncData(
      _all.where((item) =>
      (item.instituteName ?? "").toLowerCase().contains(lower) ||
          (item.salesPerson ?? "").toLowerCase().contains(lower)
      ).toList(),
    );
  }
}

final zeroActivityProvider =
AsyncNotifierProvider<ZeroactivityViewmodal, List<Zeroactivitymodel>>(
  ZeroactivityViewmodal.new,
);