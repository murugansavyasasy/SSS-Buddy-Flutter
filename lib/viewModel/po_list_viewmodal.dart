import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/PO_listModal.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class PoListViewmodal extends AsyncNotifier<List<PurchaseOrder>> {
  List<PurchaseOrder> _all = [];

  @override
  Future<List<PurchaseOrder>> build() async {
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
        return item.poNumber.toLowerCase().contains(lower) ||
            item.id.toString().contains(lower);
      }).toList(),
    );
  }

  Future<void> fetchPoList(int customerId) async {
    state = const AsyncLoading();

    try {
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;

      if (loginData == null) {
        state = AsyncError("User not logged in", StackTrace.current);
        return;
      }

      final token = loginData.token; // adjust field name below if different

      print("🟡 [PoListViewmodal] API call starting -> customerId: $customerId, token: $token");

      final repo = ref.read(repositoryProvider);
      final response = await repo.getPoList(customerId.toString(), token);

      print("🟢 [PoListViewmodal] API response received: status=${response.status}, poCount=${response.data.purchaseOrders.length}");

      _all = response.data.purchaseOrders;

      state = AsyncData(_all);
    } catch (e, s) {
      print("🔴 [PoListViewmodal] API call failed: $e");
      state = AsyncError(e, s);
    }
  }
}

final PoListviewProvider =
AsyncNotifierProvider<PoListViewmodal, List<PurchaseOrder>>(
        () => PoListViewmodal());