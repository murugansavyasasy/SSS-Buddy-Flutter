// reporting_members_dd_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ReportingMembersModel.dart';

import '../provider/app_providers.dart';
import 'login_view_model.dart';

class ReportingMembersDdViewmodel extends AsyncNotifier<List<Reportingmembersmodel>> {

  @override
  Future<List<Reportingmembersmodel>> build() async {
    return _fetch();
  }

  Future<List<Reportingmembersmodel>> _fetch() async {
    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) return [];

    final IdUser = loginData.VimsIdUser;
    final repo = ref.read(repositoryProvider);
    final response = await repo.getreportingmembers(IdUser);

    return response;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final reportingmembersProvider =
AsyncNotifierProvider<ReportingMembersDdViewmodel, List<Reportingmembersmodel>>(
  ReportingMembersDdViewmodel.new,
);