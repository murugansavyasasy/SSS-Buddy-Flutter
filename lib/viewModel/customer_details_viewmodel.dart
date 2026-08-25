import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CustomerdetailsModel.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

import '../provider/app_providers.dart';

class CustomerDetailsViewmodel
    extends AsyncNotifier<List<Customerdetailsmodel>> {

  List<Customerdetailsmodel> _all = [];

  @override
  Future<List<Customerdetailsmodel>> build() async {
    final list = await customerlist();
    _all = list;
    return list;
  }

  void filter(String query) {
    if (query.trim().isEmpty) {
      state = AsyncData(_all);
      return;
    }

    final lower = query.toLowerCase();

    state = AsyncData(
      _all.where((item) {
        return item.companyName.toLowerCase().contains(lower) ||
            item.companyName.toLowerCase().contains(lower) ||
            item.accountManager.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Customerdetailsmodel>> customerlist() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final repo = ref.read(repositoryProvider);

    final response = await repo.getCustomersList(loginData.token);

    return response;
  }
}

final customerviewProvider =
AsyncNotifierProvider<CustomerDetailsViewmodel,
    List<Customerdetailsmodel>>(
      () => CustomerDetailsViewmodel(),
);
