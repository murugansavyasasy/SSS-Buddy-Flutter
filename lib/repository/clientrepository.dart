import 'dart:convert';

import 'package:sssbuddy/model/Validatelogin.dart';
import 'package:sssbuddy/repository/app_endpoint.dart';
import 'package:sssbuddy/repository/service/apiservice.dart';
import 'app_url.dart';
import '../model/Versioncheck.dart';

class ClientRepository {
  final ApiService service;
  ClientRepository(this.service);

  Future<Versioncheck> getVersionCheckDetails() async {
    final response = await service.request(
      endpoint: AppEndpoint.versioncheckendpoint,
      queryParams: {"VersionID": "55"},
    );

    final data = jsonDecode(response.body);
    return Versioncheck.fromJson(data);
  }

  Future<Validatelogin> apilogin(String employeeId, String password) async {
    final response = await service.request(
      endpoint: AppEndpoint.validateloginendpoint,
      method: "POST",
      body: {"EmployeeId": employeeId, "Password": password},
    );

    final data = jsonDecode(response.body);

    return Validatelogin.fromJson(data);
  }
}
