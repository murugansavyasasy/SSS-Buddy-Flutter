import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sssbuddy/components/app_url.dart';

import '../../utils/app_logger.dart';

class Apiservice {
  static const Duration _timeout = Duration(seconds: 10);

  Future<http.Response> getversioncheck(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '${AppUrl.vimsUrl}$endpoint',
    ).replace(queryParameters: queryParams);



    print("API Call: $uri");

    try {
      final response = await http.get(uri).timeout(_timeout);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> postvalidatelogin(
    String endpoint, {
    Map<String, String>? body,
  }) async {
    final uri = Uri.parse('${AppUrl.vimsUrl}$endpoint');

    print("API Call: $uri");

    AppLogger.info("API Request URL: $uri");
    AppLogger.debug("Request Body: $body");

    try {
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      AppLogger.info("Status Code: ${response.statusCode}");
      AppLogger.debug("Response Body: ${response.body}");
      return response;
    } catch (e) {
      AppLogger.error("API Error: $e");
      rethrow;
    }
  }
}
