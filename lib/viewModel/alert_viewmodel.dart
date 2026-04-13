import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/AlertModel.dart';
import '../provider/app_providers.dart';

class AlertViewmodel extends AsyncNotifier<List<AlertModel>> {

  List<AlertModel> _all = [];
  @override
  Future<List<AlertModel>> build() async {
    final list = await _fetchAlerts();
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
        return item.alertTitle.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<AlertModel>> _fetchAlerts() async {
    final repo = ref.read(repositoryProvider);
    return await repo.getalertdata();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAlerts());
  }
}

final AlertViewmodelProvider =
AsyncNotifierProvider<AlertViewmodel, List<AlertModel>>(
  AlertViewmodel.new,
);