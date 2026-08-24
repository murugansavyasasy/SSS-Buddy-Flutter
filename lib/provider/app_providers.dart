import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../auth/model/ReportingMembersModel.dart';
import '../auth/model/SchoolFilter.dart';
import '../core/network/DioClient.dart';
import '../repository/clientrepository.dart';
String globalVimsIdUser = "";
final dioProvider = Provider<DioClient>((ref) {
  return DioClient(ref);
});

final repositoryProvider = Provider<ClientRepository>((ref) {
  final dio = ref.read(dioProvider);
  return ClientRepository(dio);
});

final rememberMeProvider = StateProvider<bool>((ref) => false);

final selectedFilterProvider = StateProvider<SchoolFilter>(
      (ref) => SchoolFilter.all,
);

final selectedMemberProvider = StateProvider<Reportingmembersmodel?>((ref) => null);
