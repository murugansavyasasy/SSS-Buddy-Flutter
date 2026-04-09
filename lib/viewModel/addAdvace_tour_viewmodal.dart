
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/AddTourExpenceModal.dart';
import '../provider/app_providers.dart';

class TourExpenseViewModel
    extends AsyncNotifier<TourExpenseResponse?> {

  @override
  Future<TourExpenseResponse?> build() async {
    return null;
  }

  Future<void> submitTourExpense(TourExpenseRequest request) async {
    try {
      state = const AsyncValue.loading();

      final repo = ref.read(repositoryProvider);
      final res = await repo.submitTourExpense(request);

      state = AsyncValue.data(res);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final tourExpenseProvider =
AsyncNotifierProvider<TourExpenseViewModel, TourExpenseResponse?>(
      () => TourExpenseViewModel(),
);