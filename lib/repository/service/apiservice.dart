import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sssbuddy/repository/app_url.dart';
import '../../utils/app_logger.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);

  Future<http.Response> request({
    required String endpoint,
    String method = "GET",
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
  }) async {
    Uri uri = Uri.parse('${AppUrl.vimsUrl}$endpoint');

    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    AppLogger.info("API URL: $uri");

    try {
      http.Response response;

      if (method == "POST") {
        response = await http
            .post(
              uri,
              headers: {"Content-Type": "application/json"},
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(_timeout);
      } else {
        response = await http.get(uri).timeout(_timeout);
      }

      return response;
    } catch (e) {
      AppLogger.error("API Error: $e");
      rethrow;
    }
  }
}
