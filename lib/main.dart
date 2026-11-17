import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/core/notifications/local_notifications.dart';
import 'package:sssbuddy/utils/network_utils.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/values/app_theme.dart';
import 'package:sssbuddy/utils/device_text_scale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await LocalNotifications.instance.init();

  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget  {
  const AppRoot({super.key});
  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_AppRootState>()?.restartApp();
  }
  @override
  State<StatefulWidget> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  Key _key = UniqueKey();
  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _key,
      child: const MyApp(),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generateRoutes,
      initialRoute: RoutesName.splashscreen,
      // Tapping anywhere outside a text field closes the keyboard.
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: DeviceTextScale(
          child: ConnectivityWrapper(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}