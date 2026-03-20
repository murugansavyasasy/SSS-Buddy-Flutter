import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';

void main() {
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
      onGenerateRoute: Routes.generateRoutes,
      initialRoute: RoutesName.splashscreen,
    );
  }
}