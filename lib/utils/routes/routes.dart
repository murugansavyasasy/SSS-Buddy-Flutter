import 'package:flutter/material.dart';
import 'package:sssbuddy/View/splash.dart';
import 'package:sssbuddy/View/login.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/view/create_demo.dart';
import 'package:sssbuddy/view/dashboard.dart';
import 'package:sssbuddy/view/record_voice.dart';
import 'package:sssbuddy/view/school_listview.dart';

import '../../view/demo_list.dart';

class Routes {
  static Route<dynamic> generateRoutes(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.splashscreen:
        return MaterialPageRoute(builder: (context) => Splash());

      case RoutesName.dashboard:
        return MaterialPageRoute(builder: (context) => Dashboard());

      case RoutesName.login:
        return MaterialPageRoute(builder: (context) => LoginScreen());

      case RoutesName.createdemo:
        return MaterialPageRoute(builder: (context) => CreateDemo());

      case RoutesName.recordvoice:
        return MaterialPageRoute(builder: (context) => RecordVoice());

      case RoutesName.demolistview:
        return MaterialPageRoute(builder: (context) => DemoListView());

      case RoutesName.schoollistview:
        return MaterialPageRoute(builder: (context) => SchoolListview());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text("No routes found"))),
        );
    }
  }
}
