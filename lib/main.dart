import 'package:flutter/material.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/viewModel/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: RoutesName.splashscreen,
        onGenerateRoute: Routes.generateRoutes,
      ),
    ),
  );
}
