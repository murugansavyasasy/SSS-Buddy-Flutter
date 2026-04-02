import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/SalesPersonModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class SalesPersonViewmodel extends AsyncNotifier<List<Salespersonmodel>>{
  List<Salespersonmodel>? _cache;

  @override
  Future<List<Salespersonmodel>> build() async {
    if (_cache != null) return _cache!;
    return _fetch();
  }

  Future<List<Salespersonmodel>> _fetch() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final IdUser = loginData.VimsIdUser;

    final repo = ref.read(repositoryProvider);
    final response = await repo.getsalesperson(IdUser);
    _cache = response;
    return response;
  }
  Future<void> refresh() async {
    _cache = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final salespersonProvider =
AsyncNotifierProvider<SalesPersonViewmodel, List<Salespersonmodel>>(
  SalesPersonViewmodel.new,
);