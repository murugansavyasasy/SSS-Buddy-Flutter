import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/LocalConveyenceModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class LocalConveyenceViewmodel
    extends AsyncNotifier<List<Localconveyencemodel>> {

  List<Localconveyencemodel> _all = [];

  @override
  Future<List<Localconveyencemodel>> build() async {
    final list = await localconvience();
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
        return item.Username.toLowerCase().contains(lower) ||
            item.RefId.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Localconveyencemodel>> localconvience() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final repo = ref.read(repositoryProvider);

    final response = await repo.getlocalconveyence(loginData.token);

    return response;
  }

  // ADD LOCAL EXPENSE
  Future<bool> addLocalExpense({
    required int monthOfClaim,
    required String description,
    required String remarksWithoutBill,
    required double totalLocalExpense,
    required List<Map<String, dynamic>> localItemList,
  }) async {
    try {
      final loginState = ref.read(loginProvider);
      final loginData = loginState.value;

      if (loginData == null) {
        return false;
      }

      final repo = ref.read(repositoryProvider);

      final body = {
        "idUser": 28,
        "monthOfClaim": monthOfClaim,
        "Description": description,
        "RemarksWithoutBill": remarksWithoutBill,
        "TotalLocalExpense": totalLocalExpense,
        "processType": "LocalExpense",
        "LocalItemList": localItemList,
      };

      final success = await repo.addLocalExpense(
        body: body,
      );

      return success;
    } catch (e) {
      print("LocalConveyenceViewmodel ERROR: $e");
      return false;
    }
  }
}



final localConvienceProvider =
AsyncNotifierProvider<LocalConveyenceViewmodel, List<Localconveyencemodel>>(
      () => LocalConveyenceViewmodel(),
);