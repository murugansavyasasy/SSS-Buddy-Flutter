import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/model/SchoolStats.dart';
import '../core/storage/secure_storage.dart';
import '../provider/app_providers.dart';

class SchoolStatsViewModel extends AsyncNotifier<SchoolStats> {

  @override
  Future<SchoolStats> build() async {
    return loadSchoolStats();
  }

  Future<SchoolStats> loadSchoolStats() async {

    final loginResponse = await SecureStorage.getLoginResponse();

    if (loginResponse == null) {
      return SchoolStats(
        totalSchools: 0,
        liveActive: 0,
        liveInactive: 0,
        pocActive: 0,
        pocInactive: 0,
        stopped: 0,
      );
    }

    final decode = jsonDecode(loginResponse);
    final schoolLoginId = decode["SchoolLoginId"].toString();

    final repo = ref.read(repositoryProvider);

    final jsonResponse = await repo.postschoollist(schoolLoginId);

    /// isolate handles everything
    final stats = await compute(calculateSchoolStatsFromJson, jsonResponse);

    return stats;
  }
}

final schoolStatsProvider =
AsyncNotifierProvider<SchoolStatsViewModel, SchoolStats>(
      () => SchoolStatsViewModel(),
);