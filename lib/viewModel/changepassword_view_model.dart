import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/ChangePassword.dart';
import '../provider/app_providers.dart';


class ChangepasswordViewModel extends AsyncNotifier<Changepassword?> {
  @override
  Future<Changepassword?> build() async {
    return null;
  }

  Future<Changepassword?> changepassword(
      String idUser,
      String oldPassword,
      String newPassword,
      ) async {

    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);

      final response = await repo.changepassword(
        idUser,
        oldPassword,
        newPassword,
      );

      state = AsyncData(response);

      return response;

    } catch (e, stack) {
      state = AsyncError(e, stack);

      return null;
    }
  }
}

final changepasswordProvider =
AsyncNotifierProvider<ChangepasswordViewModel, Changepassword?>(
      () => ChangepasswordViewModel(),
);