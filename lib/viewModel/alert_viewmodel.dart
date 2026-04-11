import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/AlertModel.dart';
import '../provider/app_providers.dart';

class AlertViewmodel extends AsyncNotifier<List<AlertModel>> {
  @override
  Future<List<AlertModel>> build() async {
    // Auto-fetch on init
    return _fetchAlerts();
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