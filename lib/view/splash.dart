import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/auth_view_model.dart';


class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    await viewModel.getVersionCheckApiData();
    if (viewModel.versioncheck?.IsForceUpdateRequired == 1) {
      Navigator.pushReplacementNamed(context, RoutesName.login);
    } else if (viewModel.versioncheck?.IsVersionUpdateAvailable == 1) {
      Navigator.pushReplacementNamed(context, RoutesName.login);
    } else {
      Navigator.pushReplacementNamed(context, RoutesName.login);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.fetchingData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (viewModel.hasError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error loading version'),
                  ElevatedButton(
                    onPressed: () => _checkVersion(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: Image.asset("assets/images/buddy_logo.png")),
        );
      },
    );
  }
}