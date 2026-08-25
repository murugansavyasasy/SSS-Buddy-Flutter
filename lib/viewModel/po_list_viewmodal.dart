import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/PO_listModal.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class PoListViewmodal extends AsyncNotifier<PurchaseOrderData> {
  PurchaseOrderData _all = PurchaseOrderData.fromJson({});

  @override
  Future<PurchaseOrderData> build() async {
    return PurchaseOrderData.fromJson({});
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }

    final lower = query.toLowerCase();

    final filteredOrders = _all.purchaseOrders.where((item) {
      return item.poNumber.toLowerCase().contains(lower) ||
          item.id.toString().contains(lower);
    }).toList();

    state = AsyncData(
      PurchaseOrderData(
        customer: _all.customer,
        purchaseOrders: filteredOrders,
        pendingInvoices: _all.pendingInvoices,
        pendingTotal: _all.pendingTotal,
      ),
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

      final token = loginData.token;

      final repo = ref.read(repositoryProvider);
      final response = await repo.getPoList(customerId.toString(), token);
      _all = response.data;

      state = AsyncData(_all);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }
}

final PoListviewProvider =
AsyncNotifierProvider<PoListViewmodal, PurchaseOrderData>(
        () => PoListViewmodal());