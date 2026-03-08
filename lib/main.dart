import 'package:flutter/material.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/viewModel/auth_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthViewModel())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: RoutesName.splashscreen,
        onGenerateRoute: Routes.generateRoutes,
      ),
    ),
  );
}
