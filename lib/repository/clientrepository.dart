import 'dart:convert';

import 'package:sssbuddy/model/Validatelogin.dart';
import 'package:sssbuddy/repository/service/apiservice.dart';
import 'package:sssbuddy/utils/network_utils.dart';

import '../components/app_url.dart';
import '../model/Versioncheck.dart';
import '../utils/app_logger.dart';

class ClientRepository {
  final Apiservice _service = Apiservice();

  Future<Versioncheck> getVersionCheckDetails() async {
    try {
      final response = await _service.getversioncheck(
        AppUrl.versioncheckendpoint,
        queryParams: {"VersionID": "55"},
      );

      final data = json.decode(response.body);
      return Versioncheck.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load version details: $e');
    }
  }

  Future<Validatelogin> apilogin(String employeeId, String password) async {
    try {
      AppLogger.info("Login API called");

      final response = await _service.postvalidatelogin(
        AppUrl.validateloginendpoint,
        body: {"EmployeeId": employeeId, "Password": password},
      );

      AppLogger.debug("Login API Raw Response: ${response.body}");

      final data = jsonDecode(response.body);

      return Validatelogin.fromJson(data);
    } catch (e) {
      AppLogger.error("Repository Login Error: $e");
      throw Exception("Login failed");
    }
  }
}
