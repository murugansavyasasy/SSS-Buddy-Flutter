import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/SchoolNameModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class SchollnameDdViewmodel extends AsyncNotifier<List<Schoolnamemodel>> {

  List<Schoolnamemodel>? _cache;
  @override
  Future<List<Schoolnamemodel>> build() async {
    if(_cache !=null) return _cache!;
    return _fetch();
  }

  Future<List<Schoolnamemodel>> _fetch() async {
    final loginData = ref.read(loginProvider).value;
    if (loginData == null) return [];

    final repo = ref.read(repositoryProvider);
    final response = await repo.getschoolname(loginData.VimsIdUser);
    _cache = response;
    return response;
  }

  Future<void> refresh() async {
    _cache = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final schoolnameProvider =
AsyncNotifierProvider<SchollnameDdViewmodel, List<Schoolnamemodel>>(
      () => SchollnameDdViewmodel(),
);
