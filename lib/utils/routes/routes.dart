import 'package:flutter/material.dart';
import 'package:sssbuddy/View/splash.dart';
import 'package:sssbuddy/View/login.dart';
import 'package:sssbuddy/auth/model/Demolist.dart';
import 'package:sssbuddy/utils/routes/routes_name.dart';
import 'package:sssbuddy/view/advance_tour_expense.dart';
import 'package:sssbuddy/view/change_password.dart';
import 'package:sssbuddy/view/Circular/circular_listview.dart';
import 'package:sssbuddy/view/create_demo.dart';
import 'package:sssbuddy/view/dashboard.dart';
import 'package:sssbuddy/view/local_conveyence.dart';
import 'package:sssbuddy/view/management_videos.dart';
import 'package:sssbuddy/view/record_collection.dart';
import 'package:sssbuddy/view/RecordVoice/record_voice.dart';
import 'package:sssbuddy/view/school_documents.dart';
import 'package:sssbuddy/view/school_listview.dart';
import 'package:sssbuddy/view/UsageCount/usage_count.dart';
import 'package:sssbuddy/view/status_report.dart';
import 'package:sssbuddy/view/tour_settlement.dart';

import '../../view/customer_list_view.dart';
import '../../view/demo_list.dart';
import '../../view/important_info.dart';
import '../../view/school_detail/schooldetail_view.dart';

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
        final item = settings.arguments as Demolist;
        return MaterialPageRoute(builder: (context) => RecordVoiceScreen(item: item));

      case RoutesName.demolistview:
        return MaterialPageRoute(builder: (context) => DemoListView());

      case RoutesName.schoollistview:
        return MaterialPageRoute(builder: (context) => SchoolListview());

      case RoutesName.changepassword:
        return MaterialPageRoute(builder: (context) => ChangePassword());

      case RoutesName.circularlist:
        return MaterialPageRoute(builder: (context) => CircularListview());

      case RoutesName.managementvideos:
        return MaterialPageRoute(
          builder: (context) => const ManagementVideos(userId: '0'),
        );

      case RoutesName.customerListView:
        return MaterialPageRoute(builder: (context) => CustomerListView());

      case RoutesName.schooldocuments:
        return MaterialPageRoute(builder: (context) => SchoolDocuments());

      case RoutesName.importantinfo:
        return MaterialPageRoute(builder: (context) => ImportantInfoScreen());

      case RoutesName.advancetourexpense:
        return MaterialPageRoute(builder: (context) => AdvanceTourExpense());

      case RoutesName.localconveyence:
        return MaterialPageRoute(builder: (context) => LocalConveyence());

      case RoutesName.recordcollection:
        return MaterialPageRoute(builder: (context) => RecordCollection());

      case RoutesName.statusreport:
        return MaterialPageRoute(builder: (context) => StatusReport());

      case RoutesName.toursettlement:
        return MaterialPageRoute(builder: (context) => TourSettlement());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: Center(child: Text("No routes found"))),
        );
    }
  }
}
