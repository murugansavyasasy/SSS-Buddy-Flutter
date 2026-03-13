import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/Demolist.dart';
import '../core/storage/secure_storage.dart';
import '../provider/app_providers.dart';


class DemolistViewModel extends AsyncNotifier<List<Demolist>> {

  @override
  Future<List<Demolist>> build() async {
    return demolist();
  }

  Future<List<Demolist>> demolist() async {

    final loginResponse = await SecureStorage.getLoginResponse();
    if(loginResponse == null) return [];

    final decode = jsonDecode(loginResponse);
    final schoolLoginId = decode["SchoolLoginId"].toString();
    final repo = ref.read(repositoryProvider);

    final response = await repo.getdemolist(schoolLoginId);

    return response.take(5).toList();
  }
}

final demoviewProvider =
AsyncNotifierProvider<DemolistViewModel, List<Demolist>>(
      () => DemolistViewModel(),
);