import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/secure_storage.dart';

class UserSession {
  final String employeeName;
  final String employeeId;
  final String employeerole;
  final String userId;
  final String token;

  UserSession({
    required this.employeeName,
    required this.employeeId,
    required this.employeerole,
    required this.userId,
    required this.token,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final data = json["data"] ?? {};

    return UserSession(
      employeeName: data["name"] ?? "",
      employeeId: data["employeeId"] ?? "",
      employeerole: data["roleName"] ?? "",
      userId: data["userId"].toString(),
      token: data["token"] ?? "",
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
