import 'package:http/http.dart' as http;
import 'package:sssbuddy/components/app_url.dart';


class Apiservice {

  static const Duration _timeout = Duration(seconds: 10);

  Future<http.Response> getversioncheck(String endpoint,
      {Map<String, String>? queryParams}) async {

    final uri = Uri.parse('${AppUrl.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    print("API Call: $uri");

    try {
      final response = await http.get(uri).timeout(_timeout);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
