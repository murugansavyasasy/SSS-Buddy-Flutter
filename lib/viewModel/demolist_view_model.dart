import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/Demolist.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class DemolistViewModel extends AsyncNotifier<List<Demolist>> {
  @override
  Future<List<Demolist>> build() async {
    return demolist();
  }

  Future<List<Demolist>> demolist() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final schoolLoginId = loginData.SchoolLoginId;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getdemolist(schoolLoginId);

    return response.take(5).toList();
  }
}

final demoviewProvider =
    AsyncNotifierProvider<DemolistViewModel, List<Demolist>>(
      () => DemolistViewModel(),
    );
