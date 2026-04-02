import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/model/SchoolStats.dart';
import '../provider/app_providers.dart';
import 'login_view_model.dart';

class SchoolStatsViewModel extends AsyncNotifier<SchoolStats> {
  List<dynamic> _orginalList = [];

  @override
  Future<SchoolStats> build() async {
    return loadSchoolStats();
  }

  Future<SchoolStats> loadSchoolStats() async {

    final loginState = ref.read(loginProvider);
    final loginData = loginState.value;

    if (loginData == null) {
      return SchoolStats(
        totalSchools: 0,
        liveActive: 0,
        liveInactive: 0,
        pocActive: 0,
        pocInactive: 0,
        stopped: 0,
        rawList: [],
      );
    }


    final schoolLoginId = loginData.SchoolLoginId;
    final repo = ref.read(repositoryProvider);;
    final jsonResponse = await repo.postschoollist(schoolLoginId);
    final stats = calculateSchoolStatsFromJson(jsonResponse);
    _orginalList = stats.rawList;
    return stats;
  }

  void filter (String query) {
    if(query.trim().isEmpty) {
      final stats = calculateSchoolStatsFromList(_orginalList);
      state = AsyncData(stats);
      return;
    }
    final lowerQuery = query.toLowerCase();
    final filtered = _orginalList.where((item) {

      final SchoolName = item["SchoolName"]?.toString().toLowerCase() ?? "";
      return SchoolName.contains(lowerQuery);

    }).toList();

    final stats = calculateSchoolStatsFromList(filtered);
    state = AsyncData(stats);
  }
}

final schoolStatsProvider =
AsyncNotifierProvider<SchoolStatsViewModel, SchoolStats>(
      () => SchoolStatsViewModel(),
);


