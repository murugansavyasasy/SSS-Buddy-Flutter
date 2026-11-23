import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String employeeIdKey = "employeeId";
  static const String passwordKey = "password";
  static const String loginResponseKey = "loginResponse";
  static const String tripStartedKey = "tripStarted";
  static const String tripStartDateKey = "tripStartDate";

  /// SharedPreferences flag. SharedPreferences is wiped on uninstall, but the
  /// iOS Keychain (used by flutter_secure_storage) is not.
  static const String _installMarkerKey = "hasLaunchedBefore";

  /// Call once at startup, before reading any stored login. If the install
  /// marker is missing this is a fresh install (or reinstall), so any login
  /// left in the Keychain by a previous install is cleared.
  static Future<void> clearIfFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_installMarkerKey) ?? false) return;
    await _storage.deleteAll();
    await prefs.setBool(_installMarkerKey, true);
  }

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

  // ---------------- NEW METHODS ----------------

  static Future<void> saveTripData(bool isStarted, String date) async {
    await _storage.write(key: tripStartedKey, value: isStarted.toString());
    await _storage.write(key: tripStartDateKey, value: date);
  }

  static Future<bool> getTripStarted() async {
    final value = await _storage.read(key: tripStartedKey);
    return value == "true";
  }

  static Future<String?> getTripStartDate() async {
    return await _storage.read(key: tripStartDateKey);
  }

  static Future<void> clearTripData() async {
    await _storage.delete(key: tripStartedKey);
    await _storage.delete(key: tripStartDateKey);
  }
  static Future<void> clearLoginData() async {
    await _storage.deleteAll();
  }
}
