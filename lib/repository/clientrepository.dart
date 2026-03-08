import 'dart:convert';

import 'package:sssbuddy/repository/service/apiservice.dart';

import '../components/app_url.dart';
import '../model/Versioncheck.dart';

class ClientRepository {
  final Apiservice _service = Apiservice();

  Future<Versioncheck> getVersionCheckDetails() async {
    try {
      final response = await _service.get(AppUrl.versioncheckendpoint);
      if (response.statusCode == 200 || response.body.isNotEmpty) {
        final data = json.decode(response.body);
        return Versioncheck.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load version details: $e');
    }
  }

}