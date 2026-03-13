import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';

class UserSession {
  final String employeeName;
  final String employeeId;
  final String employeerole;

  UserSession({
    required this.employeeName,
    required this.employeeId,
    required this.employeerole,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      employeeName: json["VimsUserName"] ?? "",
      employeeId: json["VimsEmployeeId"] ?? "",
      employeerole: json["SchooluserType"] ?? "",
    );
  }
}

class UserSessionNotifier extends AsyncNotifier<UserSession?> {
  @override
  Future<UserSession?> build() async {
    return loadUser();
  }

  Future<UserSession?> loadUser() async {
    final response = await SecureStorage.getLoginResponse();

    if (response == null) return null;

    final decoded = jsonDecode(response);

    return UserSession.fromJson(decoded);
  }

  Future<void> refreshUser() async {
    state = const AsyncLoading();
    state = AsyncData(await loadUser());
  }

  Future<void> logout() async {
    await SecureStorage.clearLoginData();
    state = const AsyncData(null);
  }
}

final userSessionProvider =
    AsyncNotifierProvider<UserSessionNotifier, UserSession?>(
      () => UserSessionNotifier(),
    );
