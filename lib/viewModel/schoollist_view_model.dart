import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/SchoolStats.dart';
import '../core/storage/secure_storage.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class SchoolStatsViewModel extends AsyncNotifier<SchoolStats> {

  @override
  Future<SchoolStats> build() async {
    return loadSchoolStats();
  }

  Future<SchoolStats> loadSchoolStats() async {

    final loginState = ref.watch(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) {
      return SchoolStats(
        totalSchools: 0,
        liveActive: 0,
        liveInactive: 0,
        pocActive: 0,
        pocInactive: 0,
        stopped: 0,
      );
    }


    final schoolLoginId = loginData.SchoolLoginId;
    final repo = ref.read(repositoryProvider);;

    final jsonResponse = await repo.postschoollist(schoolLoginId);

    final stats = calculateSchoolStatsFromJson(jsonResponse);

    return stats;
  }
}

final schoolStatsProvider =
AsyncNotifierProvider<SchoolStatsViewModel, SchoolStats>(
      () => SchoolStatsViewModel(),
);