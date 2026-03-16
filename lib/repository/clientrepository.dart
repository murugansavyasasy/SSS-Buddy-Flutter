import 'dart:convert';

import 'package:sssbuddy/auth/model/Schoollist.dart';
import 'package:sssbuddy/repository/app_endpoint.dart';
import '../auth/model/Demolist.dart';
import '../auth/model/Validatelogin.dart';
import '../auth/model/Versioncheck.dart';
import '../core/network/DioClient.dart';

class ClientRepository {
  final Dioclient client;
  ClientRepository(this.client);
  Future<Versioncheck> getVersionCheckDetails() async {
    final response = await client.get(
      AppEndpoint.versioncheckendpoint,
      query: {"VersionID": "55"},
    );
    return Versioncheck.fromJson(response.data);
  }

  Future<Validatelogin> apilogin(String employeeId, String password) async {
    final response = await client.post(
      AppEndpoint.validateloginendpoint,
      body: {"EmployeeId": employeeId, "Password": password},
    );
    return Validatelogin.fromJson(response.data);
  }

  Future<List<Demolist>> getdemolist(String schoolLoginId) async {
    final response = await client.get(
      AppEndpoint.demolistendpoint,
      query: {"LoginID": schoolLoginId},
      useSchoolApi: true,
    );

    final List data = response.data;

    return data.map((e) => Demolist.fromJson(e)).toList();
  }


  Future<String> postschoollist(String schoolLoginId) async {
    final response = await client.post(
      AppEndpoint.schoollistendpoint,
      body: {"LoginID": schoolLoginId},
      useSchoolApi: true,
    );

    return jsonEncode(response.data);
  }
}