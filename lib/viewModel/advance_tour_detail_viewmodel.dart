import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/AdvanceTourExpenseDetailModel.dart';

import '../provider/app_providers.dart';

class AdvanceTourDetailViewmodel extends AsyncNotifier<List<Advancetourexpensedetailmodel>>{
  String? idTourExpense;
  bool _fetched = false;

  @override
  Future<List<Advancetourexpensedetailmodel>> build() async {
    if (idTourExpense == null) return [];
    return advancetourdetailviewmodel();
  }

  Future<List<Advancetourexpensedetailmodel>> advancetourdetailviewmodel() async {
    final repo = ref.read(repositoryProvider);
    final response = await repo.getadvancetourdetails(idTourExpense!);
    return response;
  }

  void fetchDetail(String id) {
    if (_fetched && idTourExpense == id) return;
    _fetched = true;
    idTourExpense = id;
    ref.invalidateSelf();
  }
}


final advancetourdetailProvider =
AsyncNotifierProvider<AdvanceTourDetailViewmodel, List<Advancetourexpensedetailmodel>>(
      () => AdvanceTourDetailViewmodel(),
);
