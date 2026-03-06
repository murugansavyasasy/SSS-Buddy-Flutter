import 'package:flutter/cupertino.dart';
import 'package:sssbuddy/model/Versioncheck.dart';
import 'package:sssbuddy/repository/clientrepository.dart';

class AuthViewModel extends ChangeNotifier {

  final Clientrepository _clientrepository = Clientrepository();

  Versioncheck? _versioncheck;

  bool fetchingData = false;

  Versioncheck? get versioncheck => _versioncheck;

  Future<void> getVersionCheckApiData() async {

    fetchingData = true;
    notifyListeners();

    try {
      _versioncheck = await _clientrepository.getversioncheckdetails();
      print("Update Available: ${_versioncheck?.IsVersionUpdateAvailable}");
      print("Force Update: ${_versioncheck?.IsForceUpdateRequired}");
      print("School URL: ${_versioncheck?.SchoolURL}");

    } catch (e) {
      print("API ERROR : $e");
    }

    fetchingData = false;
    notifyListeners();
  }
}