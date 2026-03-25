import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CircularModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class CircularPostViewmodel extends AsyncNotifier<List<Circularmodel>> {

  List<Circularmodel> _all = [];

  @override
  Future<List<Circularmodel>> build() async {
    final list = await circularlist();
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
        return item.SchoolName.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Circularmodel>> circularlist() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final schoolLoginId = loginData.SchoolLoginId;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getcircularlist(schoolLoginId);

    return response;
  }
}

final circularviewProvider =
    AsyncNotifierProvider<CircularPostViewmodel, List<Circularmodel>>(
      () => CircularPostViewmodel(),
    );
