import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CircularModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class CircularPostViewmodel extends AsyncNotifier<List<Circularmodel>> {
  @override
  Future<List<Circularmodel>> build() async {
    return circularlist();
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
