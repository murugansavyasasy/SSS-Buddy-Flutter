import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/core/storage/secure_storage.dart';
import 'package:sssbuddy/provider/user_session_provider.dart';
import '../auth/model/Validatelogin.dart';
import '../provider/app_providers.dart';

String globalUserId = "";

class LoginViewModel extends AsyncNotifier<LoginData?> {
  @override
  Future<LoginData?> build() async {
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

      // API call
      final LoginResponse response =
      await repo.apilogin(employeeId, password);

      // validation
      if (response.status != "success") {
        throw Exception(
          (response.message.isNotEmpty)
              ? response.message
              : "Login failed",
        );
      }

      final user = response.data;

      if (user == null) {
        throw Exception("Invalid response from server");
      }

      // Save data locally
      await SecureStorage.saveLoginData(
        employeeId,
        password,
        jsonEncode(response.toJson()),
        rememberMe,
      );

      await ref.read(userSessionProvider.notifier).refreshUser();

      // Global variable store
      globalUserId = user.userId.toString();

      print("✅ User ID: ${user.userId}");
      print("✅ Name: ${user.name}");
      print("✅ Token: ${user.token}");

      state = AsyncData(user);

      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final loginProvider =
AsyncNotifierProvider<LoginViewModel, LoginData?>(
      () => LoginViewModel(),
);