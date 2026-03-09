import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sssbuddy/model/Validatelogin.dart';
import 'package:sssbuddy/repository/clientrepository.dart';

import '../utils/secure_storage.dart';
import '../utils/routes/routes_name.dart';

class LoginViewModel extends ChangeNotifier {
  final ClientRepository repository;

  LoginViewModel(this.repository);

  bool _loginloading = false;

  get loading => _loginloading;

  void setLoginLoading(bool value) {
    _loginloading = value;
    notifyListeners();
  }

  Future<void> apilogin(
    String employeeId,
    String password,
    BuildContext context,
  ) async {
    setLoginLoading(true);
    notifyListeners();

    try {
      final response = await repository.apilogin(employeeId, password);

      if (response.result == 1) {
        await SecureStorage.saveLoginData(
          employeeId,
          password,
          response.toJson().toString(),
        );

        Navigator.pushReplacementNamed(context, RoutesName.dashboard);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.resultMessage)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed")));
    }

    setLoginLoading(false);
    notifyListeners();
  }
}
