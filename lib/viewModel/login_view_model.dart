import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/auth/model/Validatelogin.dart';
import 'package:sssbuddy/core/storage/secure_storage.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import '../provider/app_providers.dart';

class LoginViewModel extends AsyncNotifier<Validatelogin?> {
  @override
  Future<Validatelogin?> build() async {
    return null;
  }

  Future<bool> login(
    String employeeId,
    String password,
    bool rememberMe,
  ) async {
    state = const AsyncLoading();

    try {
      final repo = ref.read(repositoryProvider);

      final response = await repo.apilogin(employeeId, password);

      if (response.result != 1) {
        throw Exception(response.resultMessage);
      }

      await SecureStorage.saveLoginData(
        employeeId,
        password,
        jsonEncode(response.toJson()),
        rememberMe,
      );
      await ref.read(userSessionProvider.notifier).refreshUser();

      state =    AsyncData(response);

      return true;

    } catch (e, stack) {
      state = AsyncError(e, stack);

      return false;
    }
  }
}

final loginProvider = AsyncNotifierProvider<LoginViewModel,Validatelogin?>(
  () => LoginViewModel(),
);
