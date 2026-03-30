import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/PO_listModal.dart';
import '../provider/app_providers.dart';

class PoListViewmodal extends AsyncNotifier<List<PoListModel>> {
  List<PoListModel> _all = [];

  @override
  Future<List<PoListModel>> build() async {
    return [];
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }

    final lower = query.toLowerCase();

    state = AsyncData(
      _all.where((item) {
        return item.nameValue.toLowerCase().contains(lower) ||
            item.idValue.toString().contains(lower);
      }).toList(),
    );
  }

  Future<void> fetchPoList(int customerId) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);

      final response =
      await repo.getpolist(customerId.toString());

      _all = response;

      state = AsyncData(response);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}
final PoListviewProvider =
AsyncNotifierProvider<PoListViewmodal, List<PoListModel>>(
        () => PoListViewmodal());