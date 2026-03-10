import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sssbuddy/repository/app_url.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/auth_view_model.dart';

class Splash extends StatefulWidget {
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late AuthViewModel viewModel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel = context.read<AuthViewModel>();
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    await viewModel.getVersionCheckApiData();

    AppUrl.vimsUrl = viewModel.versioncheck?.VimsURL ?? "";
    AppUrl.schoolUrl = viewModel.versioncheck?.SchoolURL ?? "";

    final versionAvailable = viewModel.versioncheck?.IsVersionUpdateAvailable ?? 0;
    final forceUpdate = viewModel.versioncheck?.IsForceUpdateRequired ?? 0;

    if (versionAvailable == 0 && forceUpdate == 0) {
      _goToLogin();
    } else {
      _showUpdateDialog(versionAvailable, forceUpdate);
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, RoutesName.login);
  }

  void _showUpdateDialog(int versionAvailable, int forceUpdate) {
    bool isForceUpdate = (versionAvailable == 1 && forceUpdate == 1);

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: const Text(
            "A new version of the app is available. Please update to continue.",
          ),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _goToLogin();
                },
                child: const Text("Later"),
              ),

            /// Update button
            ElevatedButton(
              onPressed: () {
                /// open playstore link
                // launchUrl(Uri.parse(AppUrl.playStoreUrl));
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
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
                    onPressed: _checkVersion,
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
