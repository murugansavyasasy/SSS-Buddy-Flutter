import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CustomerdetailsModel.dart';
import 'package:sssbuddy/viewModel/demolist_view_model.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

import '../provider/app_providers.dart';

class CustomerDetailsViewmodel extends AsyncNotifier<List<Customerdetailsmodel>> {
  List<Customerdetailsmodel> _all = [];
  String _selectedSalesPersonId = "0";
  @override
  Future<List<Customerdetailsmodel>> build() async {
    final list = await customerlist(_selectedSalesPersonId);
    _all = list;
    return list;
  }
  Future<void> filterBySalesPerson(String id) async {
    _selectedSalesPersonId = id;
    state = const AsyncLoading();
    final list = await customerlist(id);
    _all = list;

    state = AsyncData(list);
  }
  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }
    final lower = query.toLowerCase();
    state = AsyncData(
      _all.where((item) {
        return item.companyNameVS.toLowerCase().contains(lower) ||
            item.customerName.toLowerCase().contains(lower) ||
            item.salesPersonName.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Customerdetailsmodel>> customerlist(String customerId) async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final VimIdUser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    var selectedUser = "0";

    final response = await repo.getcustomerslist(
      VimIdUser,
      selectedUser,
      customerId,
    );
    return response;
  }
}

final customerviewProvider =
    AsyncNotifierProvider<CustomerDetailsViewmodel, List<Customerdetailsmodel>>(
      () => CustomerDetailsViewmodel(),
    );
