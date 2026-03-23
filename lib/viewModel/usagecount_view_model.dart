import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/UsageCount.dart';

import '../provider/app_providers.dart';

final usagecountViewModelProvider =
    AsyncNotifierProvider<UsagecountViewModel, Usagecount?>(
      UsagecountViewModel.new,
    );

class UsagecountViewModel extends AsyncNotifier<Usagecount?> {
  @override
  Future<Usagecount?> build() async => null;

  Future<bool> usagecount(
    String schoolID,
    String fromDate,
    String toDate,
  ) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);

      final res = await repo.usagecount(schoolID, fromDate, toDate);

      state = AsyncData(res);
      return true;
    } catch (e, s) {
      state = AsyncError(e, s);
      return false;
    }
  }
}
