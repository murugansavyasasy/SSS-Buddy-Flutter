import 'package:sssbuddy/repository/app_endpoint.dart';
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
}
