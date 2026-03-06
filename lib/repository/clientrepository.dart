import 'dart:convert';

import 'package:sssbuddy/repository/service/apiservice.dart';

import '../model/Versioncheck.dart';

class Clientrepository {

  final Apiservice _service = Apiservice();

  Future<Versioncheck> getversioncheckdetails() async {

    final response = await _service.getVersionCheckApiData();

    if (response.statusCode == 200) {

      final data = json.decode(response.body);

      return Versioncheck.fromJson(data);

    } else {
      throw Exception('Failed to load version details');
    }
  }
}