import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/FeedbackModel.dart';
import '../provider/app_providers.dart';

class FeedbackViewModel extends AsyncNotifier<List<FeedbackModel>> {
  List<FeedbackModel> _all = [];

  @override
  Future<List<FeedbackModel>> build() async {
    final list = await _fetchFeedback();
    _all = list;
    return list;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<List<FeedbackModel>> _fetchFeedback() async {
    if (globalVimsIdUser.isEmpty) return [];

    final repo = ref.read(repositoryProvider);
    final response = await repo.getFeedbackData(globalVimsIdUser);
    return response ?? [];
  }
}

final feedbackViewModelProvider =
AsyncNotifierProvider<FeedbackViewModel, List<FeedbackModel>>(
  FeedbackViewModel.new,
);