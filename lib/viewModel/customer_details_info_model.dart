import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/CustomerDetailsInfoModelClass.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class CustomerDetailsInfoModel
    extends AsyncNotifier<List<Customerdetailsinfomodelclass>> {
  @override
  Future<List<Customerdetailsinfomodelclass>> build() async {
    return [];
  }

  Future<bool> fetchCustomerInfo(int customerId) async {
    state = const AsyncLoading();
    try {
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;
      final vimIdUser = loginData?.VimsIdUser;
      final repo = ref.read(repositoryProvider);
      const selectedUser = "0";

      final res = await repo.getcustomerinfo(
        vimIdUser!,
        customerId.toString(),
        selectedUser,
      );

      state = AsyncData(res ?? []);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }
}

final customerviewinfoProvider =
    AsyncNotifierProvider<
      CustomerDetailsInfoModel,
      List<Customerdetailsinfomodelclass>
    >(CustomerDetailsInfoModel.new);
