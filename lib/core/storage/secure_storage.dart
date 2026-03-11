import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String employeeIdKey = "employeeId";
  static const String passwordKey = "password";
  static const String loginResponseKey = "loginResponse";

  static Future<void> saveLoginData(
    String employeeId,
    String password,
    String responseJson,
  ) async {
    await _storage.write(key: employeeIdKey, value: employeeId);
    await _storage.write(key: passwordKey, value: password);
    await _storage.write(key: loginResponseKey, value: responseJson);
  }

  static Future<String?> getEmployeeId() async {
    return await _storage.read(key: employeeIdKey);
  }

  static Future<String?> getPassword() async {
    return await _storage.read(key: passwordKey);
  }

  static Future<String?> getLoginResponse() async {
    return await _storage.read(key: loginResponseKey);
  }

  static Future<void> clearLoginData() async {
    await _storage.deleteAll();
  }
}
