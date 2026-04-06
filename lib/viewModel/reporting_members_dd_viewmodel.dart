import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ReportingMembersModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class ReportingMembersDdViewmodel extends AsyncNotifier<List<Reportingmembersmodel>> {

  @override
  Future<List<Reportingmembersmodel>> build() async {
    final loginAsync = ref.watch(loginProvider);

    return loginAsync.when(
      data: (loginData) async {
        if (loginData == null) return [];

        final IdUser = loginData.VimsIdUser;
        final repo = ref.read(repositoryProvider);

        final response = await repo.getreportingmembers(IdUser);

        return response;
      },
      loading: () async {
        return [];
      },
      error: (e, s) async {
        return [];
      },
    );
  }
}


final reportingmembersProvider =
AsyncNotifierProvider<ReportingMembersDdViewmodel, List<Reportingmembersmodel>>(
      () => ReportingMembersDdViewmodel(),
);

