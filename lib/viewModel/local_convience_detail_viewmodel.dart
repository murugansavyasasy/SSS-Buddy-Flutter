import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/LocalExpenseDetailModel.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class LocalConvienceDetailViewmodel extends AsyncNotifier<List<Localexpensedetailmodel>> {
  String? idLocalExpense;
  bool _fetched = false;

  @override
  Future<List<Localexpensedetailmodel>> build() async {
    if (idLocalExpense == null) return [];
    return localconviencedetail();
  }

  Future<List<Localexpensedetailmodel>> localconviencedetail() async {
    final repo = ref.read(repositoryProvider);
    final response = await repo.getlocalconviencedetail(idLocalExpense!);
    return response;
  }

  void fetchDetail(String id) {
    if (_fetched && idLocalExpense == id) return;
    _fetched = true;
    idLocalExpense = id;
    ref.invalidateSelf();
  }
}

final localconviencedetailProvider =
AsyncNotifierProvider<LocalConvienceDetailViewmodel, List<Localexpensedetailmodel>>(
      () => LocalConvienceDetailViewmodel(),
);
