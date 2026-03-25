import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../auth/model/SchoolFilter.dart';
import '../core/network/DioClient.dart';
import '../repository/clientrepository.dart';
import '../utils/filter_utils.dart';
import '../viewModel/schoollist_view_model.dart';

final dioProvider = Provider<Dioclient>((ref) {
  return Dioclient();
});

final repositoryProvider = Provider<ClientRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ClientRepository(dio);
});

final rememberMeProvider = StateProvider<bool>((ref) => false);
final searchProvider = StateProvider<bool>((ref) => false);

final searchQueryProvider = StateProvider<String>((ref) => "");
final schoolCountProvider = StateProvider<String>((ref) => "");


final filteredSchoolListProvider = Provider<List<dynamic>>((ref) {
  final schoolAsync = ref.watch(schoolStatsProvider);
  final selectedFilter = ref.watch(selectedFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return schoolAsync.when(
    data: (stats) {
      final schoolList = stats.rawList;

      final filtered = applyFilter(schoolList, selectedFilter)
          .where((item) {
        if (searchQuery.isEmpty) return true;

        final name = (item["SchoolName"] ?? "")
            .toString()
            .toLowerCase();

        return name.contains(searchQuery.toLowerCase());
      })
          .toList();
      ref.read(schoolCountProvider.notifier).state = filtered.length.toString();

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
final selectedFilterProvider = StateProvider<SchoolFilter>(
  (ref) => SchoolFilter.all,
);
