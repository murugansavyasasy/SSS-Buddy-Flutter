import 'dart:convert';

class SchoolStats {
  final int totalSchools;
  final int liveActive;
  final int liveInactive;
  final int pocActive;
  final int pocInactive;
  final int stopped;
  final List<dynamic> rawList;

  SchoolStats({
    required this.totalSchools,
    required this.liveActive,
    required this.liveInactive,
    required this.pocActive,
    required this.pocInactive,
    required this.stopped,
    required this.rawList,
  });
}
SchoolStats calculateSchoolStatsFromJson(String jsonString) {
  final List data = jsonDecode(jsonString);

  int totalSchools = data.length;
  int liveActive = 0;
  int liveInactive = 0;
  int pocActive = 0;
  int pocInactive = 0;
  int stopped = 0;

  for (final item in data) {
    final status = item["Status"]?.toString().toUpperCase() ?? "";
    final isActive = item["isActive"]?.toString() ?? "0";

    if (status == "LIVE") {
      if (isActive == "1") {
        liveActive++;
      } else {
        liveInactive++;
      }
    }
    else if (status == "POC") {
      if (isActive == "1") {
        pocActive++;
      } else {
        pocInactive++;
      }
    }
    else if (status == "STOPPED") {
      stopped++;
    }
  }

  return SchoolStats(
    totalSchools: totalSchools,
    liveActive: liveActive,
    liveInactive: liveInactive,
    pocActive: pocActive,
    pocInactive: pocInactive,
    stopped: stopped,
    rawList: data,

  );
}


SchoolStats calculateSchoolStatsFromList(List<dynamic> data) {
  int totalSchools = data.length;
  int liveActive = 0;
  int liveInactive = 0;
  int pocActive = 0;
  int pocInactive = 0;
  int stopped = 0;

  for (final item in data) {
    final status = item["Status"]?.toString().toUpperCase() ?? "";
    final isActive = item["isActive"]?.toString() ?? "0";

    if (status == "LIVE") {
      if (isActive == "1") {
        liveActive++;
      } else {
        liveInactive++;
      }
    } else if (status == "POC") {
      if (isActive == "1") {
        pocActive++;
      } else {
        pocInactive++;
      }
    } else if (status == "STOPPED") {
      stopped++;
    }
  }

  return SchoolStats(
    totalSchools: totalSchools,
    liveActive: liveActive,
    liveInactive: liveInactive,
    pocActive: pocActive,
    pocInactive: pocInactive,
    stopped: stopped,
    rawList: data,
  );
}