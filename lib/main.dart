import 'package:flutter/material.dart';
import 'package:sssbuddy/repository/clientrepository.dart';
import 'package:sssbuddy/repository/service/apiservice.dart';
import 'package:sssbuddy/utils/routes/routes.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/viewModel/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:sssbuddy/viewModel/login_view_model.dart';

void main() {
  final apiService = ApiService();
  final repository = ClientRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(repository)),
        ChangeNotifierProvider(create: (_) => LoginViewModel(repository)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute: Routes.generateRoutes,
        initialRoute: RoutesName.splashscreen,
      ),
    ),
  );
}
