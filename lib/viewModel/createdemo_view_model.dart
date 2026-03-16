import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/CreatedemoResponse.dart';

import '../provider/app_providers.dart';

class CreatedemoViewModel extends AsyncNotifier<Createdemoresponse?> {
  @override
  Future<Createdemoresponse?> build() async {
    return null;
  }

  Future<bool> createdemo(
    String LoginID,
    String SchoolName,
    String MobileNo,
    String Email,
    String ParentNos,
    String RequestType,
  ) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(repositoryProvider);

      final response = await repo.createdemo(
        LoginID,
        SchoolName,
        MobileNo,
        Email,
        ParentNos,
        "1",
      );
      state = AsyncData(response);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final createdemoProvider =
    AsyncNotifierProvider<CreatedemoViewModel, Createdemoresponse?>(
      () => CreatedemoViewModel(),
    );
