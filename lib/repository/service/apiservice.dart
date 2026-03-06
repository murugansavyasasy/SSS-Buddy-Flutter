import 'package:http/http.dart' as http;
import 'package:sssbuddy/components/app_url.dart';

class Apiservice {

  final String apiUrl = AppUrl.versioncheckendpoint;

  Future<http.Response> getVersionCheckApiData() async {
    final response = await http.get(Uri.parse(apiUrl));
    return response;
  }
}
