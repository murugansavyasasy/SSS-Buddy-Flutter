import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repository/app_url.dart';
import '../utils/routes/routes_name.dart';
import '../viewModel/auth_view_model.dart';


class Splash extends ConsumerWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionState = ref.watch(authProvider);
    return versionState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(error.toString()),
        ),
      ),

      data: (version) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (version.IsVersionUpdateAvailable == 0 &&
              version.IsForceUpdateRequired == 0) {
            _goToLogin(context);
          } else {
            _showUpdateDialog(
              context,
              version.IsVersionUpdateAvailable,
              version.IsForceUpdateRequired,
            );
          }
        });

        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Image(
              image: AssetImage("assets/images/buddy_logo.png"),
            ),
          ),
        );
      },
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, RoutesName.login);
  }
  Future<void> openStore() async {
    const androidUrl = "https://play.google.com/store/apps/details?id=pkg.vs.schoolsdemo.voicensapschoolsdemo";
    const iosUrl = "https://apps.apple.com/app/idYOUR_APP_ID";

    final url = Platform.isAndroid ? androidUrl : iosUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch store";
    }
  }

  void _showUpdateDialog(
      BuildContext context,
      int versionAvailable,
      int forceUpdate,
      ) {
    bool isForceUpdate = (versionAvailable == 1 && forceUpdate == 1);

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available!!"),
          content: const Text(
            "A new version of the app is available. Please update to continue.",
          ),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _goToLogin(context);
                },
                child: const Text("Later"),
              ),
            ElevatedButton(
              onPressed: () {
                //openStore();
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}