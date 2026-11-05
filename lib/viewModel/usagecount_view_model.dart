import 'package:flutter/foundation.dart';
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

  /// Returns the usage data, or null on failure.
  Future<Usagecount?> usagecount(
    String schoolID,
    String fromDate,
    String toDate,
  ) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);

      final res = await repo.usagecount(schoolID, fromDate, toDate);

      state = AsyncData(res);
      return res;
    } catch (e, s) {
      debugPrint('Usage count error: $e');
      state = AsyncError(e, s);
      return null;
    }
  }
}
