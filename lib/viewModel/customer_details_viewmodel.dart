import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CustomerdetailsModel.dart';
import 'package:sssbuddy/viewModel/demolist_view_model.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

import '../provider/app_providers.dart';

class CustomerDetailsViewmodel extends AsyncNotifier<List<Customerdetailsmodel>>{

  @override
  Future<List<Customerdetailsmodel>> build() async {
     return customerlist();
  }

  Future<List<Customerdetailsmodel>> customerlist() async {

    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if(loginData == null) return [];

    final VimIdUser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    var customerId = "0";
    var selectedUser = "0";

    final response = await repo.getcustomerslist(VimIdUser,customerId,selectedUser);
    return response;

  }
}


final customerviewProvider =
AsyncNotifierProvider<CustomerDetailsViewmodel, List<Customerdetailsmodel>>(
      () => CustomerDetailsViewmodel(),
);