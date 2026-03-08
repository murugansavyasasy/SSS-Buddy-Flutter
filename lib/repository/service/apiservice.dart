import 'package:http/http.dart' as http;
import 'package:sssbuddy/components/app_url.dart';

class Apiservice {

  static const Duration _timeout = Duration(seconds: 10);

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse(endpoint.startsWith('http') ? endpoint : '${AppUrl.baseUrl}$endpoint');
    print("API Call: $url");
    try {
      final response = await http.get(url).timeout(_timeout);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
