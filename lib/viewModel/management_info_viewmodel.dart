import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ManagementInfo.dart';

import '../provider/app_providers.dart';

class ManagementInfoViewmodel extends AsyncNotifier<List<Managementinfo>?> {
  @override
  Future<List<Managementinfo>?> build() async => null;
  Future<bool> managementinfo(int schoolID) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(repositoryProvider);

      final res = await repo.managementinfo(schoolID);

      state = AsyncData(res);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }
}

final managementInfoViewModelProvider =
AsyncNotifierProvider<ManagementInfoViewmodel, List<Managementinfo>?>(
    ManagementInfoViewmodel.new);