import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../auth/model/SchoolFilter.dart';
import '../core/network/DioClient.dart';
import '../repository/clientrepository.dart';

final dioProvider = Provider<Dioclient>((ref) {
  return Dioclient();
});

final repositoryProvider = Provider<ClientRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ClientRepository(dio);
});

final rememberMeProvider = StateProvider<bool>((ref) => false);

final selectedFilterProvider = StateProvider<SchoolFilter>(
      (ref) => SchoolFilter.all,
);