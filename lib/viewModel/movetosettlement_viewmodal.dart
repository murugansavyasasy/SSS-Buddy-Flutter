
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/AddTourExpenceModal.dart';
import '../auth/model/MoveToSettlementTourRequest.dart';
import '../provider/app_providers.dart';

class MovetosettlementViewmodal
    extends AsyncNotifier<TourExpenseResponse?> {

  @override
  Future<TourExpenseResponse?> build() async {
    return null;
  }

  Future<void> submitMoveTourExpense(Movetosettlementtourrequest request) async {
    try {
      state = const AsyncValue.loading();

      final repo = ref.read(repositoryProvider);
      final res = await repo.submitMoveTourExpense(request);

      state = AsyncValue.data(res);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final movetourExpenseProvider =
AsyncNotifierProvider<MovetosettlementViewmodal, TourExpenseResponse?>(
      () => MovetosettlementViewmodal(),
);