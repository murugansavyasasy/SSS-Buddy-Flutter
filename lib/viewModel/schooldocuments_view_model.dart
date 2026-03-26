import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/SchoolDocuments.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class SchooldocumentsViewModel extends AsyncNotifier <List<Schooldocuments>> {

  List<Schooldocuments> _all = [];
  @override
  Future<List<Schooldocuments>> build() async {
    final list = await schooldocuments();
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
        return item.DocumentName.toLowerCase().contains(lower);
      }).toList(),
    );
  }

  Future<List<Schooldocuments>> schooldocuments() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final vimIDuser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);

    final response = await repo.getSchoolDocuments(vimIDuser);

    return response;

  }

}


final schooldocumentsviewProvider =
AsyncNotifierProvider<SchooldocumentsViewModel, List<Schooldocuments>>(
      () => SchooldocumentsViewModel(),
);