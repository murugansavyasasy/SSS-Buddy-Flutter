import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class CustomerDetailsInfoModel extends AsyncNotifier<List<Customerdetailsinfomodelclass>>{


  @override
  Future<List<Customerdetailsinfomodelclass>> build() async{
    return getcustomerinfo();
  }

  Future<List<Customerdetailsinfomodelclass>> getcustomerinfo() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if(loginData == null) return [];

    final VimIdUser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    var customerId = "644";
    var selectedUser = "0";

    final response = await repo.getcustomerinfo(VimIdUser,customerId,selectedUser);
    return response;
  }

}


final customerviewinfoProvider =
AsyncNotifierProvider<CustomerDetailsInfoModel, List<Customerdetailsinfomodelclass>>(
      () => CustomerDetailsInfoModel(),
);