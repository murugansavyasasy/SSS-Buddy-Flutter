import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/Demolist.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class DemolistViewModel extends AsyncNotifier<List<Demolist>> {

  List<Demolist> _all = [];
  @override
  Future<List<Demolist>> build() async {
    final list = await demolist();
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
        return item.schoolName.toLowerCase().contains(lower);
      }).toList(),
    );
  }


  Future<List<Demolist>> demolist() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final schoolLoginId = loginData.SchoolLoginId;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getdemolist(schoolLoginId);

    return response;

  }
}

final demoviewProvider =
    AsyncNotifierProvider<DemolistViewModel, List<Demolist>>(
      () => DemolistViewModel(),
    );
