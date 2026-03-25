import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class CustomerDetailsInfoModel extends AsyncNotifier<List<Customerdetailsinfomodelclass>> {
  @override
  Future<List<Customerdetailsinfomodelclass>> build() async {
    return [];
  }
  Future<void> fetchCustomerInfo(String customerId) async {
    state = const AsyncLoading();

    try {
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;

      if (loginData == null) {
        state = const AsyncData([]);
        return;
      }

      final vimIdUser = loginData.VimsIdUser;
      final repo = ref.read(repositoryProvider);
      const selectedUser = "0";

      final response = await repo.getcustomerinfo(
        vimIdUser,
        customerId,
        selectedUser,
      );

      state = AsyncData(response);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
final customerviewinfoProvider =
AsyncNotifierProvider<CustomerDetailsInfoModel, List<Customerdetailsinfomodelclass>>(
  CustomerDetailsInfoModel.new,
);