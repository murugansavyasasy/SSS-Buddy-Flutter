import '../auth/model/SchoolFilter.dart';

List<dynamic> applyFilter(List<dynamic> data, SchoolFilter filter) {
  switch (filter) {
    case SchoolFilter.liveActive:
      return data.where((e) =>
      e["Status"] == "LIVE" &&
          e["isActive"].toString() == "1").toList();

    case SchoolFilter.liveInactive:
      return data.where((e) =>
      e["Status"] == "LIVE" &&
          e["isActive"].toString() == "0").toList();

    case SchoolFilter.pocActive:
      return data.where((e) =>
      e["Status"] == "POC" &&
          e["isActive"].toString() == "1").toList();

    case SchoolFilter.pocInactive:
      return data.where((e) =>
      e["Status"] == "POC" &&
          e["isActive"].toString() == "0").toList();

    case SchoolFilter.stopped:
      return data.where((e) =>
      e["Status"] == "STOPPED").toList();

    case SchoolFilter.all:
    default:
      return data;
  }
}