import 'package:flutter/cupertino.dart';
import 'package:sssbuddy/model/Versioncheck.dart';
import 'package:sssbuddy/repository/clientrepository.dart';
import 'package:flutter/foundation.dart';


class AuthViewModel extends ChangeNotifier {
  final ClientRepository _repository = ClientRepository();

  Versioncheck? _versioncheck;
  bool _fetchingData = false;
  String? _error;

  Versioncheck? get versioncheck => _versioncheck;
  bool get fetchingData => _fetchingData;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<Versioncheck?> getVersionCheckApiData() async {
    _fetchingData = true;
    _error = null;
    notifyListeners();

    try {
      _versioncheck = await _repository.getVersionCheckDetails();
      if (kDebugMode) {
        print("Update Available: ${_versioncheck?.IsVersionUpdateAvailable}");
      }
      return _versioncheck;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) print("API ERROR: $_error");
      notifyListeners();
      rethrow;
    } finally {
      _fetchingData = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}