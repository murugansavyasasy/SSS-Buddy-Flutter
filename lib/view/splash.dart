import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/auth_view_model.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _MySplash();
}

class _MySplash extends State<Splash> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      versionApi();
    });
  }

  Future<void> versionApi() async {

    final authViewModel =
    Provider.of<AuthViewModel>(context, listen: false);

    await authViewModel.getVersionCheckApiData();

    print(authViewModel.versioncheck?.resultMessage);

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacementNamed(
      context,
      RoutesName.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset("assets/images/buddy_logo.png"),
      ),
    );
  }
}