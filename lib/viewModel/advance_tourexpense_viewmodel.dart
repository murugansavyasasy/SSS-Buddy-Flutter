import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/AdvanceTourExpenseModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class AdvanceTourexpenseViewmodel
    extends AsyncNotifier<List<Advancetourexpensemodel>> {
  List<Advancetourexpensemodel> _all = [];
  @override
  Future<List<Advancetourexpensemodel>> build() async {
    final list = await advancetourexpense();
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
        return item.EmpName.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Advancetourexpensemodel>> advancetourexpense() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final VimsIdUser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getadvancetourdata(VimsIdUser);

    return response;
  }
}

final tourexpenseprovider =
    AsyncNotifierProvider<
      AdvanceTourexpenseViewmodel,
      List<Advancetourexpensemodel>
    >(() => AdvanceTourexpenseViewmodel());
